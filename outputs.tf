output "server_ip" {
  value       = var.server_ip
  description = "Public IP of the k3s control-plane node."
}

output "kubeconfig_path" {
  value       = var.kubeconfig_path
  description = "Local path to the fetched kubeconfig."
}

output "kubectl_command" {
  value       = "KUBECONFIG=${var.kubeconfig_path} kubectl get nodes"
  description = "Quick check that the cluster is reachable."
}
