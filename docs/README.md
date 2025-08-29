# Docs

This folder contains API specifications and client tooling for the microservices architecture.

For the full project overview and setup instructions, see the root [README.md](../README.md).

## Guides
- Complete Testing Guide: [testing-guide.md](testing-guide.md)
- Adding a Microservice: [ADDING_A_SERVICE.md](ADDING_A_SERVICE.md)

## OpenAPI Specifications
- User Service: `user-service.openapi.json`
- Notification Service: `notification-service.openapi.json`

You can view these specs via the API Gateway as Swagger UI:
- Users UI: http://localhost:8082/api/users/docs
- Notifications UI: http://localhost:8082/api/notifications/docs

## Postman
- Collection: `postman/collection.json`
- Environment: `postman/environment.json`

Import both into Postman and set the `GATEWAY_URL` variable to:
```
http://localhost:8082
```

> Routing note: You can call the gateway using unversioned routes (`/api/...`) or versioned routes (`/api/v1/...`). Prefer versioned routes for client applications to ensure forward compatibility.

## Diagrams

- Architecture (SVG): `architecture.svg` (source: `architecture.mmd`)
- Communication (SVG): `communication.svg` (source: `communication.mmd`)

Render both diagrams with:
```
make render-diagrams
```

## Regenerating OpenAPI
If you make API changes, export fresh OpenAPI specs and update Postman if needed:
```
make export-openapi
```

## Endpoints, Docs, and Health

| Service              | Gateway Docs                              | Gateway API (primary)                    | Direct URL              | Health/Readiness           |
|----------------------|-------------------------------------------|------------------------------------------|-------------------------|----------------------------|
| API Gateway          | —                                         | —                                        | http://localhost:8082   | GET `/health`              |
| User Service         | http://localhost:8082/api/users/docs      | `/api/users` (or `/api/v1/users`)        | http://localhost:8080   | GET `/ready`               |
| Notification Service | http://localhost:8082/api/notifications/docs | `/api/notifications` (or `/api/v1/notifications`) | http://localhost:8081   | GET `/ready`               |
| Notification Worker  | —                                         | — (consumes RabbitMQ events)             | —                       | via container status/logs  |

### Observability
- Correlation IDs: pass header `X-Correlation-ID` in requests to the gateway; it is forwarded to services and shows up in logs. Example:
  ```bash
  CORR=$(uuidgen)
  curl -H "X-Correlation-ID: $CORR" http://localhost:8082/api/v1/users/health || true
  docker compose -f ../infra/docker-compose.yml logs gateway | grep "$CORR"
  ```
