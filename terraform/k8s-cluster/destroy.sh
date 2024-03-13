#!/bin/bash

# Change directory to keycloak
# cd /keycloak || exit 1
# terraform destroy --auto-approve

# Change directory to kube-prometheus-stack
cd kube-prometheus-stack || exit 1
terraform destroy --auto-approve

# Change directory to blackbox-exporter
cd ../blackbox-exporter || exit 1
terraform destroy --auto-approve

# Change directory to postgres-exporter
cd ../postgres-exporter || exit 1
terraform destroy --auto-approve

# Change directory to keycloack
cd ../keycloak || exit 1
terraform destroy --auto-approve

# Change directory to keycloack-config
cd ../keycloak-config || exit 1
terraform destroy --auto-approve

# Change directory to apps
cd ../apps || exit 1
terraform destroy --auto-approve

# Change directory to namespaces
cd ../namespaces || exit 1
terraform destroy --auto-approve

# Return to the original directory
cd ..

echo "All Terraform destroy commands executed successfully."
