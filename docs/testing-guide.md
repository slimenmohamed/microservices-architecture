# Complete Microservices Testing Guide

This guide helps you thoroughly test the architecture: services, gateway, databases, RabbitMQ, CI, Postman, performance, failure recovery, and documentation.

Key references:
- `Makefile`
- `infra/docker-compose.yml`
- `infra/nginx/conf.d/default.conf.template` → renders to `infra/nginx/conf.d/default.conf`
- `scripts/smoke.sh`, `scripts/e2e.sh`, `scripts/export-openapi.sh`, `scripts/render-diagrams.sh`
- `.github/workflows/ci.yml` (includes Postman newman run + JSON artifact)
- `docs/postman/collection.json`, `docs/postman/environment.json`
- `docs/*.openapi.json`, `docs/*.mmd`, `docs/*.svg`

Tip for logs: any follow/stream hangs by design. Press Ctrl-C to exit (e.g., `make logs`, `make logs-gw`, `docker compose logs -f`).

---

## Phase 1: Initial Setup & Basic Health

### 1.1 Prerequisites
```bash
docker --version
docker compose version
make --version
git --version
node --version    # optional local use
php --version     # optional local use
```

### 1.2 Clone and start
```bash
git clone https://github.com/slimenmohamed/microservices-architecture.git
cd microservices-architecture
```

### 1.3 Gateway config templating (recommended; aligns with CI)
```bash
GW_RATE_LIMIT=100r/s GW_BURST=200 make gw-build-conf
# Renders: infra/nginx/conf.d/default.conf
```

### 1.4 Bring up and check
```bash
make up
make ps
curl http://localhost:8082/health    # {"status":"ok"}
docker ps  # gateway, user-service, notification-service, notification-worker, user-db, notif-db, rabbitmq
```

---

## Phase 2: Service-Level Testing

### 2.1 API Gateway
```bash
curl -i http://localhost:8082/health
# CORS probe
curl -i -H "Origin: http://example.com" http://localhost:8082/health
# Rate limit sampling (counts per code)
for i in {1..150}; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8082/api/users; done | sort | uniq -c
```

### 2.2 User Service (Direct & via Gateway)
```bash
# Direct (debugging)
curl http://localhost:8080/ready
curl http://localhost:8080/health

# Via Gateway
curl http://localhost:8082/api/users
curl http://localhost:8082/api/v1/users

# Create
curl -X POST http://localhost:8082/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john-'"$(date +%s)"'@example.com"}'

# Get by id
curl http://localhost:8082/api/users/{id}

# Update
curl -X PUT http://localhost:8082/api/users/{id} \
  -H "Content-Type: application/json" \
  -d '{"name":"John Updated","email":"john.updated@example.com"}'

# Delete
curl -X DELETE http://localhost:8082/api/users/{id}
```

### 2.3 Notification Service (Direct & via Gateway)
```bash
# Direct (debugging)
curl http://localhost:8081/ready
curl http://localhost:8081/health

# Via Gateway
curl http://localhost:8082/api/notifications
curl http://localhost:8082/api/v1/notifications

# Create directly (only if exposed; check Swagger first)
curl -X POST http://localhost:8082/api/notifications \
  -H "Content-Type: application/json" \
  -d '{"userId":"test-user","message":"Test notification","type":"info"}'

# Filter by user
curl "http://localhost:8082/api/notifications?userId=test-user"
```

### 2.4 Swagger/OpenAPI via Gateway
```bash
# Users docs
curl -I http://localhost:8082/api/users/docs
# Notifications docs
curl -I http://localhost:8082/api/notifications/docs
```

---

## Phase 3: Integration Tests

### 3.1 Smoke Tests
```bash
make smoke            # or: bash scripts/smoke.sh
GATEWAY_URL=http://localhost:8082 make smoke
```

### 3.2 E2E Tests
```bash
make e2e              # or: bash scripts/e2e.sh
GATEWAY_URL=http://localhost:8082 make e2e
# Creates sender/recipient users, sends notify, verifies notification
```

### 3.3 Async Message Flow (manual)
```bash
USER_RESPONSE=$(curl -s -X POST http://localhost:8082/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Event Test","email":"event-'"$(date +%s)"'@test.com"}')
USER_ID=$(echo "$USER_RESPONSE" | jq -r '.id')

sleep 3  # allow worker consume

curl "http://localhost:8082/api/notifications?userId=$USER_ID" | jq .
```

