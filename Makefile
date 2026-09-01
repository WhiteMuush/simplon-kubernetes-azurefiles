# Every recipe delegates to a script in scripts/. The configuration lives in
# scripts/lib.sh, so the scripts run on their own, without make.

SCRIPTS := ./scripts

.DEFAULT_GOAL := help

.PHONY: help setup rotate-token init plan apply destroy kubeconfig csi-check \
	    storageclass test-pvc test-pvc-clean mongo-env deploy undeploy status \
	    mount-check insert read restart persistence

help: ## Show this help
	@echo ""
	@echo "Usage: make <target>"
	@awk 'BEGIN { FS = ":.*##" } \
	    /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5); next } \
	    /^[a-zA-Z0-9_-]+ *:.*##/ { split($$1, t, " "); printf "  \033[36m%-16s\033[0m %s\n", t[1], $$2 }' $(MAKEFILE_LIST)
	@echo ""

##@ Environment

setup: ## Create .env, asking for the GitLab token once
	@$(SCRIPTS)/setup-env.sh

rotate-token: ## Rotate the GitLab token and rewrite .env
	@$(SCRIPTS)/rotate-token.sh

##@ Infrastructure

init: ## Configure the GitLab remote state backend and install the providers
	@$(SCRIPTS)/infra.sh init

plan: ## Review the infrastructure changes, saved to tfplan.bin
	@$(SCRIPTS)/infra.sh plan

apply: ## Apply the reviewed plan (run make plan first)
	@$(SCRIPTS)/infra.sh apply

destroy: ## Tear down every Azure resource
	@$(SCRIPTS)/infra.sh destroy

##@ Cluster

kubeconfig: ## Point kubectl at the AKS cluster
	@$(SCRIPTS)/cluster.sh kubeconfig

csi-check: ## Confirm the Azure Files CSI driver runs on the cluster
	@$(SCRIPTS)/cluster.sh csi-check

storageclass: ## Create the NFS StorageClass
	@$(SCRIPTS)/cluster.sh storageclass

test-pvc: ## Provision a throwaway PVC to prove dynamic provisioning works
	@$(SCRIPTS)/cluster.sh test-pvc

test-pvc-clean: ## Remove the throwaway PVC and its share
	@$(SCRIPTS)/cluster.sh test-pvc-clean

##@ Application

mongo-env: ## Generate kubernetes/mongodb.env with a random password
	@$(SCRIPTS)/mongodb.sh mongo-env

deploy: ## Apply the MongoDB manifests through kustomize
	@$(SCRIPTS)/mongodb.sh deploy

undeploy: ## Remove the application, keeping the PVC and its data
	@$(SCRIPTS)/mongodb.sh undeploy

status: ## Show what the namespace holds, PVC and PV included
	@$(SCRIPTS)/mongodb.sh status

mount-check: ## Prove the data directory is an NFS mount, not a local disk
	@$(SCRIPTS)/mongodb.sh mount-check

insert: ## Write a document, so persistence has something to prove
	@$(SCRIPTS)/mongodb.sh insert

read: ## Read back every document written by make insert
	@$(SCRIPTS)/mongodb.sh read

restart: ## Delete the pod and wait for its replacement
	@$(SCRIPTS)/mongodb.sh restart

persistence: ## The whole proof, insert then kill the pod then read again
	@$(SCRIPTS)/mongodb.sh persistence
