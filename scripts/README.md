# Kubecost Scripts

This directory contains utility scripts for working with Kubecost data and APIs, as well as setup scripts for local testing environments.

## Scripts Overview

| Script Name | Description | Language |
|-------------|-------------|----------|
| [allocation-query-reconciled-csv.py](#allocation-query-reconciled-csvpy) | Queries Kubecost allocation data for a specific date and exports to CSV | Python |
| [setup-local-test-environment.sh](#setup-local-test-environmentsh) | Automated setup for local Kubernetes testing environment | Bash |
| [continue-setup.sh](#continue-setupsh) | Post-setup configuration helper | Bash |

---

## Script Details

### allocation-query-reconciled-csv.py

**Purpose**: Queries the Kubecost API for allocation data from 2 days ago and outputs the data in CSV format.

**Requirements**:
- Python 3.x
- `requests` library (`pip install requests`)

**Usage**:
```bash
python allocation-query-reconciled-csv.py <kubecost_url>
```

**Example**:
```bash
python allocation-query-reconciled-csv.py kubecost.example.com
```

**Example Output**:
```
Kubecost API Query Script
==================================================
Using Kubecost URL: kubecost.example.com
Querying Kubecost for date: 2025-06-18
URL: https://kubecost.example.com/model/allocation/summary?accumulate=true&aggregate=namespace%2Cpod&chartType=costovertime&costUnit=daily&external=false&filter=&idle=true&idleByNode=false&includeSharedCostBreakdown=false&shareCost=0&shareIdle=false&shareLabels=&shareNamespaces=&shareSplit=weighted&shareTenancyCosts=false&window=2025-06-18T00%3A00%3A00Z%2C2025-06-18T23%3A59%3A59Z&offset=0&limit=25&format=csv
--------------------------------------------------------------------------------
API Response Status: SUCCESS
Response Size: 12345 bytes

Response Data Preview:
['namespace,pod,cpuCost,ramCost,gpuCost,pvCost,networkCost,loadBalancerCost,externalCost,totalCost', 'kube-system,coredns-123456,0.12,0.05,0.00,0.00,0.01,0.00,0.00,0.18', 'default,app-frontend-123456,0.25,0.15,0.00,0.02,0.03,0.01,0.00,0.46']

==================================================
Query completed successfully!
Data saved to CSV: kubecost_data_2025-06-18.csv
```

**Description**:
This script queries the Kubecost API for allocation data from 2 days ago. It formats the request to get data for a single day in CSV format and saves the response to a CSV file named with the target date (e.g., `kubecost_data_2025-06-18.csv`).

The script:
1. Takes a Kubecost URL as a command-line parameter
2. Calculates the date from 2 days ago
3. Constructs a properly formatted API request to the Kubecost allocation endpoint
4. Requests the data in CSV format
5. Saves the response directly to a CSV file
6. Provides status updates and error handling

**Customization**:
- To change the target date, modify the `timedelta(days=2)` value in the script
- To change the aggregation level, modify the `aggregate` parameter in the `params` dictionary
- To change the output format, modify the `format` parameter in the `params` dictionary
- To use a different protocol (e.g., http instead of https), modify the `base_url` line in the script

---

### setup-local-test-environment.sh

Automated setup script that installs all necessary tools and creates a local Kubernetes cluster for testing Kubecost agent deployments.

#### What It Does

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

#### Supported Operating Systems

- **Fedora Linux** (native support with dnf)
- **Ubuntu/Debian** (native support with apt)
- **macOS** (with Homebrew)
- **Other Linux distributions** (fallback to binary installations)

#### Usage

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

#### What Gets Installed

| Tool | Purpose | Version |
|------|---------|---------|
| Docker | Container runtime for kind | Latest stable |
| kubectl | Kubernetes CLI | Latest stable |
| Helm | Kubernetes package manager | Helm 3 (latest) |
| kind | Local Kubernetes clusters | v0.20.0 |
| Terraform | Infrastructure as Code | Latest stable |
| GitHub CLI | GitHub automation (optional) | Latest stable |

#### Post-Installation Steps

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

#### Cluster Details

The script creates a kind cluster with:
- **Name**: `kubecost-test`
- **Context**: `kind-kubecost-test`
- **Nodes**: 1 control-plane + 2 workers
- **Port mapping**: 30000 (host) → 30000 (container)
- **Namespace**: `kubecost` (pre-created)

#### Fedora-Specific Notes

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

#### Cleanup

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

#### Troubleshooting

**Docker Permission Denied**

If you get permission errors with Docker:
```bash
# Check if you're in the docker group
groups

# If not, the script should have added you, but you need to refresh:
newgrp docker

# Or log out and back in
```

**Kind Cluster Creation Fails**

If cluster creation fails:
```bash
# Check Docker is running
sudo systemctl status docker

# Start Docker if needed (Fedora)
sudo systemctl start docker

# Try creating cluster manually
kind create cluster --name kubecost-test
```

**kubectl Connection Issues**

If kubectl can't connect:
```bash
# Verify cluster is running
kind get clusters

# Set the correct context
kubectl config use-context kind-kubecost-test

# Verify connection
kubectl cluster-info
```

#### Example Configuration Files

The script creates these files in the `examples/` directory:

- **terraform.tfvars.example**: Example Terraform variables
- **values.yaml.example**: Example Helm values
- **test-deploy.sh**: Quick deployment script for Helm

Copy the `.example` files and update with your actual credentials before use.

#### Requirements

- **Disk Space**: ~5GB for Docker images and tools
- **Memory**: 4GB+ recommended for kind cluster
- **Internet**: Required for downloading tools and images
- **Permissions**: sudo access for installing system packages

#### Security Notes

- The script creates a test secret with a placeholder token
- **Always replace** the placeholder with your actual Kubecost SaaS token
- Never commit actual credentials to version control
- Use the example files as templates, not for production

---

### continue-setup.sh

Post-setup configuration helper script for continuing the Kubecost deployment after the initial environment setup.

---

## Adding New Scripts

When adding new scripts to this directory, please:

1. Follow the naming convention: descriptive names with hyphens between words
2. Include a docstring at the top of the script explaining its purpose
3. Add proper error handling and logging
4. Update this README.md with details about your script following the template below

### Template for New Script Documentation

```markdown
### script-name.py

**Purpose**: Brief description of what the script does.

**Requirements**:
- Required software/libraries

**Usage**:
```bash
python script-name.py [arguments]
```

**Example Output**:
```
Example output here
```

**Description**:
Detailed description of what the script does, how it works, and any important information users should know.

**Customization**:
- Notes on how to customize or configure the script
```

---

## Support

For issues with these scripts, please contact the Kubecost team or file an issue in the repository.