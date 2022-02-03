Ontrack Infra DO K8S Terraform
==============================

Installation of an Ontrack environment in a Digital Ocean Kubernetes cluster using Terraform.

# Usage

Clone this repository and create a `terraform.tfvars` file at the root of the working copy with the following values:

```hcl
# Digital Ocean token with read/write authorizations
# Create one by going to https://cloud.digitalocean.com/account/api/tokens
do_token = "..."
# Unique name for the Ontrack instance inside its domain
name = "..."
# Name of the DO cluster
do_k8s_cluster = "..."
```

Run the plan:

```bash
terraform plan -input=false -out=plan
```

Apply the plan:

```bash
terraform apply -plan plan
```

After a few minutes, Ontrack will have been deployed in your Digital Ocean cluster and a managed Postgres database has been created.

Assuming that you `kubectl` configuration points to the Digital Ocean cluster, you can access Ontrack by forwarding its port locally:


There are also some options to create an ingress (see below).

To remove the whole setup (the Ontrack K8S resources and its managed database), run:

```bash
terraform destroy
```

# Ingress setup

# Configuration variables
