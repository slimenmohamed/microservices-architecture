# Adding a New Microservice

This guide shows how to add a new microservice (example: "reporting-service") to this architecture.

It covers project layout, Dockerfile, docker-compose integration, database ownership, health endpoints, gateway routes, OpenAPI export, smoke/e2e checks, and scaling.

---

## 1) Project Layout

```
microservices-architecture/
├── reporting-service/           # Your new service (example)
│   ├── Dockerfile
│   ├── src/
│   └── ...
├── infra/
│   ├── docker-compose.yml
│   └── nginx/
│       └── conf.d/default.conf
└── docs/
    ├── reporting-service.openapi.json  # generated
    └── postman/
```

Naming recommendations:
- Folder: `reporting-service/`
- Container/service name in Compose: `reporting-service`
- API base path (gateway): `/api/reporting` and `/api/v1/reporting`

---

## 2) Dockerfile

Provide a minimal production-ready Dockerfile. Example (Node.js):

```dockerfile
# reporting-service/Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
ENV PORT=3000
EXPOSE 3000
CMD ["node", "server.js"]
```

For PHP/Symfony or other stacks, mirror the existing `user-service/` or `notification-service/` Dockerfiles.

---

## 3) Compose Stanza (infra/docker-compose.yml)

Add a service definition and (if needed) its own database. Each service must own its database.

```yaml
# Example additions to infra/docker-compose.yml
services:
  reporting-db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: reportingdb
      MYSQL_USER: app
      MYSQL_PASSWORD: app
    ports:
      - "3309:3306"   # adjust if needed
    volumes:
      - reporting_db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-uroot", "-proot"]
      interval: 5s
      timeout: 3s
      retries: 20

  reporting-service:
    build:
      context: ../reporting-service
      dockerfile: Dockerfile
    depends_on:
      reporting-db:
        condition: service_healthy
    environment:
      PORT: 3002
      DB_HOST: reporting-db
      DB_PORT: 3306
      DB_USER: app
      DB_PASSWORD: app
      DB_NAME: reportingdb
    ports:
      - "8083:3002"  # optional direct access for debugging
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS http://localhost:3002/ready || exit 1"]
      interval: 5s
      timeout: 3s
      retries: 20

volumes:
  reporting_db_data:
```

Notes:
- Use a distinct host port if you want to access the service directly (not required for gateway use).
- Always add a healthcheck for `/ready`.

---

## 4) Health Endpoints

Expose at least:
- `GET /health` → liveness
- `GET /ready` → readiness

The Compose healthcheck should probe `/ready`.

---

## 5) Gateway Routes (infra/nginx/conf.d/default.conf)

Add versioned and unversioned routes, plus optional docs pass-through.

```nginx
# Upstreams (top of file, if not already present)
upstream reporting_backend { zone reporting_zone 64k; least_conn; server reporting-service:3002 resolve; }

# Inside the server { ... }
# v1 (versioned)
location /api/v1/reporting/ {
    rewrite ^/api/v1/reporting/(.*)$ /reporting/$1 break;
    proxy_pass http://reporting_backend;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Correlation-Id $http_x_correlation_id;
    limit_req zone=api_rl burst=20 nodelay;
}
location = /api/v1/reporting {
    rewrite ^ /reporting break;
    proxy_pass http://reporting_backend;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Correlation-Id $http_x_correlation_id;
    limit_req zone=api_rl burst=20 nodelay;
}
# Unversioned
location /api/reporting/ {
    rewrite ^/api/reporting/(.*)$ /reporting/$1 break;
    proxy_pass http://reporting_backend;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Correlation-Id $http_x_correlation_id;
    limit_req zone=api_rl burst=20 nodelay;
}
location = /api/reporting {
    rewrite ^ /reporting break;
    proxy_pass http://reporting_backend;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Correlation-Id $http_x_correlation_id;
    limit_req zone=api_rl burst=20 nodelay;
}

# Optional: docs pass-through if your service exposes Swagger UI at /docs
# location /reporting/docs/ { ... proxy_pass http://reporting_backend; }
```

Remember to reload/restart the gateway container after updating config:
```bash
make restart-gw
make gw-config-test  # validate config inside the container
```

---

## 6) OpenAPI Export

Ensure your service can generate an OpenAPI JSON. Save outputs to:
- `docs/<service-name>.openapi.json`

Use the helper:
```bash
make export-openapi
```

---

## 7) Smoke Checks

Add quick health checks to `scripts/smoke.sh` (optional). Example:
```bash
# Gateway reachability already checked earlier in the script
curl -sSf http://localhost:8082/api/v1/reporting || exit 1
```

---

## 8) E2E Example

Extend `scripts/e2e.sh` (optional) with a simple end-to-end flow for your service.
Example:
```bash
# Create a resource
curl -sSf -X POST \
  -H 'Content-Type: application/json' \
  -d '{"name":"demo"}' \
  http://localhost:8082/api/v1/reporting | jq .

# Fetch it
curl -sSf http://localhost:8082/api/v1/reporting | jq .
```

Keep tests idempotent and self-contained.

---

## 9) Scaling Notes

Use Make helpers to scale horizontally:
```bash
REPL=2 make scale-user     # example for user-service
REPL=3 make scale-notif    # example for notification-service
```
For your new service, add a similar target (optional), e.g. `scale-reporting` in `Makefile`.

The gateway is configured with `least_conn` and DNS `resolve` to distribute requests among replicas.

---

## 10) Checklist

- Service code + `Dockerfile`
- Compose service + optional DB (own your data)
- Health endpoints `/health`, `/ready`
- Gateway routes added and validated
- OpenAPI exported to `docs/`
- Smoke/E2E flows updated
- Optional scaling target in Makefile
- Documentation updated (this guide)
