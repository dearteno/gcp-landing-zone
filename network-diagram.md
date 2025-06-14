# GCP Landing Zone Network Architecture (OpenTofu + Terragrunt)

```mermaid
graph TB
    %% External Components
    Internet[🌐 Internet]
    Users[👥 Users]
    
    %% External IPs
    ExtLB_IP[📍 External LB IP<br/>Reserved Static IP]
    NAT_IP[📍 NAT Gateway IP<br/>Reserved Static IP]
    
    %% Load Balancers
    ExtLB[🔄 External Load Balancer<br/>Global HTTPS LB<br/>SSL Termination]
    IntLB[🔄 Internal Load Balancer<br/>Regional TCP LB]
    
    %% Gateway API
    ExtGW[🚪 External Gateway API<br/>api.example.com<br/>/api/v1/*]
    IntGW[🚪 Internal Gateway API<br/>Internal Services]
    
    %% VPC Network
    subgraph VPC["🏠 VPC Network (per environment)"]
        direction TB
        
        %% Subnet
        subgraph Subnet["📡 Primary Subnet"]
            SubnetCIDR[10.0.x.0/24<br/>Primary Range]
            PodsCIDR[10.x.0.0/16<br/>Pods Secondary Range]
            ServicesCIDR[10.x.0.0/16<br/>Services Secondary Range]
        end
        
        %% Cloud Router and NAT
        CloudRouter[🔀 Cloud Router<br/>Regional]
        NATGateway[🚪 NAT Gateway<br/>Outbound Internet Access]
        
        %% GKE Cluster
        subgraph GKE["☸️ GKE Private Cluster"]
            direction TB
            
            %% Control Plane
            ControlPlane[🎛️ Control Plane<br/>172.16.0.0/28<br/>Private Endpoint]
            
            %% Node Pool
            subgraph NodePool["🖥️ Node Pool"]
                Node1[📦 Node 1<br/>e2-standard-x<br/>Private IP]
                Node2[📦 Node 2<br/>e2-standard-x<br/>Private IP]
                Node3[📦 Node 3<br/>e2-standard-x<br/>Private IP]
            end
            
            %% Workload Identity
            WorkloadID[🔐 Workload Identity<br/>Pod ↔ GCP Services]
            
            %% Application Pods
            subgraph Pods["🎯 Application Pods"]
                Pod1[📱 App Pod 1]
                Pod2[📱 App Pod 2]
                Pod3[📱 App Pod 3]
            end
        end
        
        %% Instance Groups for Load Balancers
        ExtIG[📋 External Instance Group<br/>Backend for Ext LB]
        IntIG[📋 Internal Instance Group<br/>Backend for Int LB]
    end
    
    %% Firewall Rules
    subgraph Firewall["🔥 Firewall Rules"]
        FW1[🛡️ Allow Internal<br/>TCP/UDP: All Ports<br/>ICMP: All]
        FW2[🛡️ Allow SSH<br/>TCP: 22<br/>Source: 0.0.0.0/0]
        FW3[🛡️ Allow HTTP<br/>TCP: 80<br/>Source: 0.0.0.0/0]
        FW4[🛡️ Allow HTTPS<br/>TCP: 443<br/>Source: 0.0.0.0/0]
    end
    
    %% Health Checks
    ExtHC[💊 External Health Check<br/>HTTP /health:80]
    IntHC[💊 Internal Health Check<br/>TCP :80]
    
    %% Backend Services
    ExtBS[⚙️ External Backend Service<br/>HTTP Protocol]
    IntBS[⚙️ Internal Backend Service<br/>TCP Protocol]
    
    %% Environment Examples
    subgraph Environments["🌍 Multi-Environment"]
        Dev[🧪 Development<br/>10.0.1.0/24<br/>1-3 nodes<br/>e2-standard-2]
        Staging[🎭 Staging<br/>10.0.2.0/24<br/>1-5 nodes<br/>e2-standard-4]
        Prod[🏭 Production<br/>10.0.3.0/24<br/>2-10 nodes<br/>e2-standard-8]
    end
    
    %% Connections - External Traffic Flow
    Users --> Internet
    Internet --> ExtLB_IP
    ExtLB_IP --> ExtLB
    ExtLB --> ExtGW
    ExtGW --> ExtBS
    ExtBS --> ExtHC
    ExtBS --> ExtIG
    ExtIG --> NodePool
    
    %% Internal Traffic Flow
    IntLB --> IntGW
    IntGW --> IntBS
    IntBS --> IntHC
    IntBS --> IntIG
    IntIG --> NodePool
    
    %% Outbound Internet Access
    NodePool --> CloudRouter
    CloudRouter --> NATGateway
    NATGateway --> NAT_IP
    NAT_IP --> Internet
    
    %% GKE Internal Connections
    ControlPlane -.-> NodePool
    Node1 --> Pod1
    Node2 --> Pod2
    Node3 --> Pod3
    Pods --> WorkloadID
    
    %% Subnet Relationships
    NodePool -.-> SubnetCIDR
    Pods -.-> PodsCIDR
    GKE -.-> ServicesCIDR
    
    %% Security
    Firewall -.-> VPC
    
    %% Styling
    classDef internet fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef loadbalancer fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef vpc fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef gke fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef firewall fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef environment fill:#f1f8e9,stroke:#33691e,stroke-width:2px
    classDef gateway fill:#e0f2f1,stroke:#00695c,stroke-width:2px
    
    class Internet,Users internet
    class ExtLB,IntLB,ExtBS,IntBS loadbalancer
    class VPC,Subnet,CloudRouter,NATGateway vpc
    class GKE,ControlPlane,NodePool,Node1,Node2,Node3,Pods,Pod1,Pod2,Pod3,WorkloadID gke
    class Firewall,FW1,FW2,FW3,FW4 firewall
    class Environments,Dev,Staging,Prod environment
    class ExtGW,IntGW gateway
```

