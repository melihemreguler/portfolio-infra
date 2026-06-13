.DEFAULT_GOAL := help
.PHONY: help up plan destroy kubeconfig nodes fmt

## up: Provision the whole platform from scratch (k3s + cert-manager + issuers)
up:
	terraform init -input=false
	terraform apply -auto-approve

## plan: Show what would change without applying
plan:
	terraform init -input=false
	terraform plan

## destroy: Remove Terraform state for the platform (does NOT uninstall k3s)
destroy:
	terraform destroy -auto-approve

## kubeconfig: Print the export line to use the fetched kubeconfig
kubeconfig:
	@echo 'export KUBECONFIG=$(HOME)/.kube/k3s-config'

## nodes: Verify the cluster is reachable
nodes:
	KUBECONFIG=$(HOME)/.kube/k3s-config kubectl get nodes -o wide

## fmt: Format Terraform files
fmt:
	terraform fmt -recursive

help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## //' | awk -F': ' '{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
