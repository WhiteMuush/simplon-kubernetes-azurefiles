#!/usr/bin/env bash
# Terraform side: the Azure resources of the lab.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

terraform_init() {
  step "Terraform init: remote state and providers"
  terraform -chdir="$TF_DIR" init
}

terraform_plan() {
  step "Terraform plan: what would change in Azure, saved to $TF_PLAN"
  terraform -chdir="$TF_DIR" plan -out="$TF_PLAN"
}

terraform_apply() {
  step "Terraform apply: creating the storage account, network and cluster"
  terraform -chdir="$TF_DIR" apply "$TF_PLAN"
}

terraform_destroy() {
  step "Terraform destroy: removing every Azure resource of the lab"
  terraform -chdir="$TF_DIR" destroy
}

main() {
  require_command terraform
  require_env

  case "${1:-}" in
    init)    terraform_init ;;
    plan)    terraform_plan ;;
    apply)   terraform_apply ;;
    destroy) terraform_destroy ;;
    *)       usage "init|plan|apply|destroy" ;;
  esac
}

main "$@"
