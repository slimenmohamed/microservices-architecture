#!/usr/bin/env bash
set -euo pipefail
GATEWAY="${GATEWAY_URL:-http://localhost:8082}"

pass() { echo -e "\e[32m✔\e[0m $1"; }
fail() { echo -e "\e[31m✖\e[0m $1"; exit 1; }

# Retry helper: curl with retries
curl_retry() {
  local url="$1"; shift
  local max=${CURL_MAX_RETRIES:-20}
  local delay=${CURL_RETRY_DELAY_SECS:-2}
  local i=1
  while true; do
    if out=$(curl -sS -w "\n%{http_code}" "$url" "$@" 2>&1); then
      body="$(echo "$out" | sed '$d')"
      code="$(echo "$out" | tail -n1)"
      if [[ "$code" =~ ^2..$ ]]; then
        echo "$body"
        return 0
      fi
    else
      body="$out"; code=""
    fi
    if (( i >= max )); then
      echo "[curl_retry] Failed after $i attempts: $url" >&2
      echo "[curl_retry] Last HTTP code: ${code:-n/a}" >&2
      echo "[curl_retry] Last output:" >&2
      echo "$body" >&2
      return 1
    fi
    sleep "$delay"; i=$((i+1))
  done
}

# Health (retry until gateway is responding 200)
curl_retry "$GATEWAY/health" >/dev/null && pass "Gateway health ok" || fail "Gateway health failed"

# Users list
if resp=$(curl_retry "$GATEWAY/api/users"); then
  echo "$resp" | jq . >/dev/null 2>&1 && pass "List users ok" || { echo "$resp"; fail "List users failed (invalid JSON)"; }
else
  fail "List users failed"
fi

# Docs via gateway (use /api prefixes to route to services)
curl -fsS "$GATEWAY/api/users/docs" >/dev/null && pass "Users Swagger UI ok" || fail "Users docs failed"
curl -fsS "$GATEWAY/api/notifications/docs" >/dev/null && pass "Notifications Swagger UI ok" || fail "Notifications docs failed"

# Rate limit sample (expect at least one 429 when flooding)
if command -v parallel >/dev/null 2>&1; then
  codes=$(seq 1 30 | parallel -j 15 -n0 curl -s -o /dev/null -w "%{http_code}\n" "$GATEWAY/api/users" | sort | uniq -c)
  echo "$codes"
  echo "$codes" | grep -q 429 && pass "Rate limiting active" || echo "(No 429 observed in quick check)"
else
  echo "GNU parallel not installed; skipping rate limit check"
fi
