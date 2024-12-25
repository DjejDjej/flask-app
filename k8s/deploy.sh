#!/usr/bin/env bash
set -Eeuo pipefail

# Colors for output (optional)
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

###############################################################################
# 1. Check dependencies
###############################################################################
if ! command -v kind &> /dev/null; then
  echo -e "${RED}ERROR: kind is not installed or not in PATH.${NC}"
  exit 1
fi

if ! command -v kubectl &> /dev/null; then
  echo -e "${RED}ERROR: kubectl is not installed or not in PATH.${NC}"
  exit 1
fi

###############################################################################
# 2. Create the KIND cluster using kind/kind-config.yaml
###############################################################################
echo -e "${GREEN}Creating KIND cluster...${NC}"
kind create cluster --config kind/kind-config.yaml || {
  echo -e "${RED}Failed to create KIND cluster${NC}"
  exit 1
}

###############################################################################
# 3. Create the namespace
###############################################################################
echo -e "${GREEN}Applying namespace...${NC}"
kubectl apply -f namespace.yaml

###############################################################################
# 4. Deploy MariaDB
###############################################################################
echo -e "${GREEN}Deploying MariaDB...${NC}"
kubectl apply -f maria/mariadb-cfgmap.yaml
kubectl apply -f maria/mariadb-secret.yaml
kubectl apply -f maria/mariadb-service.yaml
kubectl apply -f maria/mariadb-sts.yaml

###############################################################################
# 5. Deploy Redis
###############################################################################
echo -e "${GREEN}Deploying Redis...${NC}"
kubectl apply -f redis/redis-deployment.yaml
kubectl apply -f redis/redis-service.yaml

###############################################################################
# 6. Deploy the Flask app
###############################################################################
echo -e "${GREEN}Deploying Flask app...${NC}"
kubectl apply -f app/app-deployment.yaml
kubectl apply -f app/app-service.yaml

###############################################################################
# 7. Deploy Nginx
###############################################################################
echo -e "${GREEN}Deploying Nginx...${NC}"
kubectl apply -f nginx/nginx-cfgmap.yaml
kubectl apply -f nginx/nginx-secret-passwd.yaml
kubectl apply -f nginx/nginx-secret-tls.yaml
kubectl apply -f nginx/nginx-deployment.yaml
kubectl apply -f nginx/nginx-service.yaml

###############################################################################
# 8. Wait for pods to be ready
###############################################################################
echo -e "${GREEN}Waiting for pods to be ready (up to 2 minutes)...${NC}"
kubectl wait --for=condition=Available deployment -l app=flask-app -n app --timeout=120s
kubectl wait --for=condition=Available deployment -l app=nginx -n app --timeout=120s
kubectl wait --for=condition=Available deployment -l app=redis -n app --timeout=120s
kubectl wait --for=condition=Available statefulset -l app=mariadb -n app --timeout=120s

echo -e "${GREEN}All deployments are Available. Deployment complete!${NC}"

