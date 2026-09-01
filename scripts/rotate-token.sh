#!/usr/bin/env bash
# Rotate the GitLab token stored in .env.
set -euo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

CANDIDATE_FILE="$ENV_FILE.new"

# Without expires_at a rotated token lives one week, which turns into an outage
# nobody sees coming. One year is the ceiling on gitlab.com.
expiry_date() {
  date -d '+364 days' +%F
}

rotate() {
  curl -sf --request POST \
    --header "PRIVATE-TOKEN: $1" \
    "https://gitlab.com/api/v4/personal_access_tokens/self/rotate?expires_at=$2" \
    || die "rotation refused. The token needs the api or self_rotate scope."
}

token_from_response() {
  python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])'
}

# GitLab revokes the old value as soon as the call returns, so the new one is
# written aside and validated before it replaces .env.
write_candidate() {
  umask 077
  python3 - "$ENV_FILE" "$CANDIDATE_FILE" "$1" <<'PY'
import sys
src, dst, token = sys.argv[1], sys.argv[2], sys.argv[3]
lines = open(src).read().splitlines(keepends=True)
out = ["export TF_HTTP_PASSWORD=%s\n" % token if l.startswith("export TF_HTTP_PASSWORD=") else l
       for l in lines]
open(dst, "w").write("".join(out))
PY
  chmod 600 "$CANDIDATE_FILE"
}

promote_candidate() {
  curl -sf --header "PRIVATE-TOKEN: $1" https://gitlab.com/api/v4/user > /dev/null || {
    echo "The new token does not authenticate, and the old one is already revoked." >&2
    die "it is kept in $CANDIDATE_FILE, do not delete that file."
  }
  mv "$CANDIDATE_FILE" "$ENV_FILE"
}

main() {
  require_command curl
  require_env
  [ -n "${TF_HTTP_PASSWORD:-}" ] || die "TF_HTTP_PASSWORD is not set in .env"

  local expires new_token
  expires="$(expiry_date)"
  new_token="$(rotate "$TF_HTTP_PASSWORD" "$expires" | token_from_response)"

  write_candidate "$new_token"
  promote_candidate "$new_token"
  info "token rotated, valid until $expires."
}

main "$@"
