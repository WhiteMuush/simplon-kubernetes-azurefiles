#!/usr/bin/env bash
# Application side: MongoDB, its credentials, and the persistence proof.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Credentials never reach the manifests: kustomize reads them from this file,
# which stays out of git.
generate_credentials() {
  if [ -f "$MONGO_ENV_FILE" ]; then
    info "$MONGO_ENV_FILE already exists, leaving it alone."
    return 0
  fi
  require_command openssl
  umask 077
  printf 'username=admin\npassword=%s\n' \
    "$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | cut -c1-24)" > "$MONGO_ENV_FILE"
  info "wrote $MONGO_ENV_FILE"
}

# The credentials come from the container environment, so they never appear in
# a command line or in the shell history.
mongo_eval() {
  kubectl -n "$APP_NS" exec deploy/mongodb -- sh -c \
    "mongosh --quiet -u \"\$MONGO_INITDB_ROOT_USERNAME\" -p \"\$MONGO_INITDB_ROOT_PASSWORD\" --authenticationDatabase admin --eval '$1'"
}

deploy_app() {
  require_mongo_env
  kubectl apply -k "$K8S_DIR"
  kubectl -n "$APP_NS" rollout status deployment/mongodb
}

undeploy_app() {
  kubectl delete -k "$K8S_DIR" --ignore-not-found
}

show_status() {
  kubectl -n "$APP_NS" get pods,svc,pvc
  kubectl get pv
}

check_mount() {
  kubectl -n "$APP_NS" exec deploy/mongodb -- df -h -T /data/db
}

insert_document() {
  mongo_eval 'db.getSiblingDB("lab").proof.insertOne({written_at: new Date()})'
}

read_documents() {
  mongo_eval 'db.getSiblingDB("lab").proof.find().toArray()'
}

restart_pod() {
  kubectl -n "$APP_NS" delete pod -l app=mongodb
  kubectl -n "$APP_NS" rollout status deployment/mongodb
}

# The whole point of the lab: the document outlives the pod that wrote it.
prove_persistence() {
  insert_document
  restart_pod
  read_documents
}

main() {
  case "${1:-}" in
    mongo-env)   generate_credentials ;;
    deploy)      deploy_app ;;
    undeploy)    undeploy_app ;;
    status)      show_status ;;
    mount-check) check_mount ;;
    insert)      insert_document ;;
    read)        read_documents ;;
    restart)     restart_pod ;;
    persistence) prove_persistence ;;
    *)           usage "mongo-env|deploy|undeploy|status|mount-check|insert|read|restart|persistence" ;;
  esac
}

main "$@"
