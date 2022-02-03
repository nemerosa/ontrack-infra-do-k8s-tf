Ontrack Infra DO K8S Terraform
==============================

Installation of an Ontrack environment in a Digital Ocean Kubernetes cluster using Terraform.

# Usage

Clone this repository and create a `terraform.tfvars` file at the root of the working copy with the following values:

```hcl
# Digital Ocean token with read/write authorizations
# Create one by going to https://cloud.digitalocean.com/account/api/tokens
do_token       = "..."
# Unique name for the Ontrack instance inside its domain
name           = "..."
# Name of the DO cluster
do_k8s_cluster = "..."
```

Run the plan:

```bash
terraform plan -input=false -out=plan
```

Apply the plan:

```bash
terraform apply plan
```

After a few minutes, Ontrack will have been deployed in your Digital Ocean cluster and a managed Postgres database has
been created.

Assuming that you `kubectl` configuration points to the Digital Ocean cluster, you can access Ontrack by forwarding its
port locally:

```bash
kubectl port-forward -n ontrack-<name> service/ontrack-<name>-ontrack 8080:8080
```

where `<name>` is the value of the `name` variable in your `terraform.tfvars` file. You can then access Ontrack locally
using the default `admin` / `admin` credentials.

> There are also some options to create an ingress (see below).

To remove the whole setup (the Ontrack K8S resources and its managed database), run:

```bash
terraform destroy
```

# Ingress setup

By default, no ingress is setup for the Ontrack service. If your cluster is configured for ingress, you can use the
following variables to set it up:

* `do_ingress_enabled` - set to `true` to enable the ingress setup
* `do_ingress_domain` - set to a domain [managed](https://docs.digitalocean.com/products/networking/dns/) by Digital
  Ocean

After the deployment is finished, the Ontrack application will be accessible at `https://<name>.<do_ingress_domain>`.

See [`variables.tf`](variables.tf) for additional configuration options.

# Configuration variables

See [`variables.tf`](variables.tf) for the list of configuration variables, their types and their description.
