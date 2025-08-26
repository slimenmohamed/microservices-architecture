.PHONY: build up down ps logs logs-user logs-notif logs-gw migrate status smoke e2e

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
