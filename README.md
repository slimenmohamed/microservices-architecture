# 🏗️ Microservices Architecture

> **Production-ready microservices architecture demonstrating modern software engineering practices**

![Docker](https://img.shields.io/badge/Docker-✓-2496ED?logo=docker&logoColor=white)
![Compose](https://img.shields.io/badge/Compose-✓-384d54?logo=docker&logoColor=white)
![PHP](https://img.shields.io/badge/PHP-8.2-777BB4?logo=php&logoColor=white)
![Node](https://img.shields.io/badge/Node.js-20-339933?logo=node.js&logoColor=white)
[![CI](https://github.com/slimenmohamed/microservices-architecture/actions/workflows/ci.yml/badge.svg)](https://github.com/slimenmohamed/microservices-architecture/actions/workflows/ci.yml)

## 📋 Overview

This repository demonstrates a **complete microservices architecture** with two independent services, implementing industry best practices for distributed systems. Each service maintains its own database, ensuring proper service isolation and independence.

### 🎯 **Key Features**
- **Service Independence**: Each service has its own database and can be deployed separately
- **API Gateway**: Unified entry point with Nginx for request routing and rate limiting
- **Async Communication**: RabbitMQ message broker for event-driven architecture
- **Complete CI/CD**: Automated testing and deployment with GitHub Actions
- **Production Ready**: Health checks, logging, and error handling
- **Developer Friendly**: One-command setup, comprehensive testing, and documentation

### 🔧 **Services Architecture**
| Service | Technology | Database | Purpose |
|---------|------------|----------|----------|
| **user-service** | Symfony (PHP 8.2) | MySQL | User management and authentication |
| **notification-service** | Express (Node.js 20) | MySQL | Notification handling and delivery |
| **api-gateway** | Nginx | - | Request routing, rate limiting, CORS |
| **notification-worker** | Node.js | - | Async event processing from RabbitMQ |

### ⚡ **Quick Start**
```bash
# Start everything with one command
make up

# Run comprehensive tests
make smoke && make e2e

# View all services status
make ps
```

## 📚 Table of Contents

### 🚀 **Getting Started**
- [Prerequisites](#prerequisites)
- [Quick Setup](#quick-setup)
- [Verification](#verification)

### 🏗️ **Architecture & Design**
- [System Architecture](#system-architecture)
- [Service Details](#service-details)
- [API Documentation](#api-documentation)

### 🔧 **Development**
- [Basic Commands](#basic-commands)
- [Testing](#testing)
- [Contributing](#contributing)

### 📖 **Reference**
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)

---

## 📋 Prerequisites

### **System Requirements**
- **Docker**: Version 20.10+ ([Install Docker](https://docs.docker.com/get-docker/))
- **Docker Compose**: Version 2.0+ (included with Docker Desktop)
- **Make**: GNU Make for command shortcuts
- **Git**: For version control

### **Optional Tools**
- **curl**: For API testing (usually pre-installed)
- **jq**: For JSON processing in scripts
- **GNU parallel**: For advanced rate limiting tests

### **Port Requirements**
Ensure these ports are available on your system:
- `8080`: User service direct access
- `8081`: Notification service direct access  
- `8082`: API Gateway (main entry point)
- `3307`: User database (MySQL)
- `3308`: Notification database (MySQL)
- `5672`: RabbitMQ AMQP
- `15672`: RabbitMQ Management UI

---

## 🚀 Quick Setup

### **1. Clone & Navigate**
```bash
git clone https://github.com/slimenmohamed/microservices-architecture.git
cd microservices-architecture
```

### **2. Start All Services**
```bash
# Build and start everything (databases, services, gateway, message broker)
make up
```

### **3. Verify Installation**
```bash
# Check all services are healthy
make ps

# Run health checks
make smoke

# Test end-to-end workflow
make e2e
```

### **4. Access Services**
- **🌐 API Gateway**: http://localhost:8082 *(recommended entry point)*
- **👥 User Service**: http://localhost:8080/docs *(Swagger UI)*
- **📧 Notification Service**: http://localhost:8081/docs *(Swagger UI)*
- **🐰 RabbitMQ Management**: http://localhost:15672 *(guest/guest)*

---

## ✅ Verification

```bash
# Quick health verification
curl http://localhost:8082/health

# View container status - all should show "healthy"
make ps

# Run automated tests
make smoke && make e2e
```

---

## 🔧 Developer Commands

### **Essential Makefile Commands**

#### **Container Management**
```bash
# Build all Docker images
make build
# Equivalent to: cd infra && docker compose build

# Start all services in detached mode
make up
# Equivalent to: cd infra && docker compose up -d --build

# Stop and remove all containers + volumes
make down
# Equivalent to: cd infra && docker compose down -v
# ⚠️ WARNING: This removes all data volumes

# Show service status and health
make ps
# Equivalent to: cd infra && docker compose ps
```

#### **Log Management**
```bash
# Tail logs from all services (200 lines)
make logs
# Equivalent to: cd infra && docker compose logs -f --tail=200

# Service-specific logs
make logs-user      # User service logs only
make logs-notif     # Notification service logs only  
make logs-gw        # Gateway logs only

# View worker logs (not in Makefile)
docker compose -f infra/docker-compose.yml logs -f notification-worker

# View logs without following
docker compose -f infra/docker-compose.yml logs --tail=50 user-service
docker compose -f infra/docker-compose.yml logs --tail=50 notification-service
docker compose -f infra/docker-compose.yml logs --tail=50 gateway
```

#### **Database Management**
```bash
# Apply Symfony migrations (user-service)
make migrate

# Show migration status
make status

# For advanced DB operations (backups, restores, direct MySQL access), see:
# CONTRIBUTING.md#database-development
```

#### **Testing**
```bash
# Run smoke tests (health checks, basic functionality)
make smoke

# Run end-to-end tests (complete workflow)
make e2e

# Export OpenAPI documentation
make export-openapi
```

**For detailed API testing examples and manual testing procedures, see [CONTRIBUTING.md#api-testing-and-development](CONTRIBUTING.md#api-testing-and-development)**

---

## 🤝 Contributing

We welcome contributions! This project follows modern development practices and has comprehensive tooling to support contributors.

**📖 For detailed development instructions, complete command references, coding guidelines, and troubleshooting, see [CONTRIBUTING.md](CONTRIBUTING.md)**

### **Quick Contribution Workflow**
```bash
# 1. Fork and clone the repository
git clone https://github.com/your-username/microservices-architecture.git
cd microservices-architecture

# 2. Start development environment
make up

# 3. Make your changes and test
make smoke && make e2e

# 4. Submit pull request
git add . && git commit -m "feat: your feature description"
git push origin your-branch
```

---

## 📖 Project Structure

```
microservices-architecture/
├── user-service/              # Symfony PHP service
│   ├── src/Controller/        # API controllers
│   ├── src/Entity/           # Doctrine entities
│   └── migrations/           # Database migrations
├── notification-service/      # Node.js Express service
│   ├── src/controllers/      # API controllers
│   ├── src/models/          # Database models
│   └── src/workers/         # Background workers
├── infra/                    # Infrastructure setup
│   ├── docker-compose.yml   # Service orchestration
│   └── nginx/               # API gateway config
├── scripts/                  # Automation scripts
└── docs/                    # Additional documentation
```

---

## 🔍 Troubleshooting

### **Common Issues**
- **Port conflicts**: Ensure ports 8080-8082, 3307-3308, 5672, 15672 are available
- **Docker issues**: Try `docker system prune -f` and restart Docker
- **Database connection**: Check if databases are running with `make ps`
- **Service startup**: Wait for health checks to pass before testing APIs

### **Getting Help**
- Check service logs: `make logs`
- Verify service health: `curl http://localhost:8082/health`
- Review [CONTRIBUTING.md](CONTRIBUTING.md) for detailed troubleshooting
- Open an issue on GitHub for persistent problems

#### **Network Monitoring**
```bash
# Show Docker networks
docker network ls
docker network inspect infra_default

# Monitor network traffic
docker compose -f infra/docker-compose.yml exec gateway netstat -tuln
docker compose -f infra/docker-compose.yml exec user-service netstat -tuln

# Test network connectivity between services
docker compose -f infra/docker-compose.yml exec user-service ping notification-service
docker compose -f infra/docker-compose.yml exec notification-service ping user-db
```

### **Advanced Operations**

#### **Scaling Services**
```bash
# Scale notification service to 3 instances
docker compose -f infra/docker-compose.yml up --scale notification-service=3

# Scale user service to 2 instances
docker compose -f infra/docker-compose.yml up --scale user-service=2

# View scaled services
docker compose -f infra/docker-compose.yml ps
```

#### **Environment Variables**
```bash
# Show environment variables in containers
docker compose -f infra/docker-compose.yml exec user-service env
docker compose -f infra/docker-compose.yml exec notification-service env

# Override environment variables
APP_ENV=dev docker compose -f infra/docker-compose.yml up user-service
PORT=3001 docker compose -f infra/docker-compose.yml up notification-service
```

#### **Volume Management**
```bash
# List Docker volumes
docker volume ls

# Inspect volumes
docker volume inspect infra_user_db_data
docker volume inspect infra_notif_db_data

# Backup volumes
docker run --rm -v infra_user_db_data:/data -v $(pwd):/backup alpine tar czf /backup/user_db_backup.tar.gz -C /data .
docker run --rm -v infra_notif_db_data:/data -v $(pwd):/backup alpine tar czf /backup/notif_db_backup.tar.gz -C /data .

# Restore volumes
docker run --rm -v infra_user_db_data:/data -v $(pwd):/backup alpine tar xzf /backup/user_db_backup.tar.gz -C /data
```

#### **Security Operations**
```bash
# Scan images for vulnerabilities
docker scout cves infra-user-service
docker scout cves infra-notification-service

# Check for outdated base images
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}"

# Update base images
docker compose -f infra/docker-compose.yml pull
docker compose -f infra/docker-compose.yml build --no-cache
```

---

## 📊 Compliance Matrix

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

This section is already covered above in [🚀 Quick Setup](#-quick-setup) and [✅ Verification](#-verification). Refer there for commands and usage.

## At a Glance

See [Access Services](#4-access-services) and [Developer Commands](#-developer-commands) above for URLs, routes, docs, and common commands.



---

## 🏗️ System Architecture

### **High-Level Overview**

```mermaid
flowchart TB
    subgraph "External"
        C["🌐 Clients<br/>(Web, Mobile, API)"]
    end
    
    subgraph "API Layer"
        G["🚪 API Gateway<br/>(Nginx)<br/>Port: 8082"]
    end
    
    subgraph "Services"
        U["👥 User Service<br/>(Symfony/PHP)<br/>Port: 8080"]
        N["📧 Notification Service<br/>(Express/Node.js)<br/>Port: 8081"]
        W["⚙️ Notification Worker<br/>(Node.js)"]
    end
    
    subgraph "Data Layer"
        UD[("🗄️ User DB<br/>(MySQL)<br/>Port: 3307")]
        ND[("🗄️ Notification DB<br/>(MySQL)<br/>Port: 3308")]
    end
    
    subgraph "Message Broker"
        MQ["🐰 RabbitMQ<br/>Port: 5672<br/>Management: 15672"]
    end
    
    C --> G
    G -->|/api/users/*| U
    G -->|/api/notifications/*| N
    U --> UD
    N --> ND
    N -.->|publish events| MQ
    MQ -.->|consume events| W
    
    classDef service fill:#e1f5fe
    classDef database fill:#f3e5f5
    classDef gateway fill:#e8f5e8
    classDef message fill:#fff3e0
    
    class U,N,W service
    class UD,ND database
    class G gateway
    class MQ message
```

> 📄 **Static diagram available**: `docs/architecture.svg` for environments without Mermaid support

### **Architecture Principles**

#### 🔒 **Service Independence**
- Each service owns its data (service-per-database pattern)
- Services communicate only through well-defined APIs
- No direct database access between services
- Independent deployment and scaling capabilities

#### 🌐 **API Gateway Pattern**
- Single entry point for all client requests
- Request routing based on URL patterns
- Cross-cutting concerns (rate limiting, CORS, logging)
- Service discovery and load balancing

#### 📨 **Event-Driven Communication**
- Synchronous: REST APIs for immediate responses
- Asynchronous: RabbitMQ for event notifications
- Loose coupling between services
- Resilient to service failures

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

## Basic Commands (Makefile)

From the repo root, the most common shortcuts are:

```bash
make up       # build + start everything
make down     # stop and remove containers + volumes
make ps       # show services
make logs     # tail all logs (use: logs-user | logs-notif | logs-gw)
make smoke    # quick health + basic checks
make e2e      # full end-to-end workflow test
```

For the complete command reference (databases, RabbitMQ, Docker Compose, advanced ops), see CONTRIBUTING.md.

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

A concise example flow is provided in CONTRIBUTING.md (API Testing and Development). It includes ready-to-run curl snippets for creating users, sending a notification, and verifying results through the gateway.

## Docs & Tooling
- Swagger UI exposed per service.
- Gateway exposes a unified entry point.
- Inter-service communication with correlation IDs.
- Export OpenAPI specs to `docs/` via the gateway:

```bash
make export-openapi
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

See [CONTRIBUTING.md#api-testing-and-development](CONTRIBUTING.md#api-testing-and-development) for ready-to-run curl snippets and Makefile shortcuts covering health checks, CRUD operations, and the end-to-end notification flow via the gateway.

## Cleanup

To remove containers, networks, and volumes: see [CONTRIBUTING.md#maintenance-cleanup-and-pruning](CONTRIBUTING.md#maintenance-cleanup-and-pruning) (includes safe cleanup and pruning commands).

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
