.PHONY: build up down ps logs logs-user logs-notif logs-gw migrate status smoke e2e export-openapi render-diagrams
.PHONY: restart-gw restart-user restart-notif restart-all
.PHONY: gw-config-test
.PHONY: scale-user scale-notif scale-reporting help

COMPOSE = cd infra && docker compose
REPL ?= 1

## -----------------------------
## Build & lifecycle
## -----------------------------
build: ## Build all images
	$(COMPOSE) build

up: ## Start all services in detached mode
	$(COMPOSE) up -d --build

down: ## Stop and remove all containers + volumes
	$(COMPOSE) down -v

ps: ## Show running containers
	$(COMPOSE) ps

## -----------------------------
## Logs
## -----------------------------
logs: ## Tail logs from all services
	$(COMPOSE) logs -f --tail=200

logs-user: ## Tail logs from user-service
	$(COMPOSE) logs -f --tail=200 user-service

logs-notif: ## Tail logs from notification-service
	$(COMPOSE) logs -f --tail=200 notification-service

logs-gw: ## Tail logs from gateway
	$(COMPOSE) logs -f --tail=200 gateway

## -----------------------------
## Database migrations
## -----------------------------
migrate: ## Run database migrations
	$(COMPOSE) exec user-service php bin/console doctrine:migrations:migrate --no-interaction || true

status: ## Show migration status
	$(COMPOSE) exec user-service php bin/console doctrine:migrations:status || true

## -----------------------------
## Tests
## -----------------------------
smoke: ## Run smoke tests
	bash scripts/smoke.sh

e2e: ## Run end-to-end tests
	bash scripts/e2e.sh

## -----------------------------
## Docs & diagrams
## -----------------------------
export-openapi: ## Export OpenAPI specs
	bash scripts/export-openapi.sh

render-diagrams: ## Render diagrams
	bash scripts/render-diagrams.sh

## -----------------------------
## Restart helpers
## -----------------------------
restart-gw: ## Restart gateway
	$(COMPOSE) restart gateway

restart-user: ## Restart user-service
	$(COMPOSE) restart user-service

restart-notif: ## Restart notification-service
	$(COMPOSE) restart notification-service

restart-all: ## Restart all services
	$(COMPOSE) restart

## -----------------------------
## Gateway config validation
## -----------------------------
gw-config-test: ## Test Nginx config inside gateway container
	$(COMPOSE) exec gateway nginx -t -c /etc/nginx/nginx.conf

gw-build-conf: ## Generate gateway config from template (uses GW_RATE_LIMIT, GW_BURST)
	@which envsubst >/dev/null 2>&1 || { echo "envsubst is required (install gettext-base)" >&2; exit 1; }
	@echo "Generating infra/nginx/conf.d/default.conf from template..."
	@GW_RATE_LIMIT="$${GW_RATE_LIMIT:-100r/s}" GW_BURST="$${GW_BURST:-200}" \
		envsubst < infra/nginx/conf.d/default.conf.template > infra/nginx/conf.d/default.conf
	@echo "Wrote infra/nginx/conf.d/default.conf"

## -----------------------------
## Scaling
## -----------------------------
scale-user: ## Scale user-service (use REPL=<n>)
	$(COMPOSE) up -d --scale user-service=$(REPL)

scale-notif: ## Scale notification-service (use REPL=<n>)
	$(COMPOSE) up -d --scale notification-service=$(REPL)

scale-reporting: ## Scale reporting-service (use REPL=<n>)
	$(COMPOSE) up -d --scale reporting-service=$(REPL)

## -----------------------------
## Help
## -----------------------------
help: ## Show available targets
	@echo "Available make targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
