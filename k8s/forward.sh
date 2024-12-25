#!/bin/bash

# Define the processes to check and start
commands=(
  "kubectl port-forward --address 0.0.0.0 svc/nginx-service 443:443 -n app"
  "kubectl port-forward --address 0.0.0.0 svc/nginx-service 80:80 -n app"
)

# Check and start processes if not running
for cmd in "${commands[@]}"; do
  if ! pgrep -f "$cmd" > /dev/null; then
    nohup $cmd > /dev/null 2>&1 &
  fi
done

