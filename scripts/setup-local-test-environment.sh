#!/bin/bash

# Kubecost Local Test Environment Setup Script
# This script installs all necessary tools and sets up a local Kubernetes cluster for testing
# Supports: Fedora, Ubuntu, Debian, macOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    log_info "Detected OS: $OS (Distribution: ${DISTRO:-unknown})"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Docker
install_docker() {
    if command_exists docker; then
        log_success "Docker is already installed: $(docker --version)"
        return
    fi

    log_info "Installing Docker..."
    
    if [[ "$OS" == "linux" ]]; then
        if [[ "$DISTRO" == "fedora" ]]; then
            log_info "Installing Docker on Fedora..."
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            log_warning "You may need to log out and back in for Docker group membership to take effect"
        elif [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            rm get-docker.sh
            log_warning "You may need to log out and back in for Docker group membership to take effect"
        else
            log_error "Please install Docker manually for your Linux distribution"
            exit 1
        fi
    elif [[ "$OS" == "macos" ]]; then
        log_warning "Please install Docker Desktop for Mac from: https://www.docker.com/products/docker-desktop"
        log_warning "After installation, run this script again"
        exit 1
    fi
    
    log_success "Docker installed successfully"
}

# Install kubectl
install_kubectl() {
    if command_exists kubectl; then
        log_success "kubectl is already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
        return
    fi

    log_info "Installing kubectl..."
    
    if [[ "$OS" == "linux" ]]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    elif [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew install kubectl
        else
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
        fi
    fi
    
    log_success "kubectl installed successfully: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
}

# Install Helm
install_helm() {
    if command_exists helm; then
        log_success "Helm is already installed: $(helm version --short)"
        return
    fi

    log_info "Installing Helm..."
    
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    log_success "Helm installed successfully: $(helm version --short)"
}

# Install kind (Kubernetes in Docker)
install_kind() {
    if command_exists kind; then
        log_success "kind is already installed: $(kind version)"
        return
    fi

    log_info "Installing kind..."
    
    if [[ "$OS" == "linux" ]]; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    elif [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew install kind
        else
            curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-amd64
            chmod +x ./kind
            sudo mv ./kind /usr/local/bin/kind
        fi
    fi
    
    log_success "kind installed successfully: $(kind version)"
}

# Install Terraform
install_terraform() {
    if command_exists terraform; then
        log_success "Terraform is already installed: $(terraform version | head -n1)"
        return
    fi

    log_info "Installing Terraform..."
    
    if [[ "$OS" == "linux" ]]; then
        if [[ "$DISTRO" == "fedora" ]]; then
            log_info "Installing Terraform on Fedora..."
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
            sudo dnf -y install terraform
        elif [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
            wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt update && sudo apt install terraform -y
        else
            log_warning "Installing Terraform via binary download..."
            TERRAFORM_VERSION="1.6.6"
            wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
            unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
            sudo mv terraform /usr/local/bin/
            rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
        fi
    elif [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew tap hashicorp/tap
            brew install hashicorp/tap/terraform
        else
            log_error "Please install Homebrew first or install Terraform manually"
            exit 1
        fi
    fi
    
    log_success "Terraform installed successfully: $(terraform version | head -n1)"
}

# Install GitHub CLI (optional but useful)
install_gh_cli() {
    if command_exists gh; then
        log_success "GitHub CLI is already installed: $(gh --version | head -n1)"
        return
    fi

    log_info "Installing GitHub CLI..."
    
    if [[ "$OS" == "linux" ]]; then
        if [[ "$DISTRO" == "fedora" ]]; then
            sudo dnf install -y 'dnf-command(config-manager)'
            sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
            sudo dnf install -y gh
        elif [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update
            sudo apt install gh -y
        fi
    elif [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew install gh
        fi
    fi
    
    if command_exists gh; then
        log_success "GitHub CLI installed successfully: $(gh --version | head -n1)"
    else
        log_warning "GitHub CLI installation skipped (optional)"
    fi
}

# Create local Kubernetes cluster
create_kind_cluster() {
    CLUSTER_NAME="kubecost-test"
    
    # Check if we can access Docker
    if ! docker info >/dev/null 2>&1; then
        log_error "Cannot access Docker. This usually means:"
        log_error "1. Docker service is not running, or"
        log_error "2. Your user needs to be in the 'docker' group"
        echo ""
        log_info "To fix this, run:"
        echo "  sudo systemctl start docker"
        echo "  newgrp docker"
        echo ""
        log_info "Or log out and back in, then run this script again."
        exit 1
    fi
    
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        log_warning "Cluster '${CLUSTER_NAME}' already exists"
        read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Deleting existing cluster..."
            kind delete cluster --name ${CLUSTER_NAME}
        else
            log_info "Using existing cluster"
            kubectl cluster-info --context kind-${CLUSTER_NAME}
            return
        fi
    fi

    log_info "Creating kind cluster '${CLUSTER_NAME}'..."
    
    cat <<EOF | kind create cluster --name ${CLUSTER_NAME} --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
- role: worker
- role: worker
EOF

    log_success "Kind cluster created successfully"
    kubectl cluster-info --context kind-${CLUSTER_NAME}
}

# Add Helm repositories
setup_helm_repos() {
    log_info "Adding Helm repositories..."
    
    helm repo add kubecost https://kubecost.github.io/cost-analyzer/ || true
    helm repo update
    
    log_success "Helm repositories configured"
}

# Create test namespace
create_test_namespace() {
    log_info "Creating kubecost namespace..."
    
    kubectl create namespace kubecost --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Namespace created"
}

# Create sample secrets for testing
create_test_secrets() {
    log_info "Creating test secrets..."
    
    # Create a dummy token secret
    kubectl create secret generic kubecost-token \
        --from-literal=token="test-token-replace-with-real-token" \
        --namespace kubecost \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_success "Test secrets created"
    log_warning "Remember to update the kubecost-token secret with your actual SaaS token!"
}

# Create example configuration files
create_example_configs() {
    log_info "Creating example configuration files..."
    
    mkdir -p examples
    
    # Create example terraform.tfvars
    cat > examples/terraform.tfvars.example <<'EOF'
# Kubecost Agent Configuration
cluster_name         = "local-test-cluster"
kubecost_token       = "your-saas-token-here"
kubecost_primary_url = "https://kubecost.ibm.example.com"
namespace            = "kubecost"

# Optional: Customize resources
agent_resources = {
  requests = {
    cpu    = "200m"
    memory = "512Mi"
  }
  limits = {
    cpu    = "1000m"
    memory = "2Gi"
  }
}
EOF

    # Create example values.yaml for Helm
    cat > examples/values.yaml.example <<'EOF'
# Kubecost SaaS Agent Configuration
global:
  agent:
    enabled: true
    cloudCost:
      enabled: false
  
  kubecostToken: "your-saas-token-here"
  kubecostPrimaryCluster: "https://kubecost.ibm.example.com"

kubecostProductConfigs:
  clusterName: "local-test-cluster"

agent:
  enabled: true

prometheus:
  server:
    enabled: false
  nodeExporter:
    enabled: false

kubecostModel:
  resources:
    requests:
      cpu: "200m"
      memory: "512Mi"
    limits:
      cpu: "1000m"
      memory: "2Gi"
EOF

    # Create test deployment script
    cat > examples/test-deploy.sh <<'EOF'
#!/bin/bash

# Quick test deployment script
set -e

echo "Deploying Kubecost agent to local cluster..."

# Check if values file exists
if [ ! -f "values.yaml" ]; then
    echo "Error: values.yaml not found. Copy from values.yaml.example and update with your credentials."
    exit 1
fi

# Deploy with Helm
helm upgrade --install kubecost-agent kubecost/cost-analyzer \
    --namespace kubecost \
    --create-namespace \
    --values values.yaml \
    --wait

echo "Deployment complete!"
echo ""
echo "Check status with:"
echo "  kubectl get pods -n kubecost"
echo ""
echo "View logs with:"
echo "  kubectl logs -n kubecost -l app.kubernetes.io/name=cost-analyzer -f"
EOF

    chmod +x examples/test-deploy.sh
    
    log_success "Example configuration files created in ./examples/"
}

# Print summary and next steps
print_summary() {
    echo ""
    echo "=========================================="
    log_success "Local test environment setup complete!"
    echo "=========================================="
    echo ""
    echo "Installed tools:"
    echo "  - Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
    echo "  - kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -n1)"
    echo "  - Helm: $(helm version --short 2>/dev/null)"
    echo "  - kind: $(kind version 2>/dev/null)"
    echo "  - Terraform: $(terraform version 2>/dev/null | head -n1)"
    echo "  - GitHub CLI: $(gh --version 2>/dev/null | head -n1 || echo 'Not installed (optional)')"
    echo ""
    echo "Kubernetes cluster:"
    echo "  - Name: kubecost-test"
    echo "  - Context: kind-kubecost-test"
    echo "  - Namespace: kubecost"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Update test secrets with your actual Kubecost SaaS credentials:"
    echo "   kubectl create secret generic kubecost-token \\"
    echo "     --from-literal=token='YOUR-ACTUAL-TOKEN' \\"
    echo "     --namespace kubecost --dry-run=client -o yaml | kubectl apply -f -"
    echo ""
    echo "2. Test Terraform deployment:"
    echo "   cd terraform/kubecost-agent"
    echo "   cp ../../examples/terraform.tfvars.example terraform.tfvars"
    echo "   # Edit terraform.tfvars with your credentials"
    echo "   terraform init"
    echo "   terraform plan"
    echo "   terraform apply"
    echo ""
    echo "3. Or test Helm deployment:"
    echo "   cd examples"
    echo "   cp values.yaml.example values.yaml"
    echo "   # Edit values.yaml with your credentials"
    echo "   ./test-deploy.sh"
    echo ""
    echo "4. Verify deployment:"
    echo "   kubectl get pods -n kubecost"
    echo "   kubectl logs -n kubecost -l app.kubernetes.io/name=cost-analyzer"
    echo ""
    echo "5. Clean up when done:"
    echo "   kind delete cluster --name kubecost-test"
    echo ""
    
    if [[ "$DISTRO" == "fedora" ]]; then
        log_info "Fedora-specific notes:"
        echo "  - If you encounter Docker permission issues, run: newgrp docker"
        echo "  - Or log out and back in for group changes to take effect"
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "Kubecost Local Test Environment Setup"
    echo "=========================================="
    echo ""
    
    detect_os
    
    log_info "Installing required tools..."
    install_docker
    install_kubectl
    install_helm
    install_kind
    install_terraform
    install_gh_cli
    
    log_info "Setting up local Kubernetes cluster..."
    create_kind_cluster
    setup_helm_repos
    create_test_namespace
    create_test_secrets
    
    log_info "Creating example configurations..."
    create_example_configs
    
    print_summary
}

# Run main function
main

# Made with Bob
