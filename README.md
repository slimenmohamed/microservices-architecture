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
- **Production Ready**: Health checks, logging, monitoring, and error handling
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
- [Database Design](#database-design)
- [Communication Patterns](#communication-patterns)

### 🔧 **Development**
- [Developer Commands](#developer-commands)
- [Complete Command Reference](#complete-command-reference)
- [Database Operations](#database-operations)
- [API Documentation](#api-documentation)
- [Testing Guide](#testing-guide)
- [Debugging & Monitoring](#debugging--monitoring)
- [Advanced Operations](#advanced-operations)
- [Performance Monitoring](#performance-monitoring)

### 📖 **Reference**
- [Compliance Matrix](#compliance-matrix)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Project Structure](#project-structure)

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

### **Health Check Commands**
```bash
# Quick health verification
curl http://localhost:8082/health

# Test user creation
curl -X POST http://localhost:8082/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'

# View all users
curl http://localhost:8082/api/users
```

### **Service Status Verification**
```bash
# View container status
make ps

# Expected output: All services should show "healthy" status
# - user-service: healthy
# - notification-service: healthy  
# - user-db: healthy
# - notif-db: healthy
# - rabbitmq: healthy
# - gateway: running
# - notification-worker: running
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
# Apply Symfony migrations
make migrate
# Equivalent to: cd infra && docker compose exec user-service php bin/console doctrine:migrations:migrate --no-interaction

# Check migration status
make status
# Equivalent to: cd infra && docker compose exec user-service php bin/console doctrine:migrations:status
```

#### **Testing Commands**
```bash
# Run smoke tests (health checks, basic functionality)
make smoke
# Equivalent to: bash scripts/smoke.sh

# Run end-to-end tests (complete workflow)
make e2e
# Equivalent to: bash scripts/e2e.sh

# Export OpenAPI specifications
make export-openapi
# Equivalent to: bash scripts/export-openapi.sh
```

---

## 📚 Complete Command Reference

### **Direct Docker Compose Commands**

#### **Service Management**
```bash
# Start specific services
docker compose -f infra/docker-compose.yml up user-service
docker compose -f infra/docker-compose.yml up notification-service
docker compose -f infra/docker-compose.yml up gateway

# Stop specific services
docker compose -f infra/docker-compose.yml stop user-service
docker compose -f infra/docker-compose.yml stop notification-service

# Restart specific services
docker compose -f infra/docker-compose.yml restart user-service
docker compose -f infra/docker-compose.yml restart notification-service

# Remove specific services
docker compose -f infra/docker-compose.yml rm user-service
docker compose -f infra/docker-compose.yml rm notification-service
```

#### **Image Management**
```bash
# Build specific service images
docker compose -f infra/docker-compose.yml build user-service
docker compose -f infra/docker-compose.yml build notification-service
docker compose -f infra/docker-compose.yml build notification-worker

# Build without cache
docker compose -f infra/docker-compose.yml build --no-cache user-service
docker compose -f infra/docker-compose.yml build --no-cache notification-service

# Pull latest base images
docker compose -f infra/docker-compose.yml pull
```

#### **Container Inspection**
```bash
# Show detailed container information
docker compose -f infra/docker-compose.yml ps -a
docker compose -f infra/docker-compose.yml ps --services
docker compose -f infra/docker-compose.yml ps --filter "status=running"

# Show container resource usage
docker compose -f infra/docker-compose.yml top

# Show container configuration
docker compose -f infra/docker-compose.yml config
docker compose -f infra/docker-compose.yml config --services
```

### **Container Execution Commands**

#### **User Service (Symfony/PHP)**
```bash
# Execute commands in user-service container
docker compose -f infra/docker-compose.yml exec user-service bash

# Symfony console commands
docker compose -f infra/docker-compose.yml exec user-service php bin/console list
docker compose -f infra/docker-compose.yml exec user-service php bin/console debug:router
docker compose -f infra/docker-compose.yml exec user-service php bin/console debug:container

# Database operations
docker compose -f infra/docker-compose.yml exec user-service php bin/console doctrine:database:create
docker compose -f infra/docker-compose.yml exec user-service php bin/console doctrine:database:drop --force
docker compose -f infra/docker-compose.yml exec user-service php bin/console doctrine:schema:validate

# Migration operations
docker compose -f infra/docker-compose.yml exec user-service php bin/console doctrine:migrations:list
docker compose -f infra/docker-compose.yml exec user-service php bin/console doctrine:migrations:generate
docker compose -f infra/docker-compose.yml exec user-service php bin/console doctrine:migrations:execute --up VERSION
docker compose -f infra/docker-compose.yml exec user-service php bin/console doctrine:migrations:execute --down VERSION

# Cache operations
docker compose -f infra/docker-compose.yml exec user-service php bin/console cache:clear
docker compose -f infra/docker-compose.yml exec user-service php bin/console cache:warmup

# Composer operations
docker compose -f infra/docker-compose.yml exec user-service composer install
docker compose -f infra/docker-compose.yml exec user-service composer update
docker compose -f infra/docker-compose.yml exec user-service composer dump-autoload
```

#### **Notification Service (Node.js/Express)**
```bash
# Execute commands in notification-service container
docker compose -f infra/docker-compose.yml exec notification-service bash

# Node.js operations
docker compose -f infra/docker-compose.yml exec notification-service node --version
docker compose -f infra/docker-compose.yml exec notification-service npm --version

# NPM operations
docker compose -f infra/docker-compose.yml exec notification-service npm install
docker compose -f infra/docker-compose.yml exec notification-service npm update
docker compose -f infra/docker-compose.yml exec notification-service npm audit
docker compose -f infra/docker-compose.yml exec notification-service npm audit fix

# Application operations
docker compose -f infra/docker-compose.yml exec notification-service npm start
docker compose -f infra/docker-compose.yml exec notification-service npm run dev
docker compose -f infra/docker-compose.yml exec notification-service npm test
```

### **Database Operations**

#### **User Database (MySQL)**
```bash
# Connect to user database
mysql -h localhost -P 3307 -u symfony -p userdb
# Password: symfony

# Database operations via Docker
docker compose -f infra/docker-compose.yml exec user-db mysql -u root -p userdb
# Password: root

# Backup user database
docker compose -f infra/docker-compose.yml exec user-db mysqldump -u root -p userdb > user_backup.sql

# Restore user database
docker compose -f infra/docker-compose.yml exec -T user-db mysql -u root -p userdb < user_backup.sql

# Show user database tables
docker compose -f infra/docker-compose.yml exec user-db mysql -u root -p -e "USE userdb; SHOW TABLES;"

# Show user database structure
docker compose -f infra/docker-compose.yml exec user-db mysql -u root -p -e "USE userdb; DESCRIBE users;"
```

#### **Notification Database (MySQL)**
```bash
# Connect to notification database
mysql -h localhost -P 3308 -u node -p notifdb
# Password: node

# Database operations via Docker
docker compose -f infra/docker-compose.yml exec notif-db mysql -u root -p notifdb
# Password: root

# Backup notification database
docker compose -f infra/docker-compose.yml exec notif-db mysqldump -u root -p notifdb > notif_backup.sql

# Restore notification database
docker compose -f infra/docker-compose.yml exec -T notif-db mysql -u root -p notifdb < notif_backup.sql

# Show notification database tables
docker compose -f infra/docker-compose.yml exec notif-db mysql -u root -p -e "USE notifdb; SHOW TABLES;"

# Show notification database structure
docker compose -f infra/docker-compose.yml exec notif-db mysql -u root -p -e "USE notifdb; DESCRIBE notifications;"
```

### **RabbitMQ Operations**

#### **Management Commands**
```bash
# Access RabbitMQ container
docker compose -f infra/docker-compose.yml exec rabbitmq bash

# RabbitMQ management commands
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl status
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_queues
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_exchanges
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_bindings
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_connections
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_channels

# Queue management
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl purge_queue notification_queue
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl delete_queue notification_queue

# User management
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_users
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl add_user newuser password
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl set_user_tags newuser administrator
```

#### **Message Publishing (Testing)**
```bash
# Publish test message to exchange
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqadmin publish exchange=notifications routing_key=created payload="{\"test\":\"message\"}"

# Get messages from queue
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqadmin get queue=notification_queue
```

### **API Testing Commands**

#### **Health Check Endpoints**
```bash
# Test all health endpoints
curl -i http://localhost:8082/health          # Gateway health
curl -i http://localhost:8080/health          # User service health
curl -i http://localhost:8081/health          # Notification service health

# Test readiness endpoints
curl -i http://localhost:8080/ready           # User service readiness
curl -i http://localhost:8081/ready           # Notification service readiness
```

#### **User Service API Testing**
```bash
# List all users
curl -X GET http://localhost:8082/api/users
curl -X GET http://localhost:8080/users       # Direct access

# Create a new user
curl -X POST http://localhost:8082/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

# Get specific user
curl -X GET http://localhost:8082/api/users/1

# Update user
curl -X PUT http://localhost:8082/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"John Smith","email":"johnsmith@example.com"}'

# Delete user
curl -X DELETE http://localhost:8082/api/users/1

# Send notification via user service
curl -X POST http://localhost:8082/api/users/2/notify \
  -H "Content-Type: application/json" \
  -d '{"subject":"Hello","message":"Test notification"}'
```

#### **Notification Service API Testing**
```bash
# List all notifications
curl -X GET http://localhost:8082/api/notifications
curl -X GET http://localhost:8081/notifications    # Direct access

# Create notification
curl -X POST http://localhost:8082/api/notifications \
  -H "Content-Type: application/json" \
  -d '{"subject":"Test","message":"Hello World","recipientId":1}'

# Get specific notification
curl -X GET http://localhost:8082/api/notifications/1

# Update notification
curl -X PUT http://localhost:8082/api/notifications/1 \
  -H "Content-Type: application/json" \
  -d '{"subject":"Updated","message":"Updated message"}'

# Delete notification
curl -X DELETE http://localhost:8082/api/notifications/1
```

#### **Advanced API Testing**
```bash
# Test with correlation ID
curl -X GET http://localhost:8082/api/users \
  -H "X-Correlation-Id: test-12345"

# Test rate limiting
for i in {1..15}; do curl -s http://localhost:8082/api/users; done

# Test CORS
curl -X OPTIONS http://localhost:8082/api/users \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Content-Type"

# Test error handling
curl -X POST http://localhost:8082/api/users \
  -H "Content-Type: application/json" \
  -d '{"invalid":"data"}'
```

### **Performance Monitoring**

#### **Resource Usage**
```bash
# Monitor container resource usage
docker stats
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# Monitor specific containers
docker stats user-service notification-service api-gateway

# Memory usage by service
docker compose -f infra/docker-compose.yml exec user-service free -h
docker compose -f infra/docker-compose.yml exec notification-service free -h

# Disk usage
docker system df
docker system df -v
```

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
