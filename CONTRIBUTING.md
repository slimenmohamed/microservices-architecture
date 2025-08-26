# Contributing

Thanks for contributing! This project demonstrates a minimal microservices stack.

## Prerequisites
- See `README.md` → [Prerequisites](README.md#prerequisites)

## Local Development
- See `README.md` for how to run and test locally:
  - [Quick Start](README.md#quick-start)
  - [Developer commands (Makefile)](README.md#developer-commands-makefile)

## Coding Guidelines
- Keep services independent (one DB per service).
- Add/modify endpoints with Swagger/OpenAPI annotations.
- Propagate `x-correlation-id` across requests.
- Prefer migrations (Symfony) and startup schema checks (Node) for DB changes.

## Docs
- Export OpenAPI: `bash scripts/export-openapi.sh` (outputs to `docs/`).
- Postman collection: `docs/postman/collection.json` (gateway URLs).

## Tests
- Smoke/E2E: `make smoke`, `make e2e`.
- CI runs both on PRs and pushes (see `.github/workflows/ci.yml`).

## Optional: RabbitMQ
- A RabbitMQ service is available in Compose. Not required for current flows.
- If you add async flows, document routing keys/queues and update README.

## Pull Requests
- Keep PRs small and focused.
- Update README/Docs when behavior changes.
- Include reproduction steps for bug fixes and evidence for test passes.
