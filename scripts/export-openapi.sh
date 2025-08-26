#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
DOCS_DIR="$ROOT_DIR/docs"
GATEWAY="${GATEWAY_URL:-http://localhost:8082}"

mkdir -p "$DOCS_DIR"

echo "Exporting OpenAPI specs from gateway: $GATEWAY"

# user-service (Symfony via gateway)
if curl -fsS "$GATEWAY/users/docs.json" -o "$DOCS_DIR/user-service.openapi.json"; then
  echo "✔ Saved user-service OpenAPI to docs/user-service.openapi.json"
else
  echo "! Could not fetch $GATEWAY/users/docs.json" >&2
  echo "  Make sure the user-service docs JSON endpoint is enabled and reachable via the gateway." >&2
  exit 1
fi

# notification-service (Node via gateway)
if curl -fsS "$GATEWAY/notifications/docs.json" -o "$DOCS_DIR/notification-service.openapi.json"; then
  echo "✔ Saved notification-service OpenAPI to docs/notification-service.openapi.json"
else
  echo "! Could not fetch $GATEWAY/notifications/docs.json" >&2
  exit 1
fi

echo "Done. Files in $DOCS_DIR:" && ls -1 "$DOCS_DIR"