## Network Diagram Legend

### 🏗️ **Components Overview**

| Symbol | Component | Description |
|--------|-----------|-------------|
| 🌐 | Internet | External internet connectivity |
| 🔄 | Load Balancer | External/Internal load balancing |
| 🚪 | Gateway API | API gateway for routing |
| 🏠 | VPC Network | Virtual Private Cloud |
| 📡 | Subnet | Network subnet with CIDR ranges |
| 🔀 | Cloud Router | Regional router for NAT |
| ☸️ | GKE Cluster | Kubernetes cluster |
| 🖥️ | Node Pool | Kubernetes worker nodes |
| 📦 | Node | Individual compute node |
| 🎯 | Pods | Kubernetes application pods |
| 🔐 | Workload Identity | Secure pod-to-GCP authentication |
| 🔥 | Firewall | Network security rules |
| 💊 | Health Check | Load balancer health monitoring |

### 🌍 **Environment Configurations**

| Environment | Subnet CIDR | Pods CIDR | Services CIDR | Node Size | Node Count |
|-------------|-------------|-----------|---------------|-----------|------------|
| **Dev** | 10.0.1.0/24 | 10.1.0.0/16 | 10.2.0.0/16 | e2-standard-2 | 1-3 |
| **Staging** | 10.0.2.0/24 | 10.3.0.0/16 | 10.4.0.0/16 | e2-standard-4 | 1-5 |
| **Production** | 10.0.3.0/24 | 10.5.0.0/16 | 10.6.0.0/16 | e2-standard-8 | 2-10 |

### 🔄 **Traffic Flow**

1. **Inbound Traffic**: Users → Internet → External LB → Gateway API → Backend Service → GKE Nodes
2. **Internal Traffic**: Internal LB → Internal Gateway → Backend Service → GKE Nodes
3. **Outbound Traffic**: GKE Nodes → Cloud Router → NAT Gateway → Internet
4. **Pod-to-Pod**: Direct communication within cluster using pod CIDR
5. **Service Discovery**: Using services CIDR for internal service communication

### 🔒 **Security Features**

- **Private GKE Cluster**: Nodes have no public IPs
- **Workload Identity**: Secure pod authentication to GCP services
- **Network Policies**: Pod-to-pod communication control
- **Firewall Rules**: Controlled ingress/egress traffic
- **Private Google Access**: Access to GCP services without public IPs
- **NAT Gateway**: Controlled outbound internet access

This architecture provides a secure, scalable, and highly available infrastructure for your GCP landing zone!
