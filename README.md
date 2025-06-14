# GCP Landing Zone with Terragrunt and OpenTofu

This project provides a comprehensive Google Cloud Platform (GCP) landing zone using Terragrunt and OpenTofu for infrastructure as code. It deploys a complete enterprise-ready infrastructure including VPC networking, GKE clusters, load balancers, and Gateway API configurations across multiple environments.

## 🔓 Why OpenTofu?

This project uses OpenTofu instead of Terraform for the following benefits:

- **Open Source**: Truly open-source fork of Terraform, ensuring long-term sustainability
- **Community Driven**: Governed by the Linux Foundation with transparent development
- **License Freedom**: MPL 2.0 license without the restrictions of HashiCorp's BSL
- **Compatibility**: Drop-in replacement for Terraform with full compatibility
- **Innovation**: Faster feature development and community contributions
- **Vendor Neutral**: No single vendor control over the project direction

## 🏗️ Infrastructure Components

The landing zone includes the following components:

### Networking
- **VPC Network** with custom subnets
- **Cloud Router** and **NAT Gateway** for outbound internet access
- **Reserved External IP addresses** for NAT and Load Balancers
- **Secondary IP ranges** for GKE pods and services
- **Firewall rules** for security

### Compute (GKE)
- **Private GKE clusters** with Workload Identity
- **Node pools** with autoscaling
- **Service accounts** with minimal required permissions
- **Network policies** enabled
- **Maintenance windows** configured

### Load Balancing
- **External Load Balancer** (Global)
- **Internal Load Balancer** (Regional)
- **Health checks** and **backend services**
- **SSL certificates** for HTTPS
- **Gateway API** configuration for external and internal APIs

## 📁 Project Structure

```
gcp-landing-zone/
├── terragrunt.hcl                    # Root Terragrunt configuration
├── common/
│   └── terragrunt.hcl               # Common settings across environments
├── environments/
│   ├── dev/
│   │   ├── terragrunt.hcl           # Dev environment config
│   │   ├── networking/
│   │   │   └── terragrunt.hcl       # Dev networking resources
│   │   ├── compute/
│   │   │   └── terragrunt.hcl       # Dev GKE cluster
│   │   └── load-balancer/
│   │       └── terragrunt.hcl       # Dev load balancers
│   ├── staging/                     # Staging environment (similar structure)
│   └── prod/                        # Production environment (similar structure)
├── modules/
│   ├── networking/                  # VPC, subnets, NAT, firewall rules
│   ├── compute/                     # GKE cluster and node pools
│   └── load-balancer/              # External/internal LBs and Gateway API
├── deploy.sh                        # Deployment automation script
└── README.md
```

## 🚀 Quick Start

### Prerequisites

1. **Install required tools:**
   ```bash
   # Install OpenTofu
   brew install opentofu
   
   # Install Terragrunt
   brew install terragrunt
   
   # Install Google Cloud SDK
   brew install google-cloud-sdk
   ```

2. **Configure GCP Authentication:**
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   
   # Create and download service account key
   gcloud iam service-accounts create terragrunt-sa
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:terragrunt-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/editor"
   gcloud iam service-accounts keys create ~/gcp-key.json \
     --iam-account=terragrunt-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com
   
   export GOOGLE_APPLICATION_CREDENTIALS=~/gcp-key.json
   ```

3. **Update Configuration:**
   - Edit `terragrunt.hcl` and update the GCS bucket name for remote state
   - Update `common/terragrunt.hcl` with your project ID and preferred region

### Deployment

Use the provided deployment script for easy infrastructure management:

```bash
# Plan infrastructure for dev environment
./deploy.sh dev plan

# Deploy dev environment
./deploy.sh dev apply

# Deploy staging environment
./deploy.sh staging apply

# Deploy production environment
./deploy.sh prod apply

# Destroy an environment (be careful!)
./deploy.sh dev destroy
```

### Manual Deployment

For manual deployment, navigate to the specific environment and component:

```bash
# Deploy networking for dev environment
cd environments/dev/networking
terragrunt plan
terragrunt apply