---

## Phase 4: Databases

### 4.1 User DB (migrations and queries)
```bash
make status
make migrate

docker compose -f infra/docker-compose.yml exec user-db \
  mysql -usymfony -psymfony -e "SHOW TABLES;" userdb

docker compose -f infra/docker-compose.yml exec user-db \
  mysql -usymfony -psymfony -e "SELECT * FROM users;" userdb

# Backup example (writes on host shell)
docker compose -f infra/docker-compose.yml exec user-db \
  mysqldump -usymfony -psymfony userdb > userdb_backup.sql
```

### 4.2 Notification DB
```bash
docker compose -f infra/docker-compose.yml exec notif-db \
  mysql -unode -pnode -e "SHOW TABLES;" notifdb

docker compose -f infra/docker-compose.yml exec notif-db \
  mysql -unode -pnode -e "SELECT * FROM notifications;" notifdb
```

---

## Phase 5: RabbitMQ

- Management UI: http://localhost:15672 (guest/guest)
- CLI checks
```bash
docker compose -f infra/docker-compose.yml exec rabbitmq \
  rabbitmqctl list_queues name messages_ready messages_unacknowledged

docker compose -f infra/docker-compose.yml exec rabbitmq \
  rabbitmqctl list_exchanges name type

watch -n 1 'docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_queues name messages_ready'
```

---

## Phase 6: Observability

### 6.1 Correlation ID tracing
```bash
CID=$(uuidgen)
# Try X-Correlation-Id
curl -H "X-Correlation-Id: $CID" http://localhost:8082/api/users
# Or X-Correlation-ID
curl -H "X-Correlation-ID: $CID" http://localhost:8082/api/users

# Search logs
docker compose -f infra/docker-compose.yml logs gateway | grep "$CID"
docker compose -f infra/docker-compose.yml logs user-service | grep "$CID"
```

### 6.2 Logs
```bash
make logs          # follow all; Ctrl-C to exit
make logs-gw       # gateway only; Ctrl-C to exit
make logs-user     # user-service only; Ctrl-C to exit
make logs-notif    # notification-service only; Ctrl-C to exit

# Not following; print last N lines
docker compose -f infra/docker-compose.yml logs --tail=200
docker compose -f infra/docker-compose.yml logs --tail=100 gateway

# Look for errors
docker compose -f infra/docker-compose.yml logs | grep -i error
```

---

## Phase 7: Performance & Load

### 7.1 Rate limiting sampling
```bash
# Requires GNU parallel for high concurrency
seq 200 | parallel -j 50 "curl -s -o /dev/null -w '%{http_code}' http://localhost:8082/api/users" | sort | uniq -c
```

### 7.2 Change limits and retest
```bash
export GW_RATE_LIMIT=20r/s
export GW_BURST=40
make gw-build-conf
make restart-gw
for i in {1..50}; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8082/api/users; done | sort | uniq -c
```

### 7.3 Scaling (important limitation)
Current `infra/docker-compose.yml` uses fixed `container_name` for `user-service` and `notification-service`. Docker cannot scale such services. To test scaling, remove those `container_name` entries (or use a compose override without them), then:
```bash
docker compose -f infra/docker-compose.yml up -d --scale user-service=3
docker ps | grep user-service
```

---

## Phase 8: Failure & Recovery

### 8.1 Stop/restart user-service
```bash
docker compose -f infra/docker-compose.yml stop user-service
curl -i http://localhost:8082/api/users   # expect 502

docker compose -f infra/docker-compose.yml start user-service
sleep 10
curl http://localhost:8082/api/users
```

### 8.2 Stop/restart DB
```bash
docker compose -f infra/docker-compose.yml stop user-db
curl -i http://localhost:8082/api/users
make logs-user            # check DB errors

docker compose -f infra/docker-compose.yml start user-db
sleep 10
curl http://localhost:8082/api/users
```

