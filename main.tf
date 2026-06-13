# Provisions the *platform* layer of the cluster on a fresh Hetzner server:
#   1. k3s (control-plane + bundled Traefik / ServiceLB / local-path / CoreDNS)
#   2. cert-manager
#   3. Let's Encrypt ClusterIssuers (prod + staging)
#
# Application workloads (portfolio, turknet, ...) are intentionally NOT managed
# here -- they live in their own repos / manifests and are deployed on top of
# this base. Everything below is idempotent and safe to re-run.

locals {
  ssh_key = pathexpand(var.ssh_key_path)
}

resource "null_resource" "cluster" {
  # Re-run provisioning whenever the bootstrap inputs change.
  triggers = {
    k3s_version          = var.k3s_version
    cert_manager_version = var.cert_manager_version
    acme_email           = var.acme_email
    install_script       = filesha256("${path.module}/scripts/install-k3s.sh")
    bootstrap_script     = filesha256("${path.module}/scripts/bootstrap-cluster.sh")
  }

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.ssh_user
    private_key = file(local.ssh_key)
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install-k3s.sh"
    destination = "/tmp/install-k3s.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/bootstrap-cluster.sh"
    destination = "/tmp/bootstrap-cluster.sh"
  }

  # 1) k3s, 2) cert-manager + ClusterIssuers
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-k3s.sh /tmp/bootstrap-cluster.sh",
      "INSTALL_K3S_VERSION='${var.k3s_version}' /tmp/install-k3s.sh",
      "CERT_MANAGER_VERSION='${var.cert_manager_version}' ACME_EMAIL='${var.acme_email}' /tmp/bootstrap-cluster.sh",
    ]
  }

  # Fetch a kubeconfig pointed at the public IP so kubectl works from anywhere.
  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p "$(dirname ${pathexpand(var.kubeconfig_path)})"
      ssh -i ${local.ssh_key} -o StrictHostKeyChecking=no ${var.ssh_user}@${var.server_ip} \
        'cat /etc/rancher/k3s/k3s.yaml' \
        | sed 's/127.0.0.1/${var.server_ip}/g' > ${pathexpand(var.kubeconfig_path)}
      chmod 600 ${pathexpand(var.kubeconfig_path)}
    EOT
  }
}
