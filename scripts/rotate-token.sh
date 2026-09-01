#!/usr/bin/env bash
# Rotate the GitLab token stored in .env. GitLab revokes the old value as soon
# as the call succeeds, so the new one is written to a temporary file, checked,
# and only then moved over .env.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/.env"
TMP_FILE="$ENV_FILE.new"

[ -f "$ENV_FILE" ] || { echo "No .env yet. Run: make setup" >&2; exit 1; }

# shellcheck disable=SC1090
. "$ENV_FILE"
[ -n "${TF_HTTP_PASSWORD:-}" ] || { echo "TF_HTTP_PASSWORD is not set in .env" >&2; exit 1; }

# Without expires_at the rotated token lives one week, which turns into a
# surprise outage. One year is the ceiling on gitlab.com.
EXPIRES="$(date -d '+364 days' +%F)"

RESPONSE="$(curl -sf --request POST \
  --header "PRIVATE-TOKEN: $TF_HTTP_PASSWORD" \
  "https://gitlab.com/api/v4/personal_access_tokens/self/rotate?expires_at=$EXPIRES")" \
  || { echo "Rotation refused. The token needs the api or self_rotate scope." >&2; exit 1; }

NEW_TOKEN="$(printf '%s' "$RESPONSE" | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])')"

umask 077
python3 - "$ENV_FILE" "$TMP_FILE" "$NEW_TOKEN" <<'PY'
import sys
src, dst, token = sys.argv[1], sys.argv[2], sys.argv[3]
lines = open(src).read().splitlines(keepends=True)
out = ["export TF_HTTP_PASSWORD=%s\n" % token if l.startswith("export TF_HTTP_PASSWORD=") else l
       for l in lines]
open(dst, "w").write("".join(out))
PY
chmod 600 "$TMP_FILE"

if ! curl -sf --header "PRIVATE-TOKEN: $NEW_TOKEN" https://gitlab.com/api/v4/user > /dev/null; then
  echo "The new token does not authenticate. The old one is already revoked." >&2
  echo "It is kept in $TMP_FILE, do not delete that file." >&2
  exit 1
fi

mv "$TMP_FILE" "$ENV_FILE"
echo "Token rotated, valid until $EXPIRES."