### 8.3 Stop/restart RabbitMQ
```bash
docker compose -f infra/docker-compose.yml stop rabbitmq

curl -X POST http://localhost:8082/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Queue Test","email":"queue-'"$(date +%s)"'@test.com"}'

docker compose -f infra/docker-compose.yml logs notification-worker

docker compose -f infra/docker-compose.yml start rabbitmq
sleep 10
docker compose -f infra/docker-compose.yml logs notification-worker
```

---

## Phase 9: API Documentation

### 9.1 Export & validate OpenAPI
```bash
make export-openapi
ls -la docs/*.openapi.json
jq . docs/user-service.openapi.json > /dev/null && echo "User API spec valid"
jq . docs/notification-service.openapi.json > /dev/null && echo "Notification API spec valid"
```

### 9.2 Postman testing
```bash
# Postman app: import docs/postman/collection.json & environment.json, set GATEWAY_URL=http://localhost:8082

# Newman (installed)
newman run docs/postman/collection.json \
  -e docs/postman/environment.json \
  --env-var "GATEWAY_URL=http://localhost:8082"

# Dockerized newman (no local install)
docker run --rm --network host \
  -v "$PWD/docs":/etc/newman -w /etc/newman \
  postman/newman \
  run postman/collection.json \
  -e postman/environment.json \
  --env-var "GATEWAY_URL=http://localhost:8082"
```

---

## Phase 10: Clean Restart

### 10.1 Full teardown and fresh start
```bash
make down
docker ps -a | grep microservices || true
docker volume ls | grep microservices || true

make up
make smoke
make e2e
```

### 10.2 Restarts
```bash
make restart-gw
make restart-user
make restart-notif
make restart-all
curl http://localhost:8082/health
```

---

## Phase 11: CI/CD (GitHub Actions)

### 11.1 Trigger CI
```bash
git push
```

### 11.2 What CI does (`.github/workflows/ci.yml`)
- Build gateway config (templating with rate limits)
- docker compose up
- connectivity probe
- gw-config-test
- migrations
- smoke
- e2e
- Postman newman run (against http://localhost:8082)
  - Produces `newman-report.json`
  - Uploads artifact `postman-newman-report`
- export-openapi (uploads artifacts)
- down

### 11.3 Inspect CI
- Actions → latest run → expand steps for logs
- Artifacts:
  - `openapi-specs` (exported specs)
  - `postman-newman-report` (JSON run report)

---

## Manual Scenario to run after `make e2e` (Primary Focus)
```bash
SUFFIX=$(date +%s)-$RANDOM
SENDER_EMAIL="alice-${SUFFIX}@example.com"
RECIPIENT_EMAIL="bob-${SUFFIX}@example.com"

SENDER=$(curl -fsS -H 'Content-Type: application/json' \
  -d '{"name":"Alice","email":"'"$SENDER_EMAIL"'"}' \
  http://localhost:8082/api/users)

RECIPIENT=$(curl -fsS -H 'Content-Type: application/json' \
  -d '{"name":"Bob","email":"'"$RECIPIENT_EMAIL"'"}' \
  http://localhost:8082/api/users)

SID=$(echo "$SENDER" | jq -r '.id')
RID=$(echo "$RECIPIENT" | jq -r '.id')
echo "sender=$SID recipient=$RID"

NOTIF=$(curl -fsS -X POST -H 'Content-Type: application/json' \
  -d '{"subject":"Hello","message":"Hi from Alice"}' \
  http://localhost:8082/api/users/$RID/notify)
NID=$(echo "$NOTIF" | jq -r '.id')
echo "notif=$NID"

curl -fsS http://localhost:8082/api/notifications/$NID | jq .
```

Optional: watch worker logs during scenario (Ctrl-C to exit)
```bash
docker compose -f infra/docker-compose.yml logs -f notification-worker
```

---

## Troubleshooting Quick Reference

- Ports busy: free 8080/8081/8082/3307/3308/5672/15672 or adjust mappings in `infra/docker-compose.yml`.
- Gateway 502: `make restart-gw`, check `/health`, `make logs-gw`.
- Unhealthy services: `make logs`, check DB readiness and env.
- MySQL auth/availability: examine `infra/docker-compose.yml` and service logs.
- OpenAPI stale: `make export-openapi`.
- Scaling fails: due to `container_name`. Remove from services (or use an override) to enable scaling.
- Log tails: press Ctrl-C to exit.
