# Contributing

Thanks for contributing! This project demonstrates a minimal microservices stack.

## Prerequisites
- See `README.md` → [Prerequisites](README.md#prerequisites)

## Local Development Environment Setup

### Initial Setup
```bash
# 1. Clone the repository
git clone https://github.com/slimenmohamed/microservices-architecture.git
cd microservices-architecture

# 2. Verify prerequisites
docker --version          # Should be 20.10+
docker compose version    # Should be 2.0+
make --version            # GNU Make
curl --version            # For testing
jq --version              # For JSON processing

# 3. Start the development environment
make up

# 4. Verify all services are healthy
make ps

# 5. Run initial tests
make smoke && make e2e
```

### Development Workflow
```bash
# Start services
make up

# Monitor logs during development
make logs              # All services
make logs-user         # User service only
make logs-notif        # Notification service only
make logs-gw           # Gateway only

# Test changes
make smoke             # Quick health checks
make e2e               # Full end-to-end tests

# Apply database changes (user-service)
make migrate

# Export updated API docs
bash scripts/export-openapi.sh

# Clean shutdown
make down
```

### Port Configuration
- **Gateway**: http://localhost:8082 (main entry point)
- **User Service**: http://localhost:8080 (direct access)
- **Notification Service**: http://localhost:8081 (direct access)
- **User DB**: localhost:3307 (MySQL)
- **Notification DB**: localhost:3308 (MySQL)
- **RabbitMQ Management**: http://localhost:15672 (guest/guest)

## Coding Guidelines
- Keep services independent (one DB per service).
- Add/modify endpoints with Swagger/OpenAPI annotations.
- Propagate `x-correlation-id` across requests.
- Prefer migrations (Symfony) and startup schema checks (Node) for DB changes.
- Follow RESTful API design principles.
- Include proper error handling and validation.
- Add health checks for new services.

## Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, semicolons, etc.)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks, dependency updates
- **ci**: CI/CD pipeline changes

### Examples
```bash
# Feature
feat(user-service): add email validation for user creation

# Bug fix
fix(gateway): resolve rate limiting configuration issue

# Documentation
docs(readme): update API endpoint documentation

# Test
test(notification): add e2e test for cross-service communication

# CI/CD
ci: improve health check timeout in GitHub Actions
```

### Scope Guidelines
- **user-service**: Changes to user service
- **notification-service**: Changes to notification service
- **gateway**: Changes to Nginx gateway
- **infra**: Infrastructure/Docker changes
- **ci**: CI/CD pipeline changes
- **docs**: Documentation updates

## Code Review Checklist

### Before Submitting PR
- [ ] Code follows project coding guidelines
- [ ] All tests pass locally (`make smoke && make e2e`)
- [ ] New features include appropriate tests
- [ ] Documentation updated if behavior changes
- [ ] Commit messages follow format standards
- [ ] No sensitive information in code/logs
- [ ] OpenAPI specs updated if API changes

### For Reviewers
#### Functionality
- [ ] Code solves the stated problem
- [ ] Edge cases are handled appropriately
- [ ] Error handling is comprehensive
- [ ] Input validation is present

#### Architecture
- [ ] Maintains service independence
- [ ] Follows microservices patterns
- [ ] Database changes use proper migrations
- [ ] API design follows REST principles

#### Quality
- [ ] Code is readable and well-documented
- [ ] No code duplication
- [ ] Proper logging and monitoring
- [ ] Security considerations addressed

#### Testing
- [ ] Unit tests cover new functionality
- [ ] Integration tests pass
- [ ] E2E scenarios work as expected
- [ ] Performance impact is acceptable

#### Documentation
- [ ] README updated if needed
- [ ] API documentation reflects changes
- [ ] Architecture diagrams updated if needed
- [ ] CONTRIBUTING.md updated for new processes

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

### PR Guidelines
- Keep PRs small and focused (< 400 lines of code changes).
- Use descriptive PR titles following commit message format.
- Include clear description of changes and motivation.
- Reference related issues with `Fixes #123` or `Closes #123`.
- Update README/Docs when behavior changes.
- Include reproduction steps for bug fixes and evidence for test passes.

### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] CI/CD changes

## Testing
- [ ] `make smoke` passes
- [ ] `make e2e` passes
- [ ] Manual testing performed (describe)

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

## Getting Help
- Check existing issues and discussions
- Review README.md and architecture documentation
- Test locally with `make smoke` and `make e2e`
- Check CI logs for detailed error information
