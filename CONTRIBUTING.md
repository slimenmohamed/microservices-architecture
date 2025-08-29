# Contributing Guide

Welcome to the **Microservices Architecture Project**! 🎉

This guide is your **developer handbook**: setup, workflows, commands, coding standards, and troubleshooting.

---

## 📑 Table of Contents

- [🧰 Tech Stack Overview](#tech-stack-overview)
- [📚 API Docs & Postman](#api-docs--postman)
- [🩺 Health & Readiness](#health--readiness)
- [✅ Testing Overview](#testing-overview)
- [🔎 Observability & Limits](#observability--limits)
- [🧭 Dev vs Prod Modes](#dev-vs-prod-modes)
- [📋 Prerequisites](#prerequisites)
- [⚙️ Environment Setup](#environment-setup)
- [💻 Daily Development Workflow](#daily-development-workflow)
- [📖 Command Reference](#command-reference)
- [📏 Coding Standards](#coding-standards)
- [📝 Commit Conventions](#commit-conventions)
- [🔄 PR Workflow](#pr-workflow)
- [✅ Code Review Checklist](#️code-review-checklist)
- [🛠️ Troubleshooting](#troubleshooting)
- [🆘 Getting Help](#getting-help)

---

## 🧰 Tech Stack Overview

| Area            | Tools |
|-----------------|-------|
| Languages       | PHP 8.2, Node.js 20 |
| Frameworks      | Symfony (User Service), Express (Notification Service) |
| Databases       | MySQL per service (user-db, notif-db) |
| Messaging       | RabbitMQ |
| Gateway         | Nginx (reverse proxy, rate limiting, CORS) |
| CI/CD           | GitHub Actions (build, test, optional GHCR push, optional SSH deploy) |
| Containers      | Docker, Docker Compose v2 |
| Docs/Diagrams   | OpenAPI, Postman, Mermaid (communication), SVG (rendered) |

---

## 📚 API Docs & Postman

- OpenAPI (JSON):
  - Users: `docs/user-service.openapi.json`
  - Notifications: `docs/notification-service.openapi.json`
- Swagger UI via Gateway:
  - Users UI: `http://localhost:8082/api/users/docs`
  - Notifications UI: `http://localhost:8082/api/notifications/docs`
- Postman:
  - Collection: `docs/postman/collection.json`
  - Environment: `docs/postman/environment.json`
  - Import both and set `GATEWAY_URL` to `http://localhost:8082`.

---

## 🩺 Health & Readiness

- Gateway health: `GET http://localhost:8082/health` (returns `{ "status": "ok" }`)
- User Service readiness: `GET http://localhost:8080/ready`
- Notification Service readiness: `GET http://localhost:8081/ready`

---

## ✅ Testing Overview

- `make smoke`
  - Checks gateway `/health`
  - GET `/api/users`
  - Verifies Swagger UIs under `/api/users/docs` and `/api/notifications/docs`
  - Optional quick rate-limit probe (uses GNU parallel if installed)
- `make e2e`
  - Creates two users (unique emails)
  - Sends a notification to recipient
  - Fetches notification and validates payload and recipient
- Both respect `GATEWAY_URL` env var (defaults to `http://localhost:8082`). Example:
  - `GATEWAY_URL=http://localhost:8082 make e2e`

---

## 🔎 Observability & Limits

- Correlation IDs: pass `X-Correlation-ID` header; gateway forwards to services and logs. Use `make logs`, `make logs-gw`.
- Rate limiting: templated per environment via gateway config.
  - CI defaults: `GW_RATE_LIMIT=100r/s`, `GW_BURST=200` (avoid flaky tests)
  - Production: tune lower (e.g., `20r/s`, burst `40`) per SLOs
  - Generate config: `make gw-build-conf` (uses `infra/nginx/conf.d/default.conf.template`)

### Logs
- Tail all: `make logs`
- Tail gateway only: `make logs-gw`
- Filter by correlation id example:
  ```bash
  CORR=$(uuidgen)
  curl -H "X-Correlation-ID: $CORR" http://localhost:8082/api/users >/dev/null
  docker compose -f infra/docker-compose.yml logs gateway | grep "$CORR"
  ```

Example log line (gateway):
```
2025-08-26T14:12:03Z gateway INFO request_completed correlation_id=2f1a9e65-1234-4b2c-9a9a-abcdef status=200 method=GET path=/api/users duration_ms=12
```

---

## 🧭 Dev vs Prod Modes

- The User Service container defaults to `APP_ENV=prod` (`infra/docker-compose.yml`).
- For local development, you can switch to dev mode by setting `APP_ENV=dev` and then:
  ```bash
  make restart-user
  ```
- Note: using prod mode locally is fine for quick demos; dev mode enables more verbose debugging.

 

## 📋 Prerequisites
- **Docker 20.10+** with Docker Compose v2
- **GNU Make**
- **Git**
 - **Node.js 18+** (local dev; tested with Node 20)
- **PHP 8.2+** (local dev)

Optional tools: Postman/Insomnia, MySQL client, VS Code/PHPStorm

Knowledge: Docker, REST APIs, Symfony (PHP), Express (Node.js)

---

## ⚙️ Environment Setup
```bash
# Clone repository
git clone https://github.com/slimenmohamed/microservices-architecture.git
cd microservices-architecture

# Verify tools
docker --version
docker compose version
make --version
```

Start environment:
```bash
make up   # starts all services
docker ps # check containers
```

Verify:
```bash
curl http://localhost:8082/health
```

---

## 💻 Daily Development Workflow

```bash
make up         # start services
make smoke      # quick health checks
make e2e        # full tests
make logs       # monitor logs
make migrate    # apply DB migrations
make export-openapi  # update API docs
make down       # stop services
```

### Hot Reloading
- Symfony (PHP): auto-reload
- Express (Node): restart via nodemon
 - Nginx: restart container after config changes (use `make restart-gw`)
 - Convenience restarts: `make restart-gw`, `make restart-user`, `make restart-notif`, `make restart-all`

### Local environment notes
- `user-service` runs with `APP_ENV=prod` by default (see `infra/docker-compose.yml`). For dev mode, change to `APP_ENV=dev` locally if desired and `make restart-user`.

---

## 📖 Command Reference

### Container Ops
```bash
make up              # start all
make down            # stop & cleanup
make ps              # show status
make logs            # all logs
make logs-user       # user service logs
make logs-notif      # notification logs
make logs-gw         # gateway logs
make restart-gw      # restart gateway only
make restart-user    # restart user-service only
make restart-notif   # restart notification-service only
make restart-all     # restart all services
```

### Cleanup
```bash
make down   # stop containers and remove associated volumes (full cleanup)
```

### Database Development
```bash
make migrate   # apply migrations
make status    # check migrations
```

Advanced DB operations (backup, restore, manual migrations) → see docs/

#### Database cheatsheet (MySQL)

User DB (`user-db`):
```bash
# Open MySQL shell
docker compose -f infra/docker-compose.yml exec user-db mysql -usymfony -psymfony userdb

# List tables
docker compose -f infra/docker-compose.yml exec user-db mysql -usymfony -psymfony -e "SHOW TABLES;" userdb

# Dump (backup)
docker compose -f infra/docker-compose.yml exec user-db mysqldump -usymfony -psymfony userdb > userdb_dump.sql

# Restore
docker compose -f infra/docker-compose.yml exec -T user-db mysql -usymfony -psymfony userdb < userdb_dump.sql
```

Notification DB (`notif-db`):
```bash
# Open MySQL shell
docker compose -f infra/docker-compose.yml exec notif-db mysql -unode -pnode notifdb

# Dump (backup)
docker compose -f infra/docker-compose.yml exec notif-db mysqldump -unode -pnode notifdb > notifdb_dump.sql

# Restore
docker compose -f infra/docker-compose.yml exec -T notif-db mysql -unode -pnode notifdb < notifdb_dump.sql
```

### RabbitMQ
```bash
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_queues
```

#### RabbitMQ cheatsheet
```bash
# List queues (name, messages ready, unacked)
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_queues name messages_ready messages_unacknowledged

# List exchanges
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_exchanges name type

# List bindings
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_bindings

# Purge a queue (replace <queue>)
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl purge_queue <queue>

# Create a test queue
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl declare_queue name=test durable=true

# Management UI
# http://localhost:15672 (guest/guest)
```

### API Testing (examples)
```bash
curl -X GET http://localhost:8082/api/users
curl -X POST http://localhost:8082/api/users -d '{"name":"Test","email":"a@b.com"}' -H "Content-Type: application/json"
# Versioned routes
curl -X GET http://localhost:8082/api/v1/users

# Gateway-exposed API docs
curl -I http://localhost:8082/api/users/docs
curl -I http://localhost:8082/api/notifications/docs

# Correlation ID example
curl -H 'X-Correlation-Id: 123e4567-e89b-12d3-a456-426614174000' http://localhost:8082/api/users

# Simple rate limit probe (may see 429):
for i in {1..15}; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8082/api/users; done | sort | uniq -c
```

### API Versioning
- Gateway supports both unversioned and versioned routes:
  - Users: `/api/users` and `/api/v1/users`
  - Notifications: `/api/notifications` and `/api/v1/notifications`
- Prefer versioned routes (`/api/v1/...`) for external clients to enable safe evolution.

---

## 📏 Coding Standards
- Service independence (own DB, API-first)
- RESTful API design
- Health endpoints: `/health`, `/ready`
- Swagger/OpenAPI docs for all endpoints
- Structured logs with correlation IDs
- Security: input validation, SQL injection prevention, CORS, rate limiting

---

## 📝 Commit Conventions
We use **Conventional Commits**.

Format:
```
<type>[scope]: description
```

Examples:
- feat(user-service): add profile endpoints
- fix(gateway): resolve CORS issue
- docs: update README

Types: feat, fix, docs, style, refactor, test, chore, ci

---

## 🔄 PR Workflow
1. Create branch: `git checkout -b feat/my-feature`
2. Make changes & test: `make smoke && make e2e`
3. Commit: `feat(scope): description`
4. Push & open PR
5. Address reviews

PR Template:
```markdown
## Description
What this PR does

## Type
- [ ] Bug fix
- [ ] Feature
- [ ] Docs

## Tests
- [ ] make smoke
- [ ] make e2e

## Checklist
- [ ] Docs updated
- [ ] Tests added
- [ ] Conventional commits
```

---

## ✅ Code Review Checklist
- Code quality & readability
- Proper error handling
- Tests pass & edge cases covered
- Docs updated
- Commit message format followed
- No sensitive info in code/logs

---

## 🛠️ Troubleshooting
- **Service down** → `make logs`
- **Port conflict** → free ports 8080-8082, 3307-3308, 5672, 15672
- **Docker issue** → `docker system prune -f`
- **Gateway 502** → restart gateway: `make restart-gw`

---

## 🆘 Getting Help
- GitHub Issues → bugs & features
- GitHub Discussions → questions
- CI Logs → check failed workflows
- Docs → README + this guide
