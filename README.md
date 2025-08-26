# Microservices Architecture (Symfony + Node.js)

![Docker](https://img.shields.io/badge/Docker-✓-2496ED?logo=docker&logoColor=white)
![Compose](https://img.shields.io/badge/Compose-✓-384d54?logo=docker&logoColor=white)
![PHP](https://img.shields.io/badge/PHP-8.2-777BB4?logo=php&logoColor=white)
![Node](https://img.shields.io/badge/Node.js-20-339933?logo=node.js&logoColor=white)
[![CI](https://github.com/slimenmohamed/microservices-architecture/actions/workflows/ci.yml/badge.svg)](https://github.com/slimenmohamed/microservices-architecture/actions/workflows/ci.yml)

## Overview

This repo contains a minimal microservices setup with two independent services, each with its own database, containerized with Docker and orchestrated via Docker Compose.

Services:
- user-service: Symfony (PHP) + MySQL
- notification-service: Node.js (Express) + MySQL

No authentication. Minimal models and REST endpoints. No relation between services.

## Table of Contents
- [Overview](#overview)
- [Project Structure](#project-structure)
- [Features](#features)
- [Compliance Matrix](#compliance-matrix)
- [Tech Stack](#tech-stack)
- [Quick Start](#quick-start)
- [At a Glance](#at-a-glance)
- [Architecture](#architecture-high-level)
- [Getting Started](#getting-started)
- [API Endpoints](#api-endpoints)
- [Gateway](#gateway)
- [Example Workflow](#example-workflow)
- [Docs & Tooling](#docs--tooling)
- [Quick Tests](#quick-tests)
- [Cleanup](#cleanup)
- [Deep Dive: Architecture and Usage](#deep-dive-architecture-and-usage)
- [How to add a new service](#how-to-add-a-new-service)
- [Troubleshooting](#troubleshooting)
- [Development tips](#development-tips)
- [Contributing](#contributing)

## Features
- Service-per-database isolation
- Dockerized services orchestrated with Docker Compose
- Health and readiness endpoints with Compose healthchecks
- OpenAPI/Swagger UI per service
- Nginx API Gateway for a single entry point
- Inter-service communication with correlation IDs
- Database migrations (Symfony) and startup schema/index ensure (Node)
- Input validation (Symfony Validator, express-validator)
- Centralized error handling and graceful shutdown (notification-service)
- Gateway rate limiting (limit_req) to mitigate bursts/abuse

## Tech Stack
- user-service: Symfony (PHP 8), Doctrine DBAL, Doctrine Migrations, Symfony Validator, NelmioApiDocBundle, MySQL
- notification-service: Node.js (Express), express-validator, swagger-jsdoc, swagger-ui-express, uuid, MySQL
- infra: Docker, Docker Compose, Nginx (hardened with timeouts and rate limiting)

## Compliance Matrix

This section maps the project brief requirements to their implementation in this repository.

- __Backend language (Laravel/Express/other)__
  - Implemented: `user-service` uses Symfony (PHP) and `notification-service` uses Express (Node.js).
  - References: `user-service/`, `notification-service/`.

- __One database per service__
  - Implemented: `user-db` (MySQL) and `notif-db` (MySQL) are separate.
  - Reference: `infra/docker-compose.yml`.

- __Communication via REST (mandatory)__
  - Implemented: REST endpoints in both services, exposed via Nginx gateway.
  - References: `user-service/src/Controller/UserController.php`, `notification-service/src/routes/notifications.js`, `infra/nginx/conf.d/`.

- __Message Queue (optional)__
  - Implemented (optional): RabbitMQ broker and a `notification-worker` consumer; `notification-service` publishes `notifications.created` events (best-effort).
  - References: `infra/docker-compose.yml` (services `rabbitmq`, `notification-worker`), `notification-service/src/queue.js`, `notification-service/src/worker.js`.

- __Containerization (Docker)__
  - Implemented: Dockerfiles per service; images built and run via Compose.
  - References: `user-service/Dockerfile`, `notification-service/Dockerfile`.

- __Orchestration (Docker Compose)__
  - Implemented: Full stack orchestration including DBs, services, gateway, RabbitMQ.
  - Reference: `infra/docker-compose.yml`.

- __Documentation (OpenAPI/Swagger or Postman)__
  - Implemented: Swagger per service and a Postman collection (+ environment).
  - References: `http://localhost:8080/docs`, `http://localhost:8081/docs`, `docs/postman/collection.json`, `docs/postman/environment.json`.

- __API Gateway (optional)__
  - Implemented: Nginx gateway routes `/api/users` and `/api/notifications`.
  - Reference: `infra/nginx/conf.d/`.

- __Authentication (JWT optional)__
  - Not required by brief; not implemented.

- __Integration scenario: send notification user→user__
  - Implemented: E2E scenario and script.
  - References: `scripts/e2e.sh`, `make e2e`.

- __Architecture diagram + README__
  - Implemented: Mermaid diagram and static SVG; comprehensive README.
  - References: `README.md` (Architecture section), `docs/architecture.svg`.

## Quick Start

Prerequisites: Docker, Docker Compose, make, bash, curl, jq (optional: GNU parallel)

```bash
# 1) Start the full stack
make up

# 2) Smoke test via gateway (health, endpoints, docs)
make smoke

# 3) End-to-end test (creates users, sends a notification, verifies)
make e2e

# 4) Tail logs if needed
make logs   # or: make logs-user | logs-notif | logs-gw

# 5) Stop everything and remove volumes
make down
```

## At a Glance

- __Service URLs__
  - user-service: http://localhost:8080
  - notification-service: http://localhost:8081
  - gateway: http://localhost:8082
- __Gateway API routes__
  - /api/users -> user-service
  - /api/notifications -> notification-service
- __Docs__
  - User: http://localhost:8080/docs (gateway: http://localhost:8082/users/docs)
  - Notification: http://localhost:8081/docs (gateway: http://localhost:8082/notifications/docs)
  - Raw OpenAPI via gateway: /users/docs.json, /notifications/docs.json
- __Databases (host)__
  - user-db: localhost:3307 (internal: user-db:3306)
  - notif-db: localhost:3308 (internal: notif-db:3306)
- __Common commands__
  - make up | make down | make ps | make logs
  - make smoke | make e2e

## Project Structure

```
/microservices-architecture
├── user-service
│   ├── Dockerfile
│   ├── docker-entrypoint.sh
│   └── (app files generated during image build)
├── notification-service
│   ├── Dockerfile
│   ├── package.json
│   └── src/
├── infra
│   ├── docker-compose.yml
│   └── nginx/
│       └── conf.d/default.conf
├── Makefile
└── README.md
```

## Architecture (high level)

```mermaid
flowchart LR
    C[Clients]
    C --> G[API Gateway (Nginx)]
    G -->|/api/users| U[user-service (Symfony)]
    G -->|/api/notifications| N[notification-service (Express)]
    U --> UD[(user-db MySQL)]
    N --> ND[(notif-db MySQL)]
    N -->|publish events| MQ[RabbitMQ]
    MQ -->|consume| W[notification-worker]
```

Static diagram (for hosts without Mermaid): see `docs/architecture.svg`.

```
                 +---------------------+
                 |      Clients        |
                 +----------+----------+
                            |
                            v
                   +--------+--------+
                   |     Nginx       |
                   |   API Gateway   |
                   +---+---------+---+
                       |         |
     /api/users, /users/docs     |     /api/notifications, /notifications/docs
                       |         |
                       v         v
            +----------+--+    +-+------------+
            | user-service |    | notification |
            |   Symfony    |    |   Express    |
            +------+-------+    +------+-------+
                   |                   |
                   v                   v
            +------+-------+    +------+-------+
            |   user-db    |    |   notif-db   |
            |   MySQL      |    |   MySQL      |
            +--------------+    +------+-------+
                                         |
                                         | publish events
                                         v
                                  +------+------+
                                  |  RabbitMQ   |
                                  |  (optional) |
                                  +------+------+
                                         |
                                         | consume
                                         v
                                  +------+------+
                                  | notification|
                                  |   worker    |
                                  +-------------+
```

### Async flow (RabbitMQ)
The `notification-service` publishes best-effort events (e.g., `notifications.created`) to RabbitMQ. The `notification-worker` consumes these events from a queue bound to the `notifications` exchange. If RabbitMQ is unavailable, the HTTP request/response flow still succeeds; events are optional.

## Prerequisites
- Docker and Docker Compose

## Getting Started

From the `infra/` directory:

```bash
docker compose up --build
```

Services will start on:
- user-service: http://localhost:8080
- notification-service: http://localhost:8081
- gateway (Nginx): http://localhost:8082

MySQL instances:
- user-db: localhost:3307 (inside compose: user-db:3306)
- notif-db: localhost:3308 (inside compose: notif-db:3306)

## Developer commands (Makefile)

From repo root, convenient shortcuts:

```bash
make up         # build + start everything in background
make ps         # show services
make logs       # tail all logs (or: make logs-user | logs-notif | logs-gw)
make migrate    # run Symfony Doctrine migrations
make status     # show migration status
make smoke      # run smoke test (gateway, endpoints, docs)
make e2e        # run end-to-end notification test
make down       # stop and remove containers + volumes
```

## API Endpoints

### user-service (Symfony)
- GET    /users
- GET    /users/{id}
- POST   /users           (JSON: { "name": "...", "email": "..." })
- PUT    /users/{id}      (JSON: { "name": "...", "email": "..." })
- POST   /users/{id}/notify (JSON: { "subject": "...", "message": "..." })
- DELETE /users/{id}
 - Health: GET /health, GET /ready
  - Swagger UI: GET /docs (http://localhost:8080/docs)

### notification-service (Node.js)
- GET    /notifications
- GET    /notifications/:id
- POST   /notifications   (JSON: { "subject": "...", "message": "...", "recipientId": 1 (optional) })
- PUT    /notifications/:id  (JSON: { "subject": "...", "message": "..." })
- DELETE /notifications/:id
 - Health: GET /health, GET /ready
  - Swagger UI: GET /docs (http://localhost:8081/docs)

### Gateway (Nginx)
- Routes:
  - /api/users -> user-service
  - /api/notifications -> notification-service
- Docs via gateway:
  - /users/docs -> user-service Swagger UI
  - /notifications/docs -> notification-service Swagger UI

#### Rate limiting and timeouts
- Per-IP rate limit: 10 req/s with burst 20 (nodelay) on API routes.
- Sensible client body size and proxy timeouts to prevent slowloris/abuse.

#### Correlation IDs
 - Gateway forwards `X-Correlation-Id`; Node service sets one if missing and echoes it in responses/errors.
 - Use it to trace requests across services/gateway.

#### End-to-end flow (via gateway)
- The E2E test (`scripts/e2e.sh`, also `make e2e`) creates users, calls `POST /api/users/{id}/notify`, then verifies the notification via `/api/notifications/{id}`.

## Example Workflow

Run through the gateway at http://localhost:8082 once services are up.

```bash
# 1) Create two users (unique emails recommended) and capture IDs
ALICE_ID=$(curl -s -H 'Content-Type: application/json' \
  -d '{"name":"Alice","email":"alice-'"$(date +%s)""@example.com"}' \
  http://localhost:8082/api/users | jq -r '.id')

BOB_ID=$(curl -s -H 'Content-Type: application/json' \
  -d '{"name":"Bob","email":"bob-'"$(date +%s)""@example.com"}' \
  http://localhost:8082/api/users | jq -r '.id')

echo "Alice=$ALICE_ID, Bob=$BOB_ID"

# 2) Send a notification to Bob via user-service endpoint and capture notif ID
NOTIF_ID=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"subject":"Hello","message":"Hi from Alice"}' \
  http://localhost:8082/api/users/$BOB_ID/notify | jq -r '.id')

echo "Notification id=$NOTIF_ID"

# 3) Verify notification payload
curl -s http://localhost:8082/api/notifications/$NOTIF_ID | jq .
```

## Docs & Tooling
- Swagger UI exposed per service.
- Gateway exposes a unified entry point.
- Inter-service communication with correlation IDs.
- Export OpenAPI specs to `docs/` via the gateway:

```bash
bash scripts/export-openapi.sh
# Outputs:
# docs/user-service.openapi.json
# docs/notification-service.openapi.json
```

- Smoke test key endpoints and docs:

```bash
make smoke
```

- End-to-end test for the notification workflow:

```bash
make e2e
```

- Postman collection (gateway routes): `docs/postman/collection.json`
  - Import into Postman; set variables `recipientId` and `notificationId` as needed.

## Contributing

Please see `CONTRIBUTING.md` for guidelines on how to propose changes, coding standards, tests, and the PR process.

### Optional: Async Notifications (RabbitMQ)

- Services: `rabbitmq` (broker) and `notification-worker` (consumer) are defined in Compose.
- `notification-service` publishes a `notifications.created` event (best-effort). If RabbitMQ is down, the HTTP flow still succeeds.
- Management UI: http://localhost:15672 (default credentials: guest/guest)
- Environment:
  - `RABBITMQ_URL=amqp://rabbitmq:5672`
  - `NOTIF_EXCHANGE=notifications`
- Logs:
  - `make logs-notif` (publisher)
  - `docker compose -f infra/docker-compose.yml logs -f notification-worker`

## Error model and validation

- Standard error JSON:

```json
{ "code": 400, "message": "validation error", "correlationId": "...", "details": [ /* optional */ ] }
```

- user-service (Symfony):
  - Validates required fields and email format; enforces unique email; returns `{ code, message }`.
- notification-service (Node):
  - Uses `express-validator` for POST/PUT/DELETE; returns `{ code, message, details }` on 400.
  - Inter-service recipient check returns 422 if recipient doesn’t exist.
  - Centralized error handler ensures consistent error shape and includes `correlationId`.

## Migrations (user-service)

The Symfony service uses Doctrine Migrations to manage schema.

- Generate a blank migration (edit it to add SQL):

```bash
docker compose exec user-service php bin/console doctrine:migrations:generate
```

- Apply migrations (runs automatically on container start, but you can run manually too):

```bash
docker compose exec user-service php bin/console doctrine:migrations:migrate --no-interaction
```

Notes:
- The project uses DBAL-level SQL within migrations (no ORM entities). You can write SQL via `$this->addSql('...');` in the generated class.
- The initial migration is located at `user-service/migrations/` and creates `users (id, name, email unique)`.

## Quick Tests

Run these from your host once services are up:

```bash
# user-service (direct)
curl -s http://localhost:8080/users                 # list
curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"name":"Alice","email":"alice@example.com"}' \
  http://localhost:8080/users
curl -s http://localhost:8080/users/1               # get by id
curl -s -X PUT -H 'Content-Type: application/json' \
  -d '{"name":"Alice Updated","email":"alice@example.com"}' \
  http://localhost:8080/users/1
curl -i -s -X DELETE http://localhost:8080/users/1  # delete

# notification-service (direct)
curl -s http://localhost:8081/notifications
curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"subject":"Greetings","message":"hello"}' \
  http://localhost:8081/notifications
curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"subject":"Greetings","message":"hello","recipientId":1}' \
  http://localhost:8081/notifications

# via gateway
curl -s http://localhost:8082/api/users
curl -s http://localhost:8082/api/notifications

# docs
echo "User docs:           http://localhost:8080/docs (or gateway: http://localhost:8082/users/docs)"
echo "Notification docs:   http://localhost:8081/docs (or gateway: http://localhost:8082/notifications/docs)"
```

Or use the Makefile shortcuts once services are up:

```bash
make smoke   # basic health, endpoints, docs
make e2e     # creates users, sends a notification, verifies it
```

## Cleanup

```bash
docker compose down -v
```

This removes containers, networks, and volumes.

---

# Deep Dive: Architecture and Usage

## What this project demonstrates
- __Service independence__: each service has its own runtime and database.
- __Containerization__: every service is built and run in its own Docker image.
- __Service discovery via Compose__: services reach each other by service name (e.g., `user-service:8000`).
- __Operational readiness__: health and readiness endpoints, Compose healthchecks.
- __API documentation__: Swagger UI exposed per service.
- __Gateway pattern__: a simple Nginx reverse proxy exposes a unified entry point.
- __Inter-service communication__: notification-service validates `recipientId` by calling user-service.

## High-level architecture
```
[ client ]
    |
    v
[ Nginx gateway ]  -->  /api/users            -->  user-service (Symfony)  -->  MySQL (user-db)
         |          -->  /api/notifications   -->  notification-service     -->  MySQL (notif-db)

Health & Docs:
- user-service: /health, /ready, /docs       (direct: :8080)
- notification-service: /health, /ready, /docs (direct: :8081)
- via gateway: /users/docs, /notifications/docs (:8082)
```

## Using the stack
- __Local direct access__ (bypass gateway):
  - call `http://localhost:8080/...` for user-service
  - call `http://localhost:8081/...` for notification-service
- __Through the gateway__ (recommended for clients):
  - `http://localhost:8082/api/users`
  - `http://localhost:8082/api/notifications`
  - Docs: `http://localhost:8082/users/docs`, `http://localhost:8082/notifications/docs`

When to use which:
- Use direct ports for local debugging of a single service.
- Use the gateway when testing end-to-end flows or exposing a single entry point.

## Configuration
- Environment is set via `infra/docker-compose.yml`.
  - user-service DB URL: `DATABASE_URL=mysql://symfony:symfony@user-db:3306/userdb`
  - notification-service DB vars: `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`
- Ports (host -> container):
  - 8080->8000 (user-service), 8081->3000 (notification-service), 8082->80 (gateway)
- Healthchecks (Compose) hit `/ready` inside each container to gate dependencies and gateway startup.

## How to add a new service
Example: add `order-service` (choose your stack; steps below assume Node/Express + MySQL for brevity).

1) __Scaffold the service__
   - Create directory: `order-service/`
   - Add `Dockerfile`, `package.json`, and `src/` with `index.js`, routes, and DB module.
   - Expose health endpoints `/health` and `/ready`.
   - Add Swagger: `swagger-ui-express` + `swagger-jsdoc` (or OpenAPI file + UI server).

2) __Database__
   - In `infra/docker-compose.yml`, add an `order-db` service (e.g., MySQL) with its own volume and healthcheck.
   - Configure the app’s DB env vars (e.g., `DB_HOST=order-db`).

3) __Compose service entry__
   - Add an `order-service` entry:
     - `build.context: ../order-service`
     - `environment` for DB vars
     - `ports` (optional if only reachable via gateway)
     - `healthcheck` hitting `http://localhost:<port>/ready`

4) __Gateway routing__
   - Update `infra/nginx/conf.d/default.conf`:
     - Add a `location /api/orders/ { proxy_pass http://order-service:<port>/orders/; ... }`
     - Optionally expose docs: `location /orders/docs/ { proxy_pass http://order-service:<port>/docs/; }`

5) __Inter-service communication (optional)__
   - From existing services, call `http://order-service:<port>/...` inside the Compose network.
   - Propagate correlation IDs with `x-correlation-id` for traceability.

6) __Documentation and tests__
   - Document endpoints in Swagger and README.
   - Add basic integration tests (e.g., Jest or PHPUnit) and sample curl commands.

7) __Run__
   - `docker compose up -d --build`
   - Verify health: `GET /health` and `GET /ready` on your new service, and through gateway routes.

That’s it—your new service joins the mesh with isolated DB, healthchecks, docs, and routing via gateway.

## Troubleshooting
- __Service unhealthy__:
  - Check logs: `docker logs <service-name> --tail=200`
  - Confirm DB connectivity and that `/ready` returns 200.
- __Gateway 502/504__:
  - Ensure backend service is healthy and the Nginx route matches the backend path (trailing slashes matter).
  - After rebuilding backend containers, restart the gateway to refresh upstream DNS: `docker compose -f infra/docker-compose.yml restart gateway`.
- __Swagger not loading__:
  - For Symfony: ensure Nelmio bundle is registered and routes exist in `user-service/config/routes/nelmio_api_doc.yaml`.
  - For Node: verify `swaggerSpec` builds without errors and `/docs` route is registered.

## Development tips
- Use direct ports (8080/8081) while iterating on a single service; then verify via the gateway (8082).
- Keep endpoints versioned (e.g., `/v1/users`) when evolving APIs.
- Prefer migrations over ad-hoc schema creation for reproducible DB changes.
- Add central error handling and input validation to improve reliability.
