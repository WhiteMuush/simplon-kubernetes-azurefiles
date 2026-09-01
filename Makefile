# Every recipe delegates to a script in scripts/. The configuration lives in
# scripts/lib.sh, so the scripts run on their own, without make.

SCRIPTS := ./scripts

.PHONY: help setup rotate-token init plan apply destroy kubeconfig csi-check \
	    storageclass test-pvc test-pvc-clean mongo-env deploy undeploy status \
	    mount-check insert read restart persistence

## help: list available targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## //'

# Environment

## setup: create .env, asking for the GitLab token once
setup:
	@$(SCRIPTS)/setup-env.sh

## rotate-token: rotate the GitLab token and rewrite .env
rotate-token:
	@$(SCRIPTS)/rotate-token.sh

# Infrastructure

## init: configure the GitLab remote state backend and install the providers
init:
	@$(SCRIPTS)/infra.sh init

## plan: review the infrastructure changes, saved to tfplan.bin
plan:
	@$(SCRIPTS)/infra.sh plan

## apply: apply the reviewed plan (run make plan first)
apply:
	@$(SCRIPTS)/infra.sh apply

## destroy: tear down every Azure resource
destroy:
	@$(SCRIPTS)/infra.sh destroy

# Cluster

## kubeconfig: point kubectl at the AKS cluster
kubeconfig:
	@$(SCRIPTS)/cluster.sh kubeconfig

## csi-check: confirm the Azure Files CSI driver runs on the cluster
csi-check:
	@$(SCRIPTS)/cluster.sh csi-check

## storageclass: create the NFS StorageClass
storageclass:
	@$(SCRIPTS)/cluster.sh storageclass

## test-pvc: provision a throwaway PVC to prove dynamic provisioning works
test-pvc:
	@$(SCRIPTS)/cluster.sh test-pvc

## test-pvc-clean: remove the throwaway PVC and its share
test-pvc-clean:
	@$(SCRIPTS)/cluster.sh test-pvc-clean

# Application

## mongo-env: generate kubernetes/mongodb.env with a random password
mongo-env:
	@$(SCRIPTS)/mongodb.sh mongo-env

## deploy: apply the MongoDB manifests through kustomize
deploy:
	@$(SCRIPTS)/mongodb.sh deploy

## undeploy: remove the application, keeping the PVC and its data
undeploy:
	@$(SCRIPTS)/mongodb.sh undeploy

## status: show what the namespace holds, PVC and PV included
status:
	@$(SCRIPTS)/mongodb.sh status

## mount-check: prove the data directory is an NFS mount, not a local disk
mount-check:
	@$(SCRIPTS)/mongodb.sh mount-check

## insert: write a document, so persistence has something to prove
insert:
	@$(SCRIPTS)/mongodb.sh insert

## read: read back every document written by make insert
read:
	@$(SCRIPTS)/mongodb.sh read

## restart: delete the pod and wait for its replacement
restart:
	@$(SCRIPTS)/mongodb.sh restart

## persistence: the whole proof, insert then kill the pod then read again
persistence:
	@$(SCRIPTS)/mongodb.sh persistence
