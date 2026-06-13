#!/usr/bin/env bash
# Installs the cluster-wide platform add-ons on top of k3s:
#   - cert-manager
#   - Let's Encrypt ClusterIssuers (prod + staging), HTTP-01 via Traefik
# Idempotent: everything is `kubectl apply`, safe to re-run.
#
# Env:
#   CERT_MANAGER_VERSION  e.g. v1.16.2 (required)
#   ACME_EMAIL            email for Let's Encrypt registration (required)
set -euo pipefail

: "${CERT_MANAGER_VERSION:?CERT_MANAGER_VERSION is required}"
: "${ACME_EMAIL:?ACME_EMAIL is required}"

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "==> Installing cert-manager ${CERT_MANAGER_VERSION}"
kubectl apply -f \
  "https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml"

echo "==> Waiting for cert-manager to be ready"
kubectl -n cert-manager rollout status deploy/cert-manager --timeout=180s
kubectl -n cert-manager rollout status deploy/cert-manager-webhook --timeout=180s
kubectl -n cert-manager rollout status deploy/cert-manager-cainjector --timeout=180s

echo "==> Applying Let's Encrypt ClusterIssuers (email: ${ACME_EMAIL})"
# The webhook can take a few seconds to accept connections after rollout.
for _ in $(seq 1 12); do
  if kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${ACME_EMAIL}
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: traefik
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: ${ACME_EMAIL}
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: traefik
EOF
  then
    break
  fi
  echo "    webhook not ready yet, retrying..."
  sleep 5
done

echo "==> Platform bootstrap complete"
kubectl get clusterissuer
