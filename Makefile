# Azure
RESOURCE_GROUP  := mpetitRG
LOCATION        := francecentral
CLUSTER         := aks-azurefiles
VNET            := vnet-azurefiles
SUBNET          := snet-aks
STORAGE_ACCOUNT := mpazurefilesnfs

# Kubernetes
APP_NS    := mongodb
STORAGE_CLASS := azurefile-csi-nfs

# Paths
TF_DIR   := terraform
K8S_DIR  := kubernetes
ENV      := ./.env
TF_PLAN  := tfplan.bin

MONGOSH := mongosh --quiet -u "$$MONGO_INITDB_ROOT_USERNAME" -p "$$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin

.PHONY: help setup rotate-token init plan apply destroy kubeconfig storageclass test-pvc test-pvc-clean csi-check \
	    deploy undeploy status mount-check insert read restart persistence

## help: list available targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## //'

# Environment

## setup: create .env from .env.example, asking for the GitLab token once
setup:
	@./scripts/setup-env.sh

## rotate-token: rotate the GitLab token and rewrite .env with the new value
rotate-token:
	@./scripts/rotate-token.sh

# Infrastructure (Terraform)

# Every recipe sources .env on the same line as the command: make runs each
# recipe line in its own subshell, so a source on a separate line would be
# lost before terraform ever runs.
$(ENV):
	@echo "Missing $(ENV). Run: make setup"
	@exit 1

## init: configure the GitLab remote state backend and install the providers
init: $(ENV)
	@. $(ENV) && terraform -chdir=$(TF_DIR) init

## plan: review the infrastructure changes, saved to tfplan.bin
plan: $(ENV)
	@. $(ENV) && terraform -chdir=$(TF_DIR) plan -out=$(TF_PLAN)

## apply: apply the reviewed plan (run make plan first)
apply: $(ENV)
	@. $(ENV) && terraform -chdir=$(TF_DIR) apply $(TF_PLAN)

## destroy: tear down every Azure resource
destroy: $(ENV)
	@. $(ENV) && terraform -chdir=$(TF_DIR) destroy

# Cluster

## kubeconfig: point kubectl at the AKS cluster
kubeconfig:
	az aks get-credentials --resource-group $(RESOURCE_GROUP) --name $(CLUSTER) --overwrite-existing

## storageclass: create the NFS StorageClass
storageclass:
	kubectl apply -f $(K8S_DIR)/storageclass.yaml

## test-pvc: provision a throwaway PVC to prove dynamic provisioning works
test-pvc:
	kubectl apply -f $(K8S_DIR)/test-pvc.yaml
	kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/nfs-test --timeout=180s
	kubectl get pvc nfs-test

## test-pvc-clean: remove the throwaway PVC and its share
test-pvc-clean:
	kubectl delete -f $(K8S_DIR)/test-pvc.yaml --ignore-not-found

## csi-check: confirm the Azure Files CSI driver runs on the cluster
csi-check:
	kubectl get pods -n kube-system -l app=csi-azurefile-node
	kubectl get storageclass $(STORAGE_CLASS)

# Application

## mongo-env: generate kubernetes/mongodb.env with a random password
mongo-env:
	@if [ -f $(K8S_DIR)/mongodb.env ]; then \
		echo "$(K8S_DIR)/mongodb.env already exists, leaving it alone."; \
	else \
		umask 077; \
		printf 'username=admin\npassword=%s\n' "$$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | cut -c1-24)" > $(K8S_DIR)/mongodb.env; \
		echo "wrote $(K8S_DIR)/mongodb.env"; \
	fi

$(K8S_DIR)/mongodb.env:
	@echo "Missing $@. Run: make mongo-env"
	@exit 1

## deploy: apply the MongoDB manifests through kustomize
deploy: $(K8S_DIR)/mongodb.env
	kubectl apply -k $(K8S_DIR)
	kubectl -n $(APP_NS) rollout status deployment/mongodb

## undeploy: remove the application, keeping the PVC and its data
undeploy:
	kubectl delete -k $(K8S_DIR) --ignore-not-found

## status: show what the namespace holds, PVC and PV included
status:
	kubectl -n $(APP_NS) get pods,svc,pvc
	kubectl get pv

## mount-check: prove the data directory is an NFS mount, not a local disk
mount-check:
	kubectl -n $(APP_NS) exec deploy/mongodb -- df -h -T /data/db

## insert: write a document, so persistence has something to prove
insert:
	kubectl -n $(APP_NS) exec deploy/mongodb -- sh -c '$(MONGOSH) --eval "db.getSiblingDB(\"lab\").proof.insertOne({written_at: new Date()})"'

## read: read back every document written by make insert
read:
	kubectl -n $(APP_NS) exec deploy/mongodb -- sh -c '$(MONGOSH) --eval "db.getSiblingDB(\"lab\").proof.find().toArray()"'

## restart: delete the pod and wait for its replacement
restart:
	kubectl -n $(APP_NS) delete pod -l app=mongodb
	kubectl -n $(APP_NS) rollout status deployment/mongodb

## persistence: the whole proof, insert then kill the pod then read again
persistence: insert restart read
