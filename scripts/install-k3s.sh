#!/usr/bin/env bash
# Installs / upgrades k3s on the server. Idempotent: re-running is a no-op
# (or an in-place upgrade if INSTALL_K3S_VERSION changed).
#
# Env:
#   INSTALL_K3S_VERSION  k3s version to pin, e.g. v1.33.5+k3s1 (optional)
set -euo pipefail

echo "==> Installing base packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl ca-certificates >/dev/null

echo "==> Installing k3s (${INSTALL_K3S_VERSION:-latest stable})"
# k3s ships Traefik (ingress), ServiceLB, local-path-provisioner, CoreDNS and
# metrics-server by default -- exactly the platform we rely on. The official
# installer is idempotent, so this is safe to run on an existing node.
curl -sfL https://get.k3s.io \
  | INSTALL_K3S_VERSION="${INSTALL_K3S_VERSION:-}" \
    INSTALL_K3S_EXEC="server --write-kubeconfig-mode=644" \
    sh -

echo "==> Ensuring k3s service is enabled and running"
systemctl enable --now k3s

echo "==> Waiting for the node to become Ready"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
for _ in $(seq 1 30); do
  if kubectl get nodes 2>/dev/null | grep -q ' Ready'; then
    break
  fi
  sleep 5
done
kubectl wait --for=condition=Ready node --all --timeout=120s

# Open the ports we serve on, only if UFW is active.
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  echo "==> Configuring UFW (6443/80/443)"
  ufw allow 6443/tcp  # Kubernetes API
  ufw allow 80/tcp    # HTTP  (ACME http-01 + redirect)
  ufw allow 443/tcp   # HTTPS
fi

echo "==> k3s ready"
kubectl get nodes -o wide
