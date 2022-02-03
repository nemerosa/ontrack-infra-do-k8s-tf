# Required variables

variable "do_token" {
  type        = string
  sensitive   = true
  description = "Digital Ocean connection token"
}

variable "name" {
  type        = string
  description = "Name of the instance (must be unique in domain)"
}

variable "do_k8s_cluster" {
  type        = string
  description = "Name of the DO K8S Cluster where to deploy the application"
}

variable "ontrack_version" {
  type        = string
  description = "Version of Ontrack to install"
}

# Optional variables

variable "prefix" {
  type        = string
  description = "Prefix to add to the name when creating resources (database, etc.)"
  default     = "ontrack-"
}

variable "ontrack_chart_version" {
  type        = string
  description = "Chart version"
  default     = "0.1.10"
}

variable "do_database_size" {
  type        = string
  default     = "db-s-1vcpu-1gb"
  description = "Size of the Digital Ocean Postgres cluster"
}

variable "do_database_count" {
  type        = number
  default     = 1
  description = "Number of nodes in the Digital Ocean Postgres cluster"
}

variable "do_ingress_enabled" {
  type        = bool
  default     = false
  description = "Set to true to enable ingress"
}

variable "do_domain" {
  type        = string
  description = "Managed domain in Digital Ocean. Required if ingress is enabled."
  default     = "example.com"
}