# Deploy GKE cluster for dev environment
cd ../compute
terragrunt apply

# Deploy load balancers for dev environment
cd ../load-balancer
terragrunt apply
```

### Quick Migration from Terraform

If you're migrating from Terraform to OpenTofu, use the provided migration script:

```bash
# Run the migration helper script
./migrate-to-opentofu.sh
```

This script will:
- Install OpenTofu on your system
- Verify Terragrunt installation
- Check for existing Terraform state (fully compatible)
- Provide next steps for migration

## 🔧 Configuration

### Environment-Specific Settings

Each environment has different configurations:

| Component | Dev | Staging | Production |
|-----------|-----|---------|------------|
| Subnet CIDR | 10.0.1.0/24 | 10.0.2.0/24 | 10.0.3.0/24 |
| Pods CIDR | 10.1.0.0/16 | 10.3.0.0/16 | 10.5.0.0/16 |
| Services CIDR | 10.2.0.0/16 | 10.4.0.0/16 | 10.6.0.0/16 |
| GKE Machine Type | e2-standard-2 | e2-standard-4 | e2-standard-8 |
| Min Nodes | 1 | 1 | 2 |
| Max Nodes | 3 | 5 | 10 |

### Customization

To customize the infrastructure:

1. **Update variables** in the environment-specific `terragrunt.hcl` files
2. **Modify modules** in the `modules/` directory for component-specific changes
3. **Add new components** by creating new modules and environment configurations

## 🔐 Security Features

This landing zone implements enterprise-grade security controls:

- **Defense in Depth**: Multi-layer security architecture
- **Cloud Armor WAF**: Protection against OWASP Top 10 vulnerabilities
- **Private GKE Clusters**: No public endpoints, private nodes only
- **Binary Authorization**: Only signed container images allowed
- **Workload Identity**: Secure pod-to-GCP service authentication
- **Customer-Managed Encryption**: KMS keys for data protection
- **VPC Flow Logs**: Complete network traffic monitoring
- **Security Command Center**: Real-time threat detection
- **Compliance Ready**: SOC 2, ISO 27001, PCI DSS alignment

📖 **[Complete Security Guide](SECURITY.md)** - Detailed security architecture and controls

## 📊 Monitoring and Maintenance

- **GKE maintenance windows** configured for weekends
- **Node auto-repair** and **auto-upgrade** enabled
- **Logging and monitoring** configured through GCP operations suite
- **Health checks** configured for load balancers

## 🔄 State Management

- **Remote state** stored in Google Cloud Storage
- **State locking** handled by GCS
- **Separate state files** for each environment and component
- **State file encryption** at rest

## 📝 Best Practices

1. **Always run `plan` before `apply`**
2. **Use the deployment script** for consistent deployments
3. **Review changes** in pull requests before merging
4. **Test in dev/staging** before deploying to production
5. **Keep modules version-pinned** for stability
6. **Use workload identity** instead of service account keys in GKE

## 🐛 Troubleshooting

### Common Issues

1. **GCS bucket doesn't exist:**
   ```bash
   gsutil mb gs://your-terraform-state-bucket
   ```

2. **Insufficient permissions:**
   ```bash
   # Ensure your service account has the required roles
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:your-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/container.admin"
   ```

3. **API not enabled:**
   ```bash
   gcloud services enable container.googleapis.com
   gcloud services enable compute.googleapis.com
   ```

4. **OpenTofu installation issues:**
   ```bash
   # Install OpenTofu on macOS
   brew install opentofu
   
   # Install OpenTofu on Linux
   curl -fsSL https://get.opentofu.org/install-opentofu.sh | sh
   
   # Verify installation
   tofu version
   ```

5. **Terragrunt binary configuration:**
   ```bash
   # Ensure Terragrunt uses OpenTofu
   export TERRAGRUNT_TFPATH=tofu
   
   # Or set in terragrunt.hcl
   terraform_binary = "tofu"
   ```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test in dev environment
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## License

This project is licensed under the MIT License. See the LICENSE file for details.