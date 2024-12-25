# Install kind (Kubernetes IN Docker) on Linux

## Prerequisites
- Docker installed ([Get Docker](https://www.docker.com/get-started)).
- kubectl installed:
  1. Download kubectl:
     ```bash
     curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
     ```
  2. Make it executable:
     ```bash
     chmod +x ./kubectl
     ```
  3. Move to PATH:
     ```bash
     sudo mv ./kubectl /usr/local/bin/kubectl
     ```

## Install kind
1. Download kind:
   ```bash
   curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
   ```
2. Make it executable:
   ```bash
   chmod +x ./kind
   ```
3. Move to PATH:
   ```bash
   sudo mv ./kind /usr/local/bin/kind
   ```

## Verify Installations
- Verify kind:
  ```bash
  kind version
  ```
- Verify kubectl:
  ```bash
  kubectl version --client
  ```

## Create a Cluster
```bash
kind create cluster
```

