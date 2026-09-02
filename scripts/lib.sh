# Shared configuration and helpers. Sourced by the other scripts, never run.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TF_DIR="$ROOT/terraform"
K8S_DIR="$ROOT/kubernetes"
ENV_FILE="$ROOT/.env"
MONGO_ENV_FILE="$K8S_DIR/mongodb.env"
TF_PLAN="tfplan.bin"

RESOURCE_GROUP="${RESOURCE_GROUP:-mpetitRG}"
LOCATION="${LOCATION:-francecentral}"
CLUSTER="${CLUSTER:-aks-azurefiles}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-mpazurefilesnfs}"
STORAGE_CLASS="${STORAGE_CLASS:-azurefile-csi-nfs}"
APP_NS="${APP_NS:-mongodb}"

info() { echo "$*"; }

# One line per step, so a chained target says what it is doing without adding
# any wait of its own. Colour only when the output is a terminal.
if [ -t 1 ]; then
  STEP_ON="$(printf '\033[1;36m')"
  STEP_OFF="$(printf '\033[0m')"
else
  STEP_ON=""
  STEP_OFF=""
fi

step() { echo "${STEP_ON}==> $*${STEP_OFF}"; }

done_msg() { echo "    $*"; }

die() {
  echo "Error: $*" >&2
  exit 1
}

usage() {
  echo "Usage: $(basename "$0") {$1}" >&2
  exit 1
}

require_command() {
  command -v "$1" > /dev/null || die "$1 not found."
}

require_env() {
  [ -f "$ENV_FILE" ] || die "missing .env. Run: make setup"
  # shellcheck disable=SC1090
  . "$ENV_FILE"
}

require_mongo_env() {
  [ -f "$MONGO_ENV_FILE" ] || die "missing $MONGO_ENV_FILE. Run: make mongo-env"
}
