#!/usr/bin/env bash
# Cluster side: credentials, CSI driver, StorageClass and the test claim.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

fetch_kubeconfig() {
  az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER" --overwrite-existing
}

check_csi_driver() {
  kubectl get pods -n kube-system -l app=csi-azurefile-node
  kubectl get storageclass "$STORAGE_CLASS"
}

create_storage_class() {
  kubectl apply -f "$K8S_DIR/storageclass.yaml"
}

create_test_claim() {
  kubectl apply -f "$K8S_DIR/test-pvc.yaml"
  kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/nfs-test --timeout=300s
  kubectl get pvc nfs-test
}

delete_test_claim() {
  kubectl delete -f "$K8S_DIR/test-pvc.yaml" --ignore-not-found
}

main() {
  case "${1:-}" in
    kubeconfig)      require_command az; fetch_kubeconfig ;;
    csi-check)       check_csi_driver ;;
    storageclass)    create_storage_class ;;
    test-pvc)        create_test_claim ;;
    test-pvc-clean)  delete_test_claim ;;
    *)               usage "kubeconfig|csi-check|storageclass|test-pvc|test-pvc-clean" ;;
  esac
}

require_command kubectl
main "$@"
