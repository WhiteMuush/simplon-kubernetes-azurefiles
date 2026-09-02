# Every recipe delegates to a script in scripts/. The configuration lives in
# scripts/lib.sh, so the scripts run on their own, without make. The Makefile
# only chains them: each target is a whole step of the lab, not a single call.

SCRIPTS := ./scripts

.DEFAULT_GOAL := help

.PHONY: help setup up verify status persistence destroy

help: ## Show this help
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@awk 'BEGIN { FS = ":.*##" } \
	    /^[a-zA-Z0-9_-]+ *:.*##/ { split($$1, t, " "); printf "  \033[36m%-12s\033[0m %s\n", t[1], $$2 }' $(MAKEFILE_LIST)
	@echo ""

setup: ## Create .env and the MongoDB password, once per clone
	@$(SCRIPTS)/setup-env.sh
	@$(SCRIPTS)/mongodb.sh mongo-env

# The StorageClass has to exist before the claim, or the PVC waits forever on a
# class that is not there and the rollout times out.
up: ## Build everything, from an empty subscription to MongoDB running
	@$(SCRIPTS)/infra.sh init
	@$(SCRIPTS)/infra.sh plan
	@$(SCRIPTS)/infra.sh apply
	@$(SCRIPTS)/cluster.sh kubeconfig
	@$(SCRIPTS)/cluster.sh storageclass
	@$(SCRIPTS)/mongodb.sh mongo-env
	@$(SCRIPTS)/mongodb.sh deploy

verify: ## Prove the driver runs, provisioning works and the mount is NFS
	@$(SCRIPTS)/cluster.sh csi-check
	@$(SCRIPTS)/cluster.sh test-pvc
	@$(SCRIPTS)/cluster.sh test-pvc-clean
	@$(SCRIPTS)/mongodb.sh mount-check

status: ## Show what the namespace holds, PVC and PV included
	@$(SCRIPTS)/mongodb.sh status

persistence: ## Write a document, kill the pod, read it back
	@$(SCRIPTS)/mongodb.sh persistence

destroy: ## Tear down every Azure resource
	@$(SCRIPTS)/infra.sh destroy
