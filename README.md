# Install Docker on Linux

## Prerequisites
Ensure your system is up to date:
```bash
sudo apt update && sudo apt upgrade -y
```

## Install Docker
1. Install necessary packages:
   ```bash
   sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
   ```
2. Add Docker's GPG key:
   ```bash
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   ```
3. Add the Docker repository:
   ```bash
   echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```
4. Install Docker:
   ```bash
   sudo apt update
   sudo apt install docker-ce docker-ce-cli containerd.io -y
   ```
5. Verify Docker installation:
   ```bash
   docker --version
   ```
6. (Optional) Add your user to the `docker` group to run Docker without `sudo`:
   ```bash
   sudo usermod -aG docker $USER
   ```
   **Log out and log back in for this to take effect.**

---

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

## Install the flask app
```bash
cd k8s
./deploy.sh
```

Run forward to make it accessible outside (workaround due to kind networking being weird):
```bash
./forward &

