# Setup Scripts

This directory contains scripts to help set up and test the Kubecost deployment examples.

## setup-local-test-environment.sh

Automated setup script that installs all necessary tools and creates a local Kubernetes cluster for testing Kubecost agent deployments.

### What It Does

1. **Detects your operating system** (Fedora, Ubuntu, Debian, macOS)
2. **Installs required tools**:
   - Docker
   - kubectl
   - Helm
   - kind (Kubernetes in Docker)
   - Terraform
   - GitHub CLI (optional)
3. **Creates a local Kubernetes cluster** using kind
4. **Sets up Helm repositories** for Kubecost
5. **Creates test namespace and secrets**
6. **Generates example configuration files**

### Supported Operating Systems

- **Fedora Linux** (native support with dnf)
- **Ubuntu/Debian** (native support with apt)
- **macOS** (with Homebrew)
- **Other Linux distributions** (fallback to binary installations)

### Usage

```bash
# Make the script executable
chmod +x scripts/setup-local-test-environment.sh

# Run the script
./scripts/setup-local-test-environment.sh
```

The script will:
- Check for existing installations and skip if already present
- Install missing tools automatically
- Create a 3-node kind cluster named `kubecost-test`
- Set up example configuration files in the `examples/` directory

### What Gets Installed

| Tool | Purpose | Version |
|------|---------|---------|
| Docker | Container runtime for kind | Latest stable |
| kubectl | Kubernetes CLI | Latest stable |
| Helm | Kubernetes package manager | Helm 3 (latest) |
| kind | Local Kubernetes clusters | v0.20.0 |
| Terraform | Infrastructure as Code | Latest stable |
| GitHub CLI | GitHub automation (optional) | Latest stable |

### Post-Installation Steps

After running the script, you'll need to:

1. **Update credentials** in the test secret:
   ```bash
   kubectl create secret generic kubecost-token \
     --from-literal=token='YOUR-ACTUAL-SAAS-TOKEN' \
     --namespace kubecost \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

2. **Choose your deployment method**:

   **Option A: Terraform**
   ```bash
   cd terraform/kubecost-agent
   cp ../../examples/terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your credentials
   terraform init
   terraform plan
   terraform apply
   ```

   **Option B: Helm**
   ```bash
   cd examples
   cp values.yaml.example values.yaml
   # Edit values.yaml with your credentials
   ./test-deploy.sh
   ```

3. **Verify the deployment**:
   ```bash
   kubectl get pods -n kubecost
   kubectl logs -n kubecost -l app.kubernetes.io/name=cost-analyzer -f
   ```

### Cluster Details

The script creates a kind cluster with:
- **Name**: `kubecost-test`
- **Context**: `kind-kubecost-test`
- **Nodes**: 1 control-plane + 2 workers
- **Port mapping**: 30000 (host) → 30000 (container)
- **Namespace**: `kubecost` (pre-created)

### Fedora-Specific Notes

For Fedora users, the script:
- Uses `dnf` package manager
- Installs Docker from the official Docker repository
- Installs Terraform from HashiCorp's Fedora repository
- Installs GitHub CLI from the official GitHub repository
- Starts and enables Docker service automatically

If you encounter Docker permission issues after installation:
```bash
# Apply group changes without logging out
newgrp docker

# Or log out and back in for permanent effect
```

### Cleanup

To remove the test cluster when done:
```bash
kind delete cluster --name kubecost-test
```

To uninstall tools (if needed):
```bash
# Fedora
sudo dnf remove docker-ce docker-ce-cli containerd.io terraform gh

# Ubuntu/Debian
sudo apt remove docker-ce docker-ce-cli containerd.io terraform gh
```

### Troubleshooting

#### Docker Permission Denied

If you get permission errors with Docker:
```bash
# Check if you're in the docker group
groups

# If not, the script should have added you, but you need to refresh:
newgrp docker

# Or log out and back in
```

#### Kind Cluster Creation Fails

If cluster creation fails:
```bash
# Check Docker is running
sudo systemctl status docker

# Start Docker if needed (Fedora)
sudo systemctl start docker

# Try creating cluster manually
kind create cluster --name kubecost-test
```

#### kubectl Connection Issues

If kubectl can't connect:
```bash
# Verify cluster is running
kind get clusters

# Set the correct context
kubectl config use-context kind-kubecost-test

# Verify connection
kubectl cluster-info
```

### Example Configuration Files

The script creates these files in the `examples/` directory:

- **terraform.tfvars.example**: Example Terraform variables
- **values.yaml.example**: Example Helm values
- **test-deploy.sh**: Quick deployment script for Helm

Copy the `.example` files and update with your actual credentials before use.

### Requirements

- **Disk Space**: ~5GB for Docker images and tools
- **Memory**: 4GB+ recommended for kind cluster
- **Internet**: Required for downloading tools and images
- **Permissions**: sudo access for installing system packages

### Security Notes

- The script creates a test secret with a placeholder token
- **Always replace** the placeholder with your actual Kubecost SaaS token
- Never commit actual credentials to version control
- Use the example files as templates, not for production

## Contributing

To add support for additional operating systems or improve the script:

1. Test on your target OS
2. Add detection logic in `detect_os()`
3. Add installation functions for your package manager
4. Update this README with the new OS support
5. Submit a pull request

## License

[Your License Here]