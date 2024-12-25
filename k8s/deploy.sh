#!/usr/bin/env bash
set -Eeuo pipefail

# Colors for output (optional)
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# Function to handle errors
error_exit() {
  echo -e "${RED}$1${NC}" >&2
  exit 1
}

# Ensure required commands are installed
for cmd in kind kubectl openssl; do
  if ! command -v $cmd &> /dev/null; then
    error_exit "ERROR: $cmd is not installed or not in PATH."
  fi
done

###############################################################################
# 1. Create the KIND cluster using kind/kind-config.yaml
###############################################################################
echo -e "${GREEN}Checking for existing KIND cluster...${NC}"
if kind get clusters | grep -q "^kind$"; then
  echo -e "${GREEN}Existing KIND cluster found. Deleting it...${NC}"
  kind delete cluster || error_exit "Failed to delete existing KIND cluster"
fi

echo -e "${GREEN}Creating KIND cluster...${NC}"
kind create cluster --config kind/kind-config.yaml || error_exit "Failed to create KIND cluster"

###############################################################################
# 2. Create the namespace
###############################################################################
echo -e "${GREEN}Applying namespace...${NC}"
kubectl apply -f namespace.yaml || error_exit "Failed to apply namespace."

###############################################################################
# 3. Deploy MariaDB
###############################################################################
echo -e "${GREEN}Deploying MariaDB...${NC}"
kubectl apply -f maria/mariadb-cfgmap.yaml
kubectl apply -f maria/mariadb-secret.yaml
kubectl apply -f maria/mariadb-service.yaml
kubectl apply -f maria/mariadb-sts.yaml

# Wait for MariaDB to be ready
echo -e "${GREEN}Waiting for MariaDB to be ready...${NC}"
ATTEMPTS=0
MAX_ATTEMPTS=30
until kubectl get pods -n app -l app=mariadb -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null | grep -q "true"; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
    error_exit "MariaDB failed to become ready within the timeout."
  fi
  echo -e "${GREEN}MariaDB not ready yet. Retrying in 10 seconds... ($ATTEMPTS/$MAX_ATTEMPTS)${NC}"
  sleep 10
done
echo -e "${GREEN}MariaDB is ready.${NC}"

###############################################################################
# 4. Deploy Redis
###############################################################################
echo -e "${GREEN}Deploying Redis...${NC}"
kubectl apply -f redis/redis-deployment.yaml
kubectl apply -f redis/redis-service.yaml

# Wait for Redis to be ready
echo -e "${GREEN}Waiting for Redis to be ready...${NC}"
ATTEMPTS=0
MAX_ATTEMPTS=30
until kubectl get pods -n app -l app=redis -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null | grep -q "true"; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
    error_exit "Redis failed to become ready within the timeout."
  fi
  echo -e "${GREEN}Redis not ready yet. Retrying in 10 seconds... ($ATTEMPTS/$MAX_ATTEMPTS)${NC}"
  sleep 10
done
echo -e "${GREEN}Redis is ready.${NC}"

###############################################################################
# 5. Deploy the Flask app
###############################################################################
echo -e "${GREEN}Deploying Flask app...${NC}"
kubectl apply -f app/app-deployment.yaml
kubectl apply -f app/app-service.yaml

# Wait for Flask app to be ready
echo -e "${GREEN}Waiting for Flask app to be ready...${NC}"
ATTEMPTS=0
MAX_ATTEMPTS=30
until kubectl get pods -n app -l app=flask-app -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null | grep -q "true"; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
    error_exit "Flask app failed to become ready within the timeout."
  fi
  echo -e "${GREEN}Flask app not ready yet. Retrying in 10 seconds... ($ATTEMPTS/$MAX_ATTEMPTS)${NC}"
  sleep 10
done
echo -e "${GREEN}Flask app is ready.${NC}"

###############################################################################
# 6. Create TLS certificates
###############################################################################
echo -e "${GREEN}Creating TLS certificates...${NC}"
CERT_DIR=$(mktemp -d) || error_exit "Failed to create temporary directory."

# Generate a private key
openssl genrsa -out "$CERT_DIR/privkey.pem" 2048 || error_exit "Failed to generate private key."

# Create a self-signed certificate
openssl req -new -x509 -key "$CERT_DIR/privkey.pem" -out "$CERT_DIR/fullchain.pem" -days 365 \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=$(hostname -I | awk '{print $1}')" || error_exit "Failed to create self-signed certificate."

# Create Kubernetes secret with the generated certificates
echo -e "${GREEN}Creating Kubernetes secret for TLS...${NC}"
kubectl create secret generic nginx-tls --namespace app \
  --from-file=privkey.pem="$CERT_DIR/privkey.pem" \
  --from-file=fullchain.pem="$CERT_DIR/fullchain.pem" || error_exit "Failed to create nginx-tls secret."

# Clean up temporary files
rm -rf "$CERT_DIR"
echo -e "${GREEN}TLS certificates and Kubernetes secret created successfully.${NC}"

###############################################################################
# 7. Deploy Nginx
###############################################################################
echo -e "${GREEN}Deploying Nginx...${NC}"
kubectl apply -f nginx/nginx-cfgmap.yaml
kubectl apply -f nginx/nginx-secret-passwd.yaml
kubectl apply -f nginx/nginx-deployment.yaml
kubectl apply -f nginx/nginx-service.yaml

# Wait for Nginx to be ready
echo -e "${GREEN}Waiting for Nginx to be ready...${NC}"
ATTEMPTS=0
MAX_ATTEMPTS=30
until kubectl get pods -n app -l app=nginx -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null | grep -q "true"; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
    error_exit "Nginx failed to become ready within the timeout."
  fi
  echo -e "${GREEN}Nginx not ready yet. Retrying in 10 seconds... ($ATTEMPTS/$MAX_ATTEMPTS)${NC}"
  sleep 10
done
echo -e "${GREEN}Nginx is ready.${NC}"

###############################################################################
# End of script
###############################################################################
echo -e "${GREEN}Deploy completed successfully.${NC}"

