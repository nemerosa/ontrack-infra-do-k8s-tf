terraform {
  required_version = "~> 1.1.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.17.1"
    }
    helm         = {
      version = "~> 2.4.1"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

// =======================================================================================
// The target K8S cluster
// =======================================================================================

data "digitalocean_kubernetes_cluster" "cluster" {
  name = var.do_k8s_cluster
}

provider "helm" {
  kubernetes {
    host                   = data.digitalocean_kubernetes_cluster.cluster.endpoint
    token                  = data.digitalocean_kubernetes_cluster.cluster.kube_config[0].token
    cluster_ca_certificate = base64decode( data.digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate )
  }
}

// =======================================================================================
// The project
// =======================================================================================

locals {
  do_prefix = "${var.prefix}${var.name}"
}

// =======================================================================================
// Database
// =======================================================================================

resource "digitalocean_database_cluster" "db" {
  name                 = "${local.do_prefix}-database"
  engine               = "pg"
  version              = "11"
  size                 = var.do_database_size
  node_count           = var.do_database_count
  // Same VPC & region than than the K8S cluster
  region               = data.digitalocean_kubernetes_cluster.cluster.region
  private_network_uuid = data.digitalocean_kubernetes_cluster.cluster.vpc_uuid
}

// =======================================================================================
// New Ontrack user for the database
// =======================================================================================

resource "digitalocean_database_user" "db-user" {
  cluster_id = digitalocean_database_cluster.db.id
  name       = "ontrack"
}

// =======================================================================================
// New Ontrack database
// =======================================================================================

resource "digitalocean_database_db" "db-ontrack" {
  cluster_id = digitalocean_database_cluster.db.id
  name       = "ontrack"
}

// =======================================================================================
// TODO Database firewall, must be accessed only from the cluster
// =======================================================================================

#resource "digitalocean_database_firewall" "db-firewall" {
#  cluster_id = digitalocean_database_cluster.db.id
#  rule {
#    type  = "droplet"
#    value = digitalocean_droplet.instance.id
#  }
#}

// =======================================================================================
// Helm setup
// =======================================================================================

locals {
  db_url = "jdbc:postgresql://${digitalocean_database_cluster.db.private_host}:${digitalocean_database_cluster.db.port}/${digitalocean_database_db.db-ontrack.name}?sslmode=require"

  helm_values = templatefile( "${path.module}/values.yaml", {
    host = "${var.name}.${var.do_domain}",
  } )
}

resource "helm_release" "ontrack" {
  name       = "${local.do_prefix}-ontrack"
  repository = "https://nemerosa.github.io/ontrack-chart"
  chart      = "ontrack"
  version    = var.ontrack_chart_version

  depends_on = [
    digitalocean_database_cluster.db,
    digitalocean_database_db.db-ontrack,
    digitalocean_database_user.db-user,
  ]

  namespace        = local.do_prefix
  create_namespace = true

  # Previous values must be reused
  reuse_values = true

  # 10 minutes
  timeout = 600

  # Values

  values = [
    local.helm_values,
  ]

  # Ontrack version

  set {
    name  = "image.tag"
    value = var.ontrack_version
  }

  # Using the managed database

  set {
    name  = "postgresql.local"
    value = "false"
  }

  set_sensitive {
    name  = "postgresql.postgresqlUsername"
    value = digitalocean_database_user.db-user.name
  }

  set_sensitive {
    name  = "postgresql.postgresqlPassword"
    value = digitalocean_database_user.db-user.password
  }

  set {
    name  = "postgresql.postgresqlUrl"
    value = local.db_url
  }

}

// =======================================================================================
// Mapping DNS ~~> Cluster load balancer
// =======================================================================================

data "digitalocean_loadbalancer" "cluster_lb" {
  count = var.do_ingress_enabled ? 1 : 0
  # Name = Cluster name (convention)
  name  = var.do_k8s_cluster
}

resource "digitalocean_record" "cluster_lb_record" {
  count  = var.do_ingress_enabled ? 1 : 0
  domain = var.do_domain
  type   = "A"
  name   = var.name
  value  = data.digitalocean_loadbalancer.cluster_lb.ip
}
