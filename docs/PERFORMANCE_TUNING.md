# Performance Tuning Guide - GCP Landing Zone

This guide provides comprehensive performance optimization strategies for the GCP Landing Zone infrastructure.

## 🎯 Performance Overview

### Key Performance Areas
1. **[GKE Cluster Performance](#gke-cluster-performance)** - Node optimization, autoscaling, resource allocation
2. **[Network Performance](#network-performance)** - Bandwidth, latency, routing optimization
3. **[Load Balancer Performance](#load-balancer-performance)** - Traffic distribution, health checks, SSL optimization
4. **[Storage Performance](#storage-performance)** - Disk I/O, persistent volumes, backup optimization
5. **[Security Performance](#security-performance)** - Encryption overhead, policy evaluation, monitoring
6. **[Cost Optimization](#cost-optimization)** - Resource rightsizing, scheduling, waste elimination

---

## ☸️ GKE Cluster Performance

### Node Pool Optimization

#### 1. Machine Type Selection
```hcl
# Performance-optimized configurations by environment

# Development Environment
machine_type = "e2-standard-2"    # 2 vCPU, 8 GB RAM
disk_size_gb = 50                 # Smaller disk for cost savings
disk_type    = "pd-standard"      # Standard persistent disk

# Staging Environment  
machine_type = "e2-standard-4"    # 4 vCPU, 16 GB RAM
disk_size_gb = 100                # Balanced disk size
disk_type    = "pd-ssd"          # SSD for better I/O

# Production Environment
machine_type = "e2-standard-8"    # 8 vCPU, 32 GB RAM
disk_size_gb = 200                # Larger disk for production workloads
disk_type    = "pd-ssd"          # SSD for optimal performance

# High-Performance Workloads
machine_type = "c2-standard-16"   # 16 vCPU, 64 GB RAM (compute-optimized)
disk_size_gb = 500                # Large SSD disk
disk_type    = "pd-ssd"          # High-performance SSD
```

#### 2. Autoscaling Configuration
```hcl
# Optimized autoscaling settings
resource "google_container_node_pool" "optimized_nodes" {
  # Cluster autoscaling
  autoscaling {
    min_node_count = var.environment == "prod" ? 3 : 1
    max_node_count = var.environment == "prod" ? 20 : 5
    
    # Location policy for better distribution
    location_policy = "BALANCED"
  }
  
  # Node management for performance
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  
  # Node configuration
  node_config {
    # Optimized machine configuration
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    
    # Performance-oriented node settings
    metadata = {
      disable-legacy-endpoints = "true"
      enable-ip-alias         = "true"
    }
    
    # Resource allocation
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    # Preemptible nodes for cost optimization (non-prod)
    preemptible = var.environment != "prod" ? true : false
    
    # Taints for workload isolation
    dynamic "taint" {
      for_each = var.environment == "prod" ? [1] : []
      content {
        key    = "production-only"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    }
  }
}
```

#### 3. Resource Requests and Limits
```yaml
# Kubernetes resource optimization examples
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
    
    # Performance optimizations
    env:
    - name: GOMAXPROCS
      valueFrom:
        resourceFieldRef:
          resource: limits.cpu
```

### Cluster-Level Optimizations

#### 1. Enhanced Cluster Configuration
```hcl
resource "google_container_cluster" "optimized_cluster" {
  # Performance-oriented cluster settings
  cluster_autoscaling {
    enabled = true
    
    # Resource limits for autoscaling
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 100
    }
    
    resource_limits {
      resource_type = "memory"
      minimum       = 1
      maximum       = 1000
    }
    
    # Autoscaling profile
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
  }
  
  # Vertical Pod Autoscaling
  vertical_pod_autoscaling {
    enabled = true
  }
  
  # Network performance
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
    
    # Optimize IP allocation
    cluster_ipv4_cidr_block  = "/14"  # Larger range for more pods
    services_ipv4_cidr_block = "/20"  # Adequate range for services
  }
  
  # Monitoring and logging optimization
  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
      "API_SERVER"
    ]
  }
  
  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS"
    ]
    
    # Managed Prometheus for better performance
    managed_prometheus {
      enabled = true
    }
  }
}
```

#### 2. Node Pool Strategies
```hcl
# Multiple node pools for workload optimization
locals {
  node_pools = {
    # General purpose pool
    general = {
      machine_type   = "e2-standard-4"
      min_nodes     = 1
      max_nodes     = 10
      disk_size_gb  = 100
      disk_type     = "pd-ssd"
      preemptible   = false
    }
    
    # Compute-intensive pool
    compute = {
      machine_type   = "c2-standard-8"
      min_nodes     = 0
      max_nodes     = 5
      disk_size_gb  = 200
      disk_type     = "pd-ssd"
      preemptible   = false
      
      # Taints for compute workloads
      taints = [{
        key    = "compute-intensive"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
    
    # Memory-intensive pool
    memory = {
      machine_type   = "n2-highmem-4"
      min_nodes     = 0
      max_nodes     = 3
      disk_size_gb  = 150
      disk_type     = "pd-ssd"
      preemptible   = false
      
      # Taints for memory workloads
      taints = [{
        key    = "memory-intensive"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
    
    # Spot instances for batch workloads
    spot = {
      machine_type   = "e2-standard-4"
      min_nodes     = 0
      max_nodes     = 20
      disk_size_gb  = 100
      disk_type     = "pd-standard"
      preemptible   = true
      
      # Taints for spot workloads
      taints = [{
        key    = "spot-instance"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }
}

# Create optimized node pools
resource "google_container_node_pool" "optimized_pools" {
  for_each = local.node_pools
  
  name     = each.key
  cluster  = google_container_cluster.primary.name
  location = var.region
  
  autoscaling {
    min_node_count = each.value.min_nodes
    max_node_count = each.value.max_nodes
  }
  
  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type
    preemptible  = each.value.preemptible
    
    # Performance optimizations
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    # Apply taints if defined
    dynamic "taint" {
      for_each = lookup(each.value, "taints", [])
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }
}
```

---

## 🌐 Network Performance

### VPC Optimization

#### 1. Subnet Design for Performance
```hcl
# Optimized subnet configuration
resource "google_compute_subnetwork" "optimized_subnet" {
  name          = "${var.environment}-optimized-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  
  # Enable private Google access for better performance
  private_ip_google_access = true
  
  # Optimized secondary ranges
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr  # Large range: /14 for high pod density
  }
  
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr  # Adequate range: /20
  }
  
  # Flow logs for performance monitoring
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"  # More frequent for performance monitoring
    flow_sampling        = 0.1               # 10% sampling for balance
    metadata            = "INCLUDE_ALL_METADATA"
    metadata_fields     = [
      "src_ip", "dest_ip", "src_port", "dest_port",
      "protocol", "bytes_sent", "packets_sent"
    ]
  }
}
```

#### 2. Firewall Rules Optimization
```hcl
# Performance-optimized firewall rules
resource "google_compute_firewall" "optimized_rules" {
  # High-priority rules for critical traffic
  name     = "${var.environment}-high-priority-allow"
  network  = google_compute_network.vpc_network.name
  priority = 100
  
  allow {
    protocol = "tcp"
    ports    = ["443", "80"]  # HTTPS/HTTP traffic
  }
  
  source_ranges = var.allowed_ip_ranges
  target_tags   = ["web-server"]
  
  # Logging disabled for high-traffic rules to improve performance
  log_config {
    metadata = "EXCLUDE_ALL_METADATA"
  }
}

# Separate rule for internal traffic (higher performance)
resource "google_compute_firewall" "internal_optimized" {
  name     = "${var.environment}-internal-optimized"
  network  = google_compute_network.vpc_network.name
  priority = 200
  
  allow {
    protocol = "tcp"
  }
  
  allow {
    protocol = "udp"
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = [var.subnet_cidr, var.pods_cidr, var.services_cidr]
  
  # No logging for internal traffic to improve performance
  log_config {
    metadata = "EXCLUDE_ALL_METADATA"
  }
}
```

#### 3. NAT Gateway Optimization
```hcl
# High-performance NAT configuration
resource "google_compute_router_nat" "optimized_nat" {
  name   = "${var.environment}-optimized-nat"
  router = google_compute_router.router.name
  region = var.region
  
  # Performance settings
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips               = [google_compute_address.nat_ip.self_link]
  
  # Optimize for high throughput
  min_ports_per_vm                    = 2048
  max_ports_per_vm                    = 65536
  enable_endpoint_independent_mapping = true
  
  # Logging configuration for performance monitoring
  log_config {
    enable = true
    filter = "ERRORS_ONLY"  # Reduce log volume
  }
  
  # Source subnet configuration
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  
  subnetwork {
    name                    = google_compute_subnetwork.subnetwork.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
```

---

## ⚖️ Load Balancer Performance

### External Load Balancer Optimization

#### 1. Backend Service Configuration
```hcl
# High-performance backend service
resource "google_compute_backend_service" "optimized_backend" {
  name        = "${var.external_lb_name}-optimized-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10  # Reduced timeout for better performance
  
  # Performance-oriented settings
  connection_draining_timeout_sec = 60
  session_affinity               = "CLIENT_IP"  # For session persistence
  
  # Optimized backend configuration
  backend {
    group           = google_compute_instance_group.external_instance_group.self_link
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8  # Keep some headroom
    capacity_scaler = 1.0
  }
  
  # Health check configuration
  health_checks = [google_compute_health_check.optimized_health_check.self_link]
  
  # Enable CDN for static content
  enable_cdn = true
  
  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                 = 3600
    max_ttl                     = 86400
    client_ttl                  = 3600
    negative_caching            = true
    negative_caching_policy {
      code = 404
      ttl  = 120
    }
    
    # Cache key policy for better hit rates
    cache_key_policy {
      include_host         = true
      include_protocol     = true
      include_query_string = false
    }
  }
  
  # Security policy for performance
  security_policy = google_compute_security_policy.optimized_policy.self_link
}
```

#### 2. Optimized Health Checks
```hcl
# Performance-tuned health checks
resource "google_compute_health_check" "optimized_health_check" {
  name               = "${var.external_lb_name}-optimized-hc"
  check_interval_sec = 5   # Faster detection
  timeout_sec        = 3   # Quick timeout
  healthy_threshold  = 2   # Quick recovery
  unhealthy_threshold = 3  # Reasonable failure detection
  
  http_health_check {
    port               = var.health_check_port
    request_path       = "/health"
    proxy_header       = "NONE"
    response           = ""  # Any 2xx response is healthy
  }
  
  # Logging for performance monitoring
  log_config {
    enable = true
  }
}
```

#### 3. SSL/TLS Optimization
```hcl
# Optimized SSL configuration
resource "google_compute_target_https_proxy" "optimized_https_proxy" {
  name             = "${var.external_lb_name}-optimized-proxy"
  url_map          = google_compute_url_map.optimized_url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.optimized_ssl_cert.self_link]
  
  # SSL policy for performance and security balance
  ssl_policy = google_compute_ssl_policy.optimized_ssl_policy.self_link
}

# SSL policy for optimal performance
resource "google_compute_ssl_policy" "optimized_ssl_policy" {
  name            = "${var.external_lb_name}-optimized-ssl-policy"
  profile         = "MODERN"  # Balance of security and performance
  min_tls_version = "TLS_1_2"
  
  # Optimized cipher suites
  custom_features = [
    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
    "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
  ]
}
```

### Internal Load Balancer Optimization

#### 1. Regional Backend Service
```hcl
# Optimized internal load balancer
resource "google_compute_region_backend_service" "optimized_internal" {
  name                  = "${var.internal_lb_name}-optimized"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  timeout_sec          = 10
  
  # Performance settings
  connection_draining_timeout_sec = 30
  session_affinity               = "CLIENT_IP"
  
  backend {
    group          = google_compute_instance_group.internal_instance_group.self_link
    balancing_mode = "CONNECTION"
    max_connections = 1000
  }
  
  health_checks = [google_compute_health_check.internal_optimized_hc.self_link]
}

# Optimized internal health check
resource "google_compute_health_check" "internal_optimized_hc" {
  name               = "${var.internal_lb_name}-optimized-hc"
  check_interval_sec = 3
  timeout_sec        = 2
  healthy_threshold  = 2
  unhealthy_threshold = 2
  
  tcp_health_check {
    port = var.health_check_port
  }
}
```

---

## 💾 Storage Performance

### Persistent Volume Optimization

#### 1. Storage Classes
```yaml
# High-performance storage class
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  replication-type: regional-pd
  zones: us-central1-a,us-central1-b
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer

---
# Balanced performance storage class
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: balanced-ssd
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-balanced
  replication-type: regional-pd
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer

---
# Cost-optimized storage class
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard-hdd
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-standard
  replication-type: regional-pd
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

#### 2. Volume Performance Tuning
```yaml
# Example high-performance persistent volume claim
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: high-performance-storage
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 100Gi
  # Performance annotations
  annotations:
    volume.beta.kubernetes.io/storage-provisioner: kubernetes.io/gce-pd
    volume.kubernetes.io/storage-provisioner: kubernetes.io/gce-pd
```

### Backup Performance

#### 1. Optimized Backup Strategy
```hcl
# High-performance backup bucket
resource "google_storage_bucket" "optimized_backups" {
  name     = "${var.project_id}-optimized-backups"
  location = var.region
  
  # Performance settings
  storage_class = "STANDARD"  # For frequent access
  
  # Lifecycle management for performance and cost
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
  
  # Versioning for data protection
  versioning {
    enabled = true
  }
  
  # Performance monitoring
  logging {
    log_bucket = google_storage_bucket.access_logs.name
  }
}
```

---

## 🛡️ Security Performance

### Encryption Performance

#### 1. KMS Key Optimization
```hcl
# Optimized KMS configuration
resource "google_kms_crypto_key" "optimized_key" {
  name     = "optimized-encryption-key"
  key_ring = google_kms_key_ring.security_keyring.id
  
  # Performance-oriented settings
  purpose = "ENCRYPT_DECRYPT"
  
  # Automatic rotation for security without performance impact
  rotation_period = "7776000s"  # 90 days
  
  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"  # Better performance than HSM
  }
}
```

#### 2. Binary Authorization Performance
```hcl
# Optimized Binary Authorization policy
resource "google_binary_authorization_policy" "optimized_policy" {
  admission_whitelist_patterns {
    name_pattern = "gcr.io/${var.project_id}/*"
  }
  
  # Performance-optimized default admission rule
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    
    require_attestations_by = [
      google_binary_authorization_attestor.optimized_attestor.name
    ]
  }
  
  # Cluster-specific rules for performance
  cluster_admission_rules {
    cluster                = "projects/${var.project_id}/locations/${var.region}/clusters/${var.cluster_name}"
    evaluation_mode        = "REQUIRE_ATTESTATION"
    enforcement_mode       = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [
      google_binary_authorization_attestor.optimized_attestor.name
    ]
  }
}
```

---

## 💰 Cost Optimization

### Resource Rightsizing

#### 1. Automated Rightsizing
```hcl
# Rightsizing recommendations
resource "google_compute_project_metadata_item" "rightsizing" {
  key   = "enable-rightsizing-recommendations"
  value = "true"
}

# Committed use discounts
resource "google_compute_region_commitment" "optimized_commitment" {
  name   = "${var.environment}-optimized-commitment"
  region = var.region
  
  # 1-year commitment for cost savings
  plan = "TWELVE_MONTH"
  type = "GENERAL_PURPOSE"
  
  resources {
    type   = "VCPU"
    amount = "100"  # Adjust based on usage patterns
  }
  
  resources {
    type   = "MEMORY"
    amount = "400"  # GB of memory
  }
}
```

#### 2. Preemptible Instance Strategy
```hcl
# Preemptible node pool for batch workloads
resource "google_container_node_pool" "preemptible_pool" {
  name     = "${var.environment}-preemptible-pool"
  cluster  = google_container_cluster.primary.name
  location = var.region
  
  # Autoscaling for cost optimization
  autoscaling {
    min_node_count = 0
    max_node_count = 50
  }
  
  node_config {
    preemptible  = true
    machine_type = "e2-standard-4"
    disk_size_gb = 100
    disk_type    = "pd-standard"  # Cost-optimized storage
    
    # Taints to ensure only appropriate workloads are scheduled
    taint {
      key    = "preemptible"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
    
    # Labels for workload targeting
    labels = {
      workload-type = "batch"
      cost-optimized = "true"
    }
  }
}
```

### Scheduling Optimization

#### 1. Pod Disruption Budgets
```yaml
# Ensure availability during cost optimization
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: optimized-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: critical-app
```

#### 2. Horizontal Pod Autoscaler
```yaml
# Cost-aware autoscaling
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: optimized-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app-deployment
  minReplicas: 2
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # Balanced utilization
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Prevent flapping
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
```

---

## 📊 Performance Monitoring

### Metrics and Alerting

#### 1. Custom Metrics
```hcl
# Performance monitoring dashboard
resource "google_monitoring_dashboard" "performance_dashboard" {
  dashboard_json = jsonencode({
    displayName = "GCP Landing Zone Performance"
    mosaicLayout = {
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "GKE Node CPU Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_node\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}

# Performance alerts
resource "google_monitoring_alert_policy" "high_cpu_utilization" {
  display_name = "High CPU Utilization"
  combiner     = "OR"
  
  conditions {
    display_name = "CPU utilization above 80%"
    
    condition_threshold {
      filter          = "resource.type=\"k8s_node\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.8
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [google_monitoring_notification_channel.email.name]
}
```

#### 2. Performance Testing
```bash
#!/bin/bash
# Performance testing script

# Load testing with Apache Bench
ab -n 10000 -c 100 https://your-load-balancer-ip/

# Network performance testing
iperf3 -c your-internal-ip -t 60

# Storage performance testing
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: storage-test
spec:
  containers:
  - name: test
    image: busybox
    command: ['sh', '-c', 'dd if=/dev/zero of=/data/test bs=1M count=1000']
    volumeMounts:
    - name: test-volume
      mountPath: /data
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: test-pvc
EOF
```

---

## 🎯 Performance Benchmarks

### Target Performance Metrics

#### GKE Cluster
- **Node startup time**: < 2 minutes
- **Pod startup time**: < 30 seconds
- **CPU utilization**: 60-80% average
- **Memory utilization**: 70-85% average
- **Network latency**: < 10ms internal

#### Load Balancer
- **Response time**: < 100ms (95th percentile)
- **Throughput**: > 10,000 RPS
- **SSL handshake time**: < 50ms
- **Health check interval**: 5 seconds

#### Storage
- **IOPS**: > 3,000 (SSD volumes)
- **Throughput**: > 240 MB/s (SSD volumes)
- **Backup time**: < 30 minutes (100GB)

### Performance Testing Schedule

#### Daily Tests
- Health check response times
- Basic connectivity tests
- Resource utilization monitoring

#### Weekly Tests
- Load testing with realistic traffic patterns
- Storage performance benchmarks
- Network latency measurements

#### Monthly Tests
- Full disaster recovery testing
- Capacity planning assessments
- Cost optimization reviews

---

## 🔧 Troubleshooting Performance Issues

### Common Performance Problems

#### 1. High CPU Utilization
```bash
# Identify high CPU pods
kubectl top pods --all-namespaces --sort-by=cpu

# Check node CPU usage
kubectl top nodes

# Scale up if needed
kubectl scale deployment/app-deployment --replicas=10
```

#### 2. Memory Pressure
```bash
# Check memory usage
kubectl top pods --all-namespaces --sort-by=memory

# Identify memory leaks
kubectl describe pod high-memory-pod

# Adjust resource limits
kubectl patch deployment app-deployment -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","resources":{"limits":{"memory":"2Gi"}}}]}}}}'
```

#### 3. Network Performance Issues
```bash
# Test network connectivity
kubectl run test-pod --image=busybox --rm -it -- /bin/sh

# Check DNS resolution
nslookup kubernetes.default.svc.cluster.local

# Test bandwidth
iperf3 -c target-service
```

---

**Remember**: Performance optimization is an ongoing process. Regularly monitor, test, and adjust your configuration based on actual usage patterns and requirements!