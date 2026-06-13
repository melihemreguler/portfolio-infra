# portfolio-infra

Platform infrastructure for the portfolio web services, provisioned **from scratch with a single command** using Terraform + k3s on a Hetzner dedicated server.

This repo manages only the **cluster platform layer**. Application workloads
(`portfolio`, `turknet`, …) are deployed separately on top of it and are
intentionally **not** managed here.

## What gets provisioned

| Layer | Component | Version |
|-------|-----------|---------|
| Kubernetes | **k3s** (control-plane, single node) | `v1.33.5+k3s1` |
| Ingress / LB / DNS / Storage | Traefik, ServiceLB, CoreDNS, local-path-provisioner, metrics-server | bundled with k3s |
| Certificates | **cert-manager** | `v1.16.2` |
| ACME | `letsencrypt-prod` + `letsencrypt-staging` ClusterIssuers (HTTP-01 via Traefik) | — |
| Secrets | **encryption at rest** (`--secrets-encryption`, AES-CBC) | — |

Everything is **idempotent** — re-running is safe and only applies drift.

## Requirements

- Terraform >= 1.0
- SSH access to the server with your private key
- `kubectl` locally (optional, to use the fetched kubeconfig)

## Quick start

```bash
# 1. Set your server IP + ACME email (file is git-ignored)
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars

# 2. Provision everything
make up
```

`make up` runs `terraform init` + `apply`, which will:

1. SSH into the server and install/upgrade **k3s**.
2. Install **cert-manager** and wait for it to be ready.
3. Apply the **Let's Encrypt ClusterIssuers**.
4. Download a kubeconfig to `~/.kube/k3s-config` (pointed at the public IP).

Then verify:

```bash
make nodes        # KUBECONFIG=~/.kube/k3s-config kubectl get nodes
```

> Prefer raw Terraform? `terraform init && terraform apply` does the same thing.

## Configuration

Two inputs are **required** (set them in `terraform.tfvars`); the rest have
sensible defaults in [`variables.tf`](variables.tf). Override any default via
`terraform.tfvars` (git-ignored) or `-var` flags:

| Variable | Default | Notes |
|----------|---------|-------|
| `server_ip` | — **required** | Public server IP |
| `acme_email` | — **required** | Let's Encrypt registration |
| `ssh_user` | `root` | |
| `ssh_key_path` | `~/.ssh/hetzner-dedicated` | |
| `k3s_version` | `v1.33.5+k3s1` | empty = latest stable |
| `cert_manager_version` | `v1.16.2` | |
| `kubeconfig_path` | `~/.kube/k3s-config` | where the local kubeconfig is written |

## Layout

```
portfolio-infra/
├── Makefile                       # `make up` = one-command provision
├── versions.tf                    # Terraform + provider constraints
├── variables.tf                   # all inputs (with defaults)
├── main.tf                        # SSH provisioner orchestration
├── outputs.tf
└── scripts/
    ├── install-k3s.sh             # idempotent k3s install + firewall
    └── bootstrap-cluster.sh       # cert-manager + ClusterIssuers
```

## Deploying applications on top

Apps reference the issuer via an ingress annotation, e.g.:

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts: [app.example.com]
      secretName: example-tls
```

## Common operations

```bash
make plan         # preview changes
make destroy      # drop Terraform state (does NOT uninstall k3s)
make fmt          # terraform fmt
```

Fully wipe k3s from the server (irreversible — also removes running apps):

```bash
ssh -i <ssh_key_path> <ssh_user>@<server_ip> /usr/local/bin/k3s-uninstall.sh
```
