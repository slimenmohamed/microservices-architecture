# Docs

This folder contains API specifications and client tooling for the microservices architecture.

For the full project overview and setup instructions, see the root [README.md](../README.md).

## OpenAPI Specifications
- Users: `user-service.openapi.json`
- Notifications: `notification-service.openapi.json`

You can view these specs via the API Gateway as Swagger UI:
- Users UI: http://localhost:8082/users/docs/
- Notifications UI: http://localhost:8082/notifications/docs/

## Postman
- Collection: `postman/collection.json`
- Environment: `postman/environment.json`

Import both into Postman and set the `GATEWAY_URL` variable to:
```
http://localhost:8082
```

Then you can run requests against the gateway using either unversioned (`/api/...`) or versioned (`/api/v1/...`) routes.

## Regenerating OpenAPI
If you make API changes, export fresh OpenAPI specs and update Postman if needed:
```
make export-openapi
```

## Health & Readiness
- Gateway health: `GET http://localhost:8082/health`
- User Service readiness: `GET http://localhost:8080/ready`
- Notification Service readiness: `GET http://localhost:8081/ready`
