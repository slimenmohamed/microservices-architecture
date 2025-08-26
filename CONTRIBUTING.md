# 🤝 Contributing Guide

> **Welcome to the Microservices Architecture project!** We're excited to have you contribute to this production-ready microservices demonstration.

[![CI](https://github.com/slimenmohamed/microservices-architecture/actions/workflows/ci.yml/badge.svg)](https://github.com/slimenmohamed/microservices-architecture/actions/workflows/ci.yml)

## ℹ️ About this guide

This document is the comprehensive developer reference for this repo. It contains the full set of commands, workflows, troubleshooting tips, and standards.

- For a project overview, architecture, and quick start: see README.md.
- For detailed development operations (Docker Compose, DB/RabbitMQ, API testing, maintenance): use this guide.

## 📋 Table of Contents

### 🚀 **Getting Started**
- [Prerequisites](#prerequisites)
- [Development Environment Setup](#development-environment-setup)
- [First Contribution](#first-contribution)

### 💻 **Development Workflow**
- [Daily Development](#daily-development)
- [Testing Your Changes](#testing-your-changes)
- [Code Quality Standards](#code-quality-standards)

### 📝 **Standards & Guidelines**
- [Coding Guidelines](#coding-guidelines)
- [Commit Message Format](#commit-message-format)
- [Pull Request Process](#pull-request-process)

### ✅ **Quality Assurance**
- [Code Review Checklist](#code-review-checklist)
- [Testing Requirements](#testing-requirements)
- [Documentation Standards](#documentation-standards)

### 🆘 **Support**
- [Getting Help](#getting-help)
- [Troubleshooting](#troubleshooting)

---

## 📋 Prerequisites

### **System Requirements**
- **Docker**: Version 20.10+ with Docker Compose v2
- **Make**: GNU Make for build automation
- **Git**: Version control system
- **Node.js**: 18+ (for local development/testing)
- **PHP**: 8.2+ (for local development/testing)

### **Development Tools**
- **Code Editor**: VS Code, PHPStorm, or similar with Docker support
- **API Testing**: Postman, Insomnia, or curl
- **Database Client**: MySQL Workbench, DBeaver, or similar (optional)

### **Knowledge Prerequisites**
- Basic understanding of microservices architecture
- Familiarity with Docker and containerization
- REST API development experience
- Basic knowledge of PHP (Symfony) and Node.js (Express)

---

## 🛠️ Development Environment Setup

### **1. Initial Setup**
```bash
# Clone the repository
git clone https://github.com/slimenmohamed/microservices-architecture.git
cd microservices-architecture

# Verify prerequisites
docker --version          # Should be 20.10+
docker compose version    # Should be 2.0+
make --version            # GNU Make
curl --version            # For API testing
jq --version              # For JSON processing
```

### **2. Environment Startup**
```bash
# Start all services (databases, apps, gateway, message broker)
make up

# Verify all services are healthy
make ps

# Run comprehensive tests
make smoke && make e2e
```

### **3. Verify Installation**
```bash
# Test API Gateway
curl http://localhost:8082/health

# Test User Service
curl http://localhost:8080/health

# Test Notification Service  
curl http://localhost:8081/health
```

---

## 💻 Daily Development

### **Development Cycle**
```bash
# 1. Start your development session
make up                    # Start all services
make ps                    # Verify services are healthy

# 2. Make your changes
# Edit code in your preferred editor
# Services auto-reload on file changes

# 3. Test your changes
make smoke                 # Quick health checks
make e2e                   # Full workflow tests

# 4. Database changes (if needed)
make migrate               # Apply Symfony migrations
make status                # Check migration status

# 5. Update documentation
make export-openapi        # Export updated API specs

# 6. Monitor and debug
make logs                  # All service logs
make logs-user             # User service logs
make logs-notif            # Notification service logs
make logs-gw               # Gateway logs

# 7. Clean shutdown
make down                  # Stop and cleanup
```

### **Hot Reloading**
- **PHP (Symfony)**: Changes reflected immediately
- **Node.js (Express)**: Automatic restart with nodemon
- **Nginx**: Configuration changes require container restart
- **Docker**: Rebuild required for Dockerfile changes

### **Database Development**
```bash
# Create new migration (user-service)
docker compose -f infra/docker-compose.yml exec user-service \
  php bin/console doctrine:migrations:generate

# Apply migrations
make migrate

# Check migration status
make status

# Access databases directly
mysql -h localhost -P 3307 -u symfony -p userdb      # User DB (password: symfony)
mysql -h localhost -P 3308 -u node -p notifdb        # Notification DB (password: node)

# Advanced database operations
docker compose -f infra/docker-compose.yml exec user-service php bin/console doctrine:migrations:list
docker compose -f infra/docker-compose.yml exec user-service php bin/console doctrine:migrations:execute --up VERSION
docker compose -f infra/docker-compose.yml exec user-service php bin/console doctrine:migrations:execute --down VERSION
docker compose -f infra/docker-compose.yml exec user-service php bin/console doctrine:schema:validate
docker compose -f infra/docker-compose.yml exec user-service php bin/console doctrine:database:create --if-not-exists

# Database backup and restore
docker compose -f infra/docker-compose.yml exec user-db mysqldump -u root -p userdb > user_backup.sql
docker compose -f infra/docker-compose.yml exec notif-db mysqldump -u root -p notifdb > notif_backup.sql
docker compose -f infra/docker-compose.yml exec -T user-db mysql -u root -p userdb < user_backup.sql
docker compose -f infra/docker-compose.yml exec -T notif-db mysql -u root -p notifdb < notif_backup.sql
```

### **Service Endpoints**
For URLs and documentation links, see `README.md`:
- Access points: `README.md` > [Access Services](README.md#4-access-services)
- Swagger UIs and OpenAPI JSON: `README.md` > [API Documentation](README.md#api-documentation)

### **API Documentation**
| Documentation | URL | Description |
|---------------|-----|-------------|
| **User API** | http://localhost:8082/users/docs | Swagger UI via Gateway |
| **Notification API** | http://localhost:8082/notifications/docs | Swagger UI via Gateway |
| **OpenAPI JSON** | http://localhost:8082/users/docs.json | Raw OpenAPI spec |
| **OpenAPI JSON** | http://localhost:8082/notifications/docs.json | Raw OpenAPI spec |

### **Complete Development Command Reference**

#### **Container Operations**
```bash
# Start specific services only
docker compose -f infra/docker-compose.yml up user-service notification-service
docker compose -f infra/docker-compose.yml up user-db notif-db
docker compose -f infra/docker-compose.yml up rabbitmq

# Stop specific services
docker compose -f infra/docker-compose.yml stop user-service
docker compose -f infra/docker-compose.yml stop notification-service

# Restart services after code changes
docker compose -f infra/docker-compose.yml restart user-service
docker compose -f infra/docker-compose.yml restart notification-service

# Rebuild services after Dockerfile changes
docker compose -f infra/docker-compose.yml build --no-cache user-service
docker compose -f infra/docker-compose.yml build --no-cache notification-service

# Scale services for load testing
docker compose -f infra/docker-compose.yml up --scale notification-service=3
docker compose -f infra/docker-compose.yml up --scale user-service=2
```

#### **Development Debugging**
```bash
# Access container shells
docker compose -f infra/docker-compose.yml exec user-service bash
docker compose -f infra/docker-compose.yml exec notification-service bash
docker compose -f infra/docker-compose.yml exec gateway bash

# View real-time logs with timestamps
docker compose -f infra/docker-compose.yml logs -f --timestamps user-service
docker compose -f infra/docker-compose.yml logs -f --timestamps notification-service

# Filter logs by service and time
docker compose -f infra/docker-compose.yml logs --since="1h" user-service
docker compose -f infra/docker-compose.yml logs --until="2023-01-01T12:00:00" notification-service

# Monitor container resource usage
docker stats user-service notification-service api-gateway
docker compose -f infra/docker-compose.yml top
```

#### **Service-Specific Commands**

##### **User Service (Symfony/PHP)**
```bash
# Symfony development commands
docker compose -f infra/docker-compose.yml exec user-service php bin/console list
docker compose -f infra/docker-compose.yml exec user-service php bin/console debug:router
docker compose -f infra/docker-compose.yml exec user-service php bin/console debug:container
docker compose -f infra/docker-compose.yml exec user-service php bin/console debug:config

# Cache management
docker compose -f infra/docker-compose.yml exec user-service php bin/console cache:clear
docker compose -f infra/docker-compose.yml exec user-service php bin/console cache:warmup
docker compose -f infra/docker-compose.yml exec user-service php bin/console cache:pool:clear cache.app

# Composer operations
docker compose -f infra/docker-compose.yml exec user-service composer install --no-dev --optimize-autoloader
docker compose -f infra/docker-compose.yml exec user-service composer update
docker compose -f infra/docker-compose.yml exec user-service composer dump-autoload -o
docker compose -f infra/docker-compose.yml exec user-service composer require package/name
docker compose -f infra/docker-compose.yml exec user-service composer remove package/name

# PHP debugging
docker compose -f infra/docker-compose.yml exec user-service php -v
docker compose -f infra/docker-compose.yml exec user-service php -m
docker compose -f infra/docker-compose.yml exec user-service php -i
```

##### **Notification Service (Node.js/Express)**
```bash
# Node.js development commands
docker compose -f infra/docker-compose.yml exec notification-service node --version
docker compose -f infra/docker-compose.yml exec notification-service npm --version
docker compose -f infra/docker-compose.yml exec notification-service npm list

# Package management
docker compose -f infra/docker-compose.yml exec notification-service npm install
docker compose -f infra/docker-compose.yml exec notification-service npm update
docker compose -f infra/docker-compose.yml exec notification-service npm audit
docker compose -f infra/docker-compose.yml exec notification-service npm audit fix
docker compose -f infra/docker-compose.yml exec notification-service npm install package-name
docker compose -f infra/docker-compose.yml exec notification-service npm uninstall package-name

# Application operations
docker compose -f infra/docker-compose.yml exec notification-service npm start
docker compose -f infra/docker-compose.yml exec notification-service npm run dev
docker compose -f infra/docker-compose.yml exec notification-service npm test
docker compose -f infra/docker-compose.yml exec notification-service npm run lint
```

#### **Message Queue Operations**
```bash
# RabbitMQ management
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl status
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_queues
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_exchanges
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_bindings
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_connections
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_channels

# Queue operations
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl purge_queue notification_queue
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl delete_queue notification_queue

# User and permission management
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl list_users
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl add_user newuser password
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl set_user_tags newuser administrator
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqctl set_permissions -p / newuser ".*" ".*" ".*"

# Message testing
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqadmin publish exchange=notifications routing_key=created payload='{"test":"message"}'
docker compose -f infra/docker-compose.yml exec rabbitmq rabbitmqadmin get queue=notification_queue
```

#### **API Testing and Development**
```bash
# Health checks
curl -i http://localhost:8082/health
curl -i http://localhost:8080/health
curl -i http://localhost:8081/health
curl -i http://localhost:8080/ready
curl -i http://localhost:8081/ready

# User API testing
curl -X GET http://localhost:8082/api/users
curl -X POST http://localhost:8082/api/users -H "Content-Type: application/json" -d '{"name":"Test User","email":"test@example.com"}'
curl -X GET http://localhost:8082/api/users/1
curl -X PUT http://localhost:8082/api/users/1 -H "Content-Type: application/json" -d '{"name":"Updated User","email":"updated@example.com"}'
curl -X DELETE http://localhost:8082/api/users/1
curl -X POST http://localhost:8082/api/users/2/notify -H "Content-Type: application/json" -d '{"subject":"Test","message":"Hello"}'

# Notification API testing
curl -X GET http://localhost:8082/api/notifications
curl -X POST http://localhost:8082/api/notifications -H "Content-Type: application/json" -d '{"subject":"Test","message":"Hello World","recipientId":1}'
curl -X GET http://localhost:8082/api/notifications/1
curl -X PUT http://localhost:8082/api/notifications/1 -H "Content-Type: application/json" -d '{"subject":"Updated","message":"Updated message"}'
curl -X DELETE http://localhost:8082/api/notifications/1

# Advanced testing
curl -X GET http://localhost:8082/api/users -H "X-Correlation-Id: test-12345"
for i in {1..15}; do curl -s http://localhost:8082/api/users; done  # Rate limiting test
curl -X OPTIONS http://localhost:8082/api/users -H "Origin: http://localhost:3000" -H "Access-Control-Request-Method: GET"  # CORS test
```

#### **Performance and Monitoring**
```bash
# Resource monitoring
docker stats
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
docker system df
docker system df -v

# Network inspection
docker network ls
docker network inspect infra_default
docker compose -f infra/docker-compose.yml exec user-service netstat -tuln
docker compose -f infra/docker-compose.yml exec notification-service netstat -tuln

# Service connectivity testing
docker compose -f infra/docker-compose.yml exec user-service ping notification-service
docker compose -f infra/docker-compose.yml exec notification-service ping user-db
docker compose -f infra/docker-compose.yml exec notification-service ping rabbitmq
```

#### **Volume and Data Management**
```bash
# Volume operations
docker volume ls
docker volume inspect infra_user_db_data
docker volume inspect infra_notif_db_data

# Data backup
docker run --rm -v infra_user_db_data:/data -v $(pwd):/backup alpine tar czf /backup/user_db_backup.tar.gz -C /data .
docker run --rm -v infra_notif_db_data:/data -v $(pwd):/backup alpine tar czf /backup/notif_db_backup.tar.gz -C /data .

# Data restore
docker run --rm -v infra_user_db_data:/data -v $(pwd):/backup alpine tar xzf /backup/user_db_backup.tar.gz -C /data
docker run --rm -v infra_notif_db_data:/data -v $(pwd):/backup alpine tar xzf /backup/notif_db_backup.tar.gz -C /data
```

#### **Maintenance (Cleanup and pruning)**
```bash
# Stop and remove containers, networks, and volumes
docker compose -f infra/docker-compose.yml down -v

# Image and resource cleanup (use with care)
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}"
docker image prune -f
docker container prune -f
docker volume prune -f
docker system prune -af
```

#### **Security Scanning**
```bash
# Image security scanning
docker scout cves infra-user-service
docker scout cves infra-notification-service

# Update base images
docker compose -f infra/docker-compose.yml pull
docker compose -f infra/docker-compose.yml build --no-cache
```

#### **Environment Configuration**
```bash
# View environment variables
docker compose -f infra/docker-compose.yml exec user-service env
docker compose -f infra/docker-compose.yml exec notification-service env

# Override environment variables for testing
APP_ENV=dev docker compose -f infra/docker-compose.yml up user-service
PORT=3001 docker compose -f infra/docker-compose.yml up notification-service
DATABASE_URL=mysql://test:test@user-db:3306/testdb docker compose -f infra/docker-compose.yml up user-service
```

---

## 📏 Coding Guidelines

### **Microservices Principles**
- **Service Independence**: Each service owns its data and business logic
- **Database per Service**: No shared databases between services
- **API-First Design**: Services communicate only through well-defined APIs
- **Idempotency**: Operations should be safe to retry
- **Graceful Degradation**: Handle service failures elegantly

### **API Design Standards**
- **RESTful URLs**: Use resource-based URLs (`/users`, `/notifications`)
- **HTTP Methods**: GET (read), POST (create), PUT (update), DELETE (remove)
- **Status Codes**: Use appropriate HTTP status codes
- **Content-Type**: Always specify `application/json` for JSON APIs
- **Error Responses**: Consistent error format with correlation IDs

### **Code Quality Requirements**
- **Input Validation**: Validate all inputs at service boundaries
- **Error Handling**: Comprehensive error handling with meaningful messages
- **Logging**: Structured logging with correlation IDs
- **Health Checks**: Every service must have `/health` and `/ready` endpoints
- **Documentation**: OpenAPI/Swagger annotations for all endpoints

### **Database Guidelines**
- **Migrations**: Use Symfony migrations for schema changes
- **Indexes**: Add appropriate database indexes for performance
- **Constraints**: Use database constraints for data integrity
- **Transactions**: Use database transactions for multi-step operations

### **Security Considerations**
- **Input Sanitization**: Sanitize all user inputs
- **SQL Injection**: Use parameterized queries
- **Rate Limiting**: Implement appropriate rate limiting
- **CORS**: Configure CORS properly for web clients

---

## 📝 Commit Message Format

We use [Conventional Commits](https://www.conventionalcommits.org/) for consistent and semantic commit messages.

### **Format Structure**
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### **Commit Types**
| Type | Purpose | Example |
|------|---------|----------|
| **feat** | New feature | `feat(user-service): add user profile endpoints` |
| **fix** | Bug fix | `fix(gateway): resolve CORS configuration issue` |
| **docs** | Documentation | `docs(readme): update installation instructions` |
| **style** | Code formatting | `style(notification): fix code formatting` |
| **refactor** | Code restructuring | `refactor(user): extract validation logic` |
| **test** | Testing | `test(e2e): add notification workflow test` |
| **chore** | Maintenance | `chore(deps): update Docker base images` |
| **ci** | CI/CD changes | `ci: improve GitHub Actions workflow` |

### **Scope Guidelines**
| Scope | Description | Example |
|-------|-------------|----------|
| **user-service** | User service changes | `feat(user-service): add password reset` |
| **notification-service** | Notification service | `fix(notification-service): handle queue errors` |
| **gateway** | API Gateway (Nginx) | `feat(gateway): add request logging` |
| **infra** | Infrastructure/Docker | `chore(infra): update MySQL to 8.0.35` |
| **ci** | CI/CD pipeline | `ci: add security scanning step` |
| **docs** | Documentation | `docs: improve troubleshooting guide` |

### **Good Commit Examples**
```bash
# Feature with detailed description
feat(user-service): implement user profile management

Add endpoints for user profile CRUD operations:
- GET /users/{id}/profile
- PUT /users/{id}/profile
- Includes validation and error handling

Closes #123

# Bug fix with reproduction steps
fix(gateway): resolve rate limiting bypass issue

Rate limiting was not applied to /health endpoints.
Now all endpoints respect the 10 req/s limit.

Fixes #456

# Breaking change
feat(notification)!: change notification payload format

BREAKING CHANGE: notification payload now includes timestamp
and priority fields. Update clients accordingly.
```

---

## ✅ Code Review Checklist

### **Before Submitting PR**
- [ ] **Code Quality**
  - [ ] Code follows project coding guidelines
  - [ ] No code duplication or unnecessary complexity
  - [ ] Proper error handling and input validation
  - [ ] Meaningful variable and function names

- [ ] **Testing**
  - [ ] All tests pass locally (`make smoke && make e2e`)
  - [ ] New features include appropriate tests
  - [ ] Edge cases are covered
  - [ ] No breaking changes to existing tests

- [ ] **Documentation**
  - [ ] README updated if behavior changes
  - [ ] API documentation reflects changes
  - [ ] Code comments explain complex logic
  - [ ] OpenAPI specs updated for API changes

- [ ] **Security & Performance**
  - [ ] No sensitive information in code/logs
  - [ ] Input validation and sanitization
  - [ ] No performance regressions
  - [ ] Database queries are optimized

- [ ] **Standards Compliance**
  - [ ] Commit messages follow format standards
  - [ ] PR description is clear and complete
  - [ ] Related issues are referenced
  - [ ] CI/CD pipeline passes

### **For Reviewers**

#### **🔍 Functionality Review**
- [ ] **Problem Solving**: Code addresses the stated requirements
- [ ] **Edge Cases**: Handles boundary conditions and error scenarios
- [ ] **Business Logic**: Implements requirements correctly
- [ ] **Data Flow**: Information flows correctly between components

#### **🏗️ Architecture Review**
- [ ] **Service Boundaries**: Maintains proper service independence
- [ ] **Data Consistency**: No cross-service database dependencies
- [ ] **API Design**: Follows RESTful principles and conventions
- [ ] **Scalability**: Design supports horizontal scaling

#### **💎 Code Quality Review**
- [ ] **Readability**: Code is clear and self-documenting
- [ ] **Maintainability**: Easy to modify and extend
- [ ] **Performance**: No obvious performance bottlenecks
- [ ] **Security**: Follows security best practices

#### **🧪 Testing Review**
- [ ] **Test Coverage**: Adequate test coverage for new code
- [ ] **Test Quality**: Tests are meaningful and maintainable
- [ ] **Integration**: Services work together correctly
- [ ] **Regression**: No existing functionality is broken

#### **📚 Documentation Review**
- [ ] **API Docs**: OpenAPI specifications are accurate
- [ ] **Code Comments**: Complex logic is explained
- [ ] **User Docs**: README and guides are updated
- [ ] **Architecture**: Diagrams reflect current state

## Docs
- Export OpenAPI: `make export-openapi` (outputs to `docs/`).
- Postman collection: `docs/postman/collection.json` (gateway URLs).

## Tests
- Smoke/E2E: `make smoke`, `make e2e`.
- CI runs both on PRs and pushes (see `.github/workflows/ci.yml`).

## Optional: RabbitMQ
- A RabbitMQ service is available in Compose. Not required for current flows.
- If you add async flows, document routing keys/queues and update README.

---

## 🔄 Pull Request Process

### **PR Guidelines**
- **Size**: Keep PRs focused and under 400 lines of changes
- **Title**: Use conventional commit format (`feat(scope): description`)
- **Description**: Clear explanation of changes and motivation
- **Issues**: Reference related issues (`Fixes #123`, `Closes #456`)
- **Documentation**: Update docs when behavior changes
- **Evidence**: Include screenshots, test results, or reproduction steps

### **PR Workflow**
1. **Create Feature Branch**: `git checkout -b feat/your-feature-name`
2. **Make Changes**: Implement your feature or fix
3. **Test Locally**: Run `make smoke && make e2e`
4. **Commit**: Use conventional commit messages
5. **Push**: `git push origin feat/your-feature-name`
6. **Create PR**: Use the template below
7. **Address Reviews**: Respond to feedback promptly
8. **Merge**: Squash and merge when approved

### **PR Template**
```markdown
## 📝 Description
Brief description of what this PR does and why.

## 🔄 Type of Change
- [ ] 🐛 Bug fix (non-breaking change that fixes an issue)
- [ ] ✨ New feature (non-breaking change that adds functionality)
- [ ] 💥 Breaking change (fix or feature that causes existing functionality to change)
- [ ] 📚 Documentation update
- [ ] 🔧 Refactoring (no functional changes)
- [ ] 🚀 CI/CD changes

## 🧪 Testing
- [ ] `make smoke` passes
- [ ] `make e2e` passes
- [ ] Manual testing performed: _describe what you tested_
- [ ] New tests added for new functionality

## 📋 Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated (README, API docs, etc.)
- [ ] Tests added/updated
- [ ] No breaking changes (or clearly documented)
- [ ] Related issues referenced

## 📸 Screenshots/Evidence
_Include screenshots, logs, or other evidence of testing_

## 🔗 Related Issues
Fixes #issue_number
```

---

## 🆘 Getting Help

### **Before Asking for Help**
1. **Check Documentation**: Review README.md and this contributing guide
2. **Search Issues**: Look for similar problems in GitHub issues
3. **Test Locally**: Run `make smoke && make e2e` to verify your setup
4. **Check Logs**: Use `make logs` to see service logs

### **Where to Get Help**
- **GitHub Issues**: For bugs, feature requests, and questions
- **GitHub Discussions**: For general questions and community support
- **CI Logs**: Check GitHub Actions for detailed error information
- **Documentation**: README.md has comprehensive troubleshooting

### **When Reporting Issues**
Include this information:
- **Environment**: OS, Docker version, etc.
- **Steps to Reproduce**: Exact commands you ran
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happened
- **Logs**: Relevant log output from `make logs`
- **Screenshots**: If applicable

### **Quick Troubleshooting**
```bash
# Check service health
make ps

# View all logs
make logs

# Restart everything
make down && make up

# Verify tests pass
make smoke && make e2e

# Check port conflicts
netstat -tulpn | grep -E ':(8080|8081|8082|3307|3308|5672|15672)'
```

---

## 🎯 Summary

Thank you for contributing to this microservices architecture project! By following these guidelines, you help maintain code quality and make the project better for everyone.

**Key Points to Remember:**
- ✅ Follow the development workflow
- ✅ Write comprehensive tests
- ✅ Use conventional commit messages
- ✅ Keep PRs focused and well-documented
- ✅ Ask for help when needed

Happy coding! 🚀
