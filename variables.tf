# Connection to the Hetzner dedicated server.
# `server_ip` and `acme_email` are required -- copy terraform.tfvars.example to
# terraform.tfvars and fill them in. Everything else has a sensible default.

variable "server_ip" {
  type        = string
  description = "Public IP of the Hetzner server that hosts the k3s cluster."
  # No default: set this in terraform.tfvars (see terraform.tfvars.example).
}

variable "ssh_user" {
  type        = string
  description = "SSH user used to provision the server."
  default     = "root"
}

variable "ssh_key_path" {
  type        = string
  description = "Path to the private SSH key used to reach the server."
  default     = "~/.ssh/hetzner-dedicated"
}

# --- Cluster platform versions -------------------------------------------------

variable "k3s_version" {
  type        = string
  description = "k3s version to install (INSTALL_K3S_VERSION). Empty = latest stable channel."
  default     = "v1.33.5+k3s1"
}

variable "cert_manager_version" {
  type        = string
  description = "cert-manager release to install via the upstream static manifest."
  default     = "v1.16.2"
}

# --- Let's Encrypt -------------------------------------------------------------

variable "acme_email" {
  type        = string
  description = "Email registered with Let's Encrypt for the ClusterIssuers."
  # No default: set this in terraform.tfvars (see terraform.tfvars.example).
}

# --- Local kubeconfig ----------------------------------------------------------

variable "kubeconfig_path" {
  type        = string
  description = "Where to write the fetched kubeconfig on the machine running Terraform."
  default     = "~/.kube/k3s-config"
}
