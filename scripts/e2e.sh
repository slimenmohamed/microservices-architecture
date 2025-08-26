#!/usr/bin/env bash
set -euo pipefail
GATEWAY="${GATEWAY_URL:-http://localhost:8082}"

pass() { echo -e "\e[32m✔\e[0m $1"; }
fail() { echo -e "\e[31m✖\e[0m $1"; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "Missing dependency: $1"; }

need curl
need jq

# 1) Create sender and recipient users (unique emails to avoid 409 on reruns)
SUFFIX=$(date +%s)-$RANDOM
SENDER_EMAIL="alice-${SUFFIX}@example.com"
RECIPIENT_EMAIL="bob-${SUFFIX}@example.com"
sender=$(curl -fsS -H 'Content-Type: application/json' -d '{"name":"Alice","email":"'"$SENDER_EMAIL"'"}' "$GATEWAY/api/users") || fail "Create sender failed"
recipient=$(curl -fsS -H 'Content-Type: application/json' -d '{"name":"Bob","email":"'"$RECIPIENT_EMAIL"'"}' "$GATEWAY/api/users") || fail "Create recipient failed"
SENDER_ID=$(echo "$sender" | jq -r '.id')
RECIPIENT_ID=$(echo "$recipient" | jq -r '.id')
[[ "$SENDER_ID" != "null" && -n "$SENDER_ID" ]] || fail "Invalid sender id"
[[ "$RECIPIENT_ID" != "null" && -n "$RECIPIENT_ID" ]] || fail "Invalid recipient id"
pass "Created users: sender=$SENDER_ID recipient=$RECIPIENT_ID"

# 2) Send notification from sender to recipient via user-service endpoint
notif=$(curl -fsS -X POST -H 'Content-Type: application/json' -d '{"subject":"Hello","message":"Hi from Alice"}' "$GATEWAY/api/users/$RECIPIENT_ID/notify") || fail "Send notification failed"
NOTIF_ID=$(echo "$notif" | jq -r '.id')
[[ "$NOTIF_ID" != "null" && -n "$NOTIF_ID" ]] || fail "Invalid notification id"
pass "Notification created: id=$NOTIF_ID"

# 3) Verify notification exists via notification-service through gateway
found=$(curl -fsS "$GATEWAY/api/notifications/$NOTIF_ID") || fail "Fetch notification failed"
RID=$(echo "$found" | jq -r '.recipientId')
SUB=$(echo "$found" | jq -r '.subject')
MSG=$(echo "$found" | jq -r '.message')
[[ "$RID" = "$RECIPIENT_ID" ]] || fail "recipientId mismatch: expected $RECIPIENT_ID got $RID"
[[ "$SUB" = "Hello" ]] || fail "subject mismatch"
[[ "$MSG" = "Hi from Alice" ]] || fail "message mismatch"
pass "Notification verified with correct payload and recipient"

pass "E2E scenario passed"
