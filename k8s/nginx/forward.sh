kubectl port-forward --address 0.0.0.0 svc/nginx-service 443:443 -n app
kubectl port-forward --address 0.0.0.0 svc/nginx-service 80:80 -n app
