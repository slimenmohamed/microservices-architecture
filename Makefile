.PHONY: build up down ps logs logs-user logs-notif logs-gw migrate status smoke e2e export-openapi render-diagrams
.PHONY: restart-gw restart-user restart-notif restart-all
.PHONY: gw-config-test
.PHONY: scale-user scale-notif scale-reporting

COMPOSE=cd infra && docker compose

build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down -v

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f --tail=200

logs-user:
	$(COMPOSE) logs -f --tail=200 user-service

logs-notif:
	$(COMPOSE) logs -f --tail=200 notification-service

logs-gw:
	$(COMPOSE) logs -f --tail=200 gateway

migrate:
	$(COMPOSE) exec user-service php bin/console doctrine:migrations:migrate --no-interaction || true

status:
	$(COMPOSE) exec user-service php bin/console doctrine:migrations:status || true

smoke:
	bash scripts/smoke.sh

e2e:
	bash scripts/e2e.sh

export-openapi:
	bash scripts/export-openapi.sh

render-diagrams:
	bash scripts/render-diagrams.sh

# Convenience restarts
restart-gw:
	$(COMPOSE) restart gateway

restart-user:
	$(COMPOSE) restart user-service

restart-notif:
	$(COMPOSE) restart notification-service

restart-all:
	$(COMPOSE) restart

# Validate Nginx gateway configuration inside the container
gw-config-test:
	$(COMPOSE) exec gateway nginx -t -c /etc/nginx/nginx.conf

# Horizontal scaling helpers (use REPL=<n>, default 1)
REPL ?= 1
scale-user:
	$(COMPOSE) up -d --scale user-service=$(REPL)

scale-notif:
	$(COMPOSE) up -d --scale notification-service=$(REPL)

scale-reporting:
	$(COMPOSE) up -d --scale reporting-service=$(REPL)
