#!/usr/bin/env bash
set -euo pipefail
GATEWAY="${GATEWAY_URL:-http://localhost:8082}"

pass() { echo -e "\e[32m✔\e[0m $1"; }
fail() { echo -e "\e[31m✖\e[0m $1"; exit 1; }

# Health
curl -fsS "$GATEWAY/health" >/dev/null && pass "Gateway health ok" || fail "Gateway health failed"

# Users list
resp=$(curl -fsS "$GATEWAY/api/users") && echo "$resp" | jq . >/dev/null 2>&1 && pass "List users ok" || fail "List users failed"

# Docs
curl -fsS "$GATEWAY/users/docs" >/dev/null && pass "Users Swagger UI ok" || fail "Users docs failed"
curl -fsS "$GATEWAY/notifications/docs" >/dev/null && pass "Notifications Swagger UI ok" || fail "Notifications docs failed"

# Rate limit sample (expect at least one 429 when flooding)
if command -v parallel >/dev/null 2>&1; then
  codes=$(seq 1 30 | parallel -j 15 -n0 curl -s -o /dev/null -w "%{http_code}\n" "$GATEWAY/api/users" | sort | uniq -c)
  echo "$codes"
  echo "$codes" | grep -q 429 && pass "Rate limiting active" || echo "(No 429 observed in quick check)"
else
  echo "GNU parallel not installed; skipping rate limit check"
fi
