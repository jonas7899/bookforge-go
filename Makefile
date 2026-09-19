## feature/temp/2026-04-25_19-32-43

.PHONY: dev build-backend build-frontend build \
	logs logs-postgres logs-prod ps ps-prod check \
	docker_dev-up docker_dev-down docker_prod-up docker_prod-down docker-clean refresh-dev \
	db-up db-down db-reset db-console db-diagram \
	migrate-up migrate-down migrate-status migrate-prod-up migrate-prod-status migrate-create \
	dev-backup-db prod-backup-db \
	dev-reset-db dev-reinit-db dev-restore-db \
	prod-reset-db prod-reinit-db prod-restore-db \
	db-seed db-seed-prod \
	git-new-branch git-return-to-main git-drop-feature \
	test test-unit test-integration \
	test-integration-auth test-integration-health test-integration-user \
	test-integration-org test-integration-members test-integration-invitations test-integration-apikeys \
	vulncheck setup info help

# Default target
.DEFAULT_GOAL := help

## ============================================
## ENVIRONMENT - Load .env for Make variables
## ============================================
## Egységes konfiguráció mindkét környezetben: 05_config/.env
## Dev:  05_config/.env  (lokális fejlesztés)
## Prod: 05_config/.env  (szerveren ugyanitt)
-include 05_config/.env
export

## Docker Compose env file flag — dev és prod azonos
ENV_FILE := --env-file 05_config/.env

## Backup könyvtár és timestamp
BACKUP_DIR := backups
TIMESTAMP  := $(shell date +%Y%m%d_%H%M%S)

## .env értékek kiolvasása - a recepteken belül használjuk őket, hogy 
## biztosan a shell kezelje az idézőjeleket és speciális karaktereket.
## (Lásd: _backup, _restore, _seed, _migrate_step definiálása lent)

_DB_USER   := $(shell grep '^DB_USER='   05_config/.env | cut -d= -f2- | tr -d '"' | tr -d "'")
_DB_PASS   := $(shell grep '^DB_PASSWORD=' 05_config/.env | cut -d= -f2- | tr -d '"' | tr -d "'")
_DB_PORT   := $(shell grep '^DB_PORT='   05_config/.env | cut -d= -f2- | tr -d '"' | tr -d "'")
_DB_HOST   := $(shell grep '^DB_HOST='   05_config/.env | cut -d= -f2- | tr -d '"' | tr -d "'")
_DB_NAME   := $(shell grep '^DB_NAME='   05_config/.env | cut -d= -f2- | tr -d '"' | tr -d "'")
_DB_SCHEMA := $(shell grep '^DB_SCHEMA=' 05_config/.env | cut -d= -f2- | tr -d '"' | tr -d "'")

## ============================================
## Colors for output
## ============================================
CYAN   := \033[0;36m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
PURPLE := \033[0;35m
RED    := \033[0;31m
RESET  := \033[0m


# ============================================
# Initial project setup
# ============================================

setup: ## Initial project setup (submodules + deps)
	@printf "$(YELLOW) Setting up project... $(RESET)\n"
	(cd 02_backend && go mod download)
	(cd 03_frontend_htmx && go mod download)
	@printf "$(GREEN) ✓ Setup complete! $(RESET)\n"


# ============================================
# Development settings
# ============================================

dev: docker_dev-up ## Start dev infrastructure + wait for healthy
	@printf "$(GREEN)✓ Development environment is ready!$(RESET)\n"
	@printf "$(CYAN)Backend:$(RESET)  http://localhost:$(API_PORT)\n"
	@printf "$(CYAN)Frontend:$(RESET) http://localhost:$(FRONTEND_PORT)\n"

build-backend: ## Build backend Docker image
	@if [ -z "$(GITHUB_TOKEN)" ]; then echo "$(RED)Error: GITHUB_TOKEN is not set in 05_config/.env!$(RESET)"; exit 1; fi
	@printf "$(YELLOW) Building backend Docker image... $(RESET)\n"
	docker buildx build --build-arg GITHUB_TOKEN=$(GITHUB_TOKEN) -t bookforge-backend -f docker/backend/Dockerfile .
	@printf "$(GREEN)✓ Backend Docker image built!$(RESET)\n"

build-frontend: ## Build frontend Docker image
	@if [ -z "$(GITHUB_TOKEN)" ]; then echo "$(RED)Error: GITHUB_TOKEN is not set in 05_config/.env!$(RESET)"; exit 1; fi
	@printf "$(YELLOW) Building frontend Docker image... $(RESET)\n"
	docker buildx build --build-arg GITHUB_TOKEN=$(GITHUB_TOKEN) -t bookforge-frontend -f docker/frontend/Dockerfile .
	@printf "$(GREEN)✓ Frontend Docker image built!$(RESET)\n"

build: build-backend build-frontend ## Build all images
	@printf "$(GREEN)✓ All images built!$(RESET)\n"


# ============================================
# Docker diagnostics
# ============================================

logs: ## Follow logs — dev
	@printf "$(YELLOW) Following dev logs... $(RESET)\n"
	docker compose -f compose.dev.yaml $(ENV_FILE) logs -f

logs-prod: ## Follow logs — prod
	@printf "$(YELLOW) Following prod logs... $(RESET)\n"
	docker compose -f compose.prod.yaml $(ENV_FILE) logs -f

logs-postgres: ## Follow PostgreSQL logs only
	docker compose -f compose.dev.yaml $(ENV_FILE) logs -f bookforge-postgres

ps: ## List running containers — dev
	@printf "$(YELLOW) Listing dev containers... $(RESET)\n"
	docker compose -f compose.dev.yaml $(ENV_FILE) ps
	@printf "$(GREEN)✓ Done!$(RESET)\n"

ps-prod: ## List running containers — prod
	@printf "$(YELLOW) Listing prod containers... $(RESET)\n"
	docker compose -f compose.prod.yaml $(ENV_FILE) ps
	@printf "$(GREEN)✓ Done!$(RESET)\n"

check: ## Check all services — press Ctrl+C to exit
	@printf "$(YELLOW) Checking if all services are running... $(RESET)\n"
	docker stats
	@printf "$(GREEN)✓ All services are running!$(RESET)\n"


# ============================================
# Docker dev mode
# ============================================

docker_dev-up: ## Start all services in dev mode
	@printf "$(YELLOW) Starting all services in dev mode... $(RESET)\n"
	docker compose -f compose.dev.yaml $(ENV_FILE) up -d
	@printf "$(GREEN)✓ All services started in dev mode!$(RESET)\n"

docker_dev-down: ## Stop all dev mode services
	@printf "$(YELLOW) Stopping all services in dev mode... $(RESET)\n"
	docker compose -f compose.dev.yaml $(ENV_FILE) down
	@printf "$(GREEN)✓ All services stopped in dev mode!$(RESET)\n"


# ============================================
# Docker prod mode
# ============================================

docker_prod-up: ## Start all services in prod mode
	@printf "$(YELLOW) Starting all services in prod mode... $(RESET)\n"
	docker compose -f compose.prod.yaml $(ENV_FILE) up -d
	@printf "$(GREEN)✓ All services started in prod mode!$(RESET)\n"

docker_prod-down: ## Stop all prod mode services
	@printf "$(YELLOW) Stopping all services in prod mode... $(RESET)\n"
	docker compose -f compose.prod.yaml $(ENV_FILE) down
	@printf "$(GREEN)✓ All services stopped in prod mode!$(RESET)\n"


# ============================================
# Docker cleanup
# ============================================

docker-clean: ## Remove all containers and volumes — USE WITH CAUTION
	@printf "$(RED)Removing containers and volumes! Is that really what you want? [y/N] (5 sec)$(RESET)\n"
	@read -t 5 ANSWER; \
	ANSWER=$${ANSWER:-n}; \
	if [ "$$ANSWER" = "y" ]; then \
		printf "$(RED)Deleting...$(RESET)\n"; \
		docker compose -f compose.dev.yaml $(ENV_FILE) down -v; \
		printf "$(RED)Deleted$(RESET)\n"; \
	else \
		printf "$(GREEN)Left it!$(RESET)\n"; \
	fi

refresh-dev: ## Full rebuild + restart dev (base images cached)
	@printf "$(YELLOW)Stopping dev environment...$(RESET)\n"
	docker compose -f compose.dev.yaml $(ENV_FILE) down
	@printf "$(YELLOW)Removing custom images...$(RESET)\n"
	docker rmi bookforge-backend:latest bookforge-frontend:latest 2>/dev/null || true
	@printf "$(YELLOW)Rebuilding backend image...$(RESET)\n"
	$(MAKE) build-backend
	@printf "$(YELLOW)Rebuilding frontend image...$(RESET)\n"
	$(MAKE) build-frontend
	@printf "$(YELLOW)Starting dev environment...$(RESET)\n"
	$(MAKE) docker_dev-up
	@printf "$(YELLOW)Waiting for database to be ready...$(RESET)\n"
	@until docker exec bookforge-postgres pg_isready -q 2>/dev/null; do sleep 1; done
	@printf "$(YELLOW)Running database migrations...$(RESET)\n"
	$(MAKE) migrate-up
	@printf "$(YELLOW)Verifying image hashes...$(RESET)\n"
	@printf "Container: "; docker inspect bookforge-frontend --format '{{.Image}}'
	@printf "Local:     "; docker inspect bookforge-frontend:latest --format '{{.Id}}'
	@printf "\n$(GREEN)✓ refresh-dev complete!$(RESET)\n"


# ============================================
# Database shortcuts
# ============================================

db-up: ## Start only PostgreSQL + Redis
	@printf "$(YELLOW) Starting database services... $(RESET)\n"
	docker compose -f compose.dev.yaml $(ENV_FILE) up -d bookforge-postgres bookforge-redis
	@printf "$(GREEN)✓ Database services started!$(RESET)\n"

db-down: ## Stop database services
	@printf "$(YELLOW) Stopping database services... $(RESET)\n"
	docker compose -f compose.dev.yaml $(ENV_FILE) stop bookforge-postgres bookforge-redis
	@printf "$(GREEN)✓ Database services stopped!$(RESET)\n"

db-reset: ## Reset database (destroy volume + restart)
	@printf "$(RED)This will destroy all database data! [y/N] (5 sec)$(RESET)\n"
	@read -t 5 ANSWER; \
	ANSWER=$${ANSWER:-n}; \
	if [ "$$ANSWER" = "y" ]; then \
		printf "$(RED)Resetting database...$(RESET)\n"; \
		docker compose -f compose.dev.yaml $(ENV_FILE) stop bookforge-postgres; \
		docker volume rm bookforge_postgres_data 2>/dev/null || true; \
		docker compose -f compose.dev.yaml $(ENV_FILE) up -d bookforge-postgres; \
		printf "$(GREEN)✓ Database reset! Run 'make migrate-up' next.$(RESET)\n"; \
	else \
		printf "$(GREEN)Left it!$(RESET)\n"; \
	fi

db-console: ## Open psql console
	docker exec -it bookforge-postgres psql \
		-U $(_DB_USER) -d $(_DB_NAME) \
		-P pager=off

db-diagram: ## Generate PlantUML ER diagram from the database
	@printf "$(YELLOW) Generating database diagram... $(RESET)\n"
	@mkdir -p 01_docs/diagrams/src
	@DB_IP=$$(docker inspect bookforge-postgres --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || echo "localhost"); \
	 U="$$(grep '^DB_USER='     05_config/.env | cut -d= -f2- | tr -d '"' | tr -d "'")"; \
	 P="$$(grep '^DB_PASSWORD=' 05_config/.env | cut -d= -f2- | tr -d '"' | tr -d "'")"; \
	 D="$$(grep '^DB_NAME='     05_config/.env | cut -d= -f2- | tr -d '"' | tr -d "'")"; \
	 S="$$(grep '^DB_SCHEMA='   05_config/.env | cut -d= -f2- | tr -d '"' | tr -d "'")"; \
	 P_ENC=$$(echo "$$P" | python3 -c "import urllib.parse as p; import sys; print(p.quote(sys.stdin.read().strip(), safe=''))"); \
	 planter -s $$S "postgres://$$U:$$P_ENC@$$DB_IP:5432/$$D?sslmode=disable" > 01_docs/diagrams/src/schema_base.puml
	@printf "$(GREEN)✓ Diagram generated in 01_docs/diagrams/src/schema.puml$(RESET)\n"


# ============================================
# Database migrations
# ============================================

COMPOSE_MIGRATE      = docker compose -f compose.dev.yaml  $(ENV_FILE) --profile tools run --rm bookforge-migrate
COMPOSE_MIGRATE_PROD = docker compose -f compose.prod.yaml $(ENV_FILE) --profile tools run --rm bookforge-migrate

migrate-up: ## Run database migrations (dev)
	@printf "$(YELLOW) Running database migrations... $(RESET)\n"
	@U="$$(grep '^DB_USER='     05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 P="$$(grep '^DB_PASSWORD=' 05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 D="$$(grep '^DB_NAME='     05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 DB_USER="$$U" DB_PASSWORD="$$P" DB_NAME="$$D" \
	 docker compose -f compose.dev.yaml $(ENV_FILE) --profile migrate run --rm bookforge-migrate up
	@printf "$(GREEN)✓ Migrations applied!$(RESET)\n"

migrate-down: ## Rollback last migration (dev)
	@printf "$(YELLOW) Rolling back last migration... $(RESET)\n"
	@U="$$(grep '^DB_USER='     05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 P="$$(grep '^DB_PASSWORD=' 05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 D="$$(grep '^DB_NAME='     05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 DB_USER="$$U" DB_PASSWORD="$$P" DB_NAME="$$D" \
	 docker compose -f compose.dev.yaml $(ENV_FILE) --profile migrate run --rm bookforge-migrate down
	@printf "$(GREEN)✓ Last migration rolled back!$(RESET)\n"

migrate-status: ## Check migration status (dev)
	@printf "$(YELLOW) Checking migration status... $(RESET)\n"
	@U="$$(grep '^DB_USER='     05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 P="$$(grep '^DB_PASSWORD=' 05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 D="$$(grep '^DB_NAME='     05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 DB_USER="$$U" DB_PASSWORD="$$P" DB_NAME="$$D" \
	 docker compose -f compose.dev.yaml $(ENV_FILE) --profile migrate run --rm bookforge-migrate status

migrate-prod-up: ## Run database migrations (prod)
	@printf "$(YELLOW) Running PROD database migrations... $(RESET)\n"
	@U="$$(grep '^DB_USER='   05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 P="$$(grep '^DB_PASSWORD=' 05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 D="$$(grep '^DB_NAME='   05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 DB_USER="$$U" DB_PASSWORD="$$P" DB_NAME="$$D" \
	 docker compose -f compose.prod.yaml $(ENV_FILE) --profile migrate run --rm bookforge-migrate up
	@printf "$(GREEN)✓ Prod migrations applied!$(RESET)\n"

migrate-prod-status: ## Check migration status (prod)
	@printf "$(YELLOW) Checking PROD migration status... $(RESET)\n"
	@U="$$(grep '^DB_USER='     05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 P="$$(grep '^DB_PASSWORD=' 05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 D="$$(grep '^DB_NAME='     05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 DB_USER="$$U" DB_PASSWORD="$$P" DB_NAME="$$D" \
	 docker compose -f compose.prod.yaml $(ENV_FILE) --profile migrate run --rm bookforge-migrate status

migrate-create: ## Create a new migration file (usage: make migrate-create name=my_migration)
	@if [ -z "$(name)" ]; then \
		echo "$(RED)Error: name is required. Usage: make migrate-create name=my_migration$(RESET)"; \
		exit 1; \
	fi
	@printf "$(YELLOW) Creating new migration: $(name)... $(RESET)\n"
	goose -dir 02_backend/migrations create "$(name)" sql
	@printf "$(GREEN)✓ Migration file created!$(RESET)\n"


## ============================================
## DB backup / restore / reinit
## ============================================
##
## FONTOS: A DB_PASSWORD tartalmazhat # karaktert, amit a Make kommentnek
## értelmez. Ezért a jelszót mindig shell subshell-ben olvassuk ki:
##   DB_PASS="$$(grep '^DB_PASSWORD=' 05_config/.env | cut -d= -f2-)"
## — így a Make soha nem látja a # karaktert.
##
## Backup: pg_dump --data-only --schema=$(_DB_SCHEMA) | gzip → backups/*.sql.gz
##   - pg_dump kimenetét először temp fájlba írjuk, majd gzip-eljük
##     (így a pipefail probléma elkerülhető és a fájlméret ellenőrizhető)
##   - created_at / updated_at megőrzése: INSERT-ek eredeti értékekkel
##   - Fájlnév tartalmaz timestampet, backups/ könyvtár nem törlődik
##   - Sikertelenség esetén: hibaüzenet + kézi instrukció, NEM automatikus rollback
##
## Backup segédfüggvény (compose fájl, fájlnév)
## pg_dump → temp fájl → gzip (pipefail elkerülése)
define _backup
	@mkdir -p $(BACKUP_DIR)
	@printf "$(YELLOW) Adatok mentése: $(BACKUP_DIR)/$(2) ...$(RESET)\n"
	@U="$$(grep '^DB_USER=' 05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 D="$$(grep '^DB_NAME=' 05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 S="$$(grep '^DB_SCHEMA=' 05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 TMPFILE="/tmp/pg_backup_$(2).sql"; \
	docker exec bookforge-postgres pg_dump \
		-U $$U -d $$D --schema=$$S \
		--data-only --no-owner --no-privileges \
		> "$$TMPFILE" \
	&& [ -s "$$TMPFILE" ] \
	&& gzip -c "$$TMPFILE" > "$(BACKUP_DIR)/$(2)" \
	&& rm -f "$$TMPFILE" \
	&& printf "$(GREEN)✓ Backup kész$(RESET)\n" \
	|| { rm -f "$$TMPFILE" "$(BACKUP_DIR)/$(2)"; exit 1; }
endef

## ============================================
## Volume reset segédfüggvény (compose fájl)
## ============================================
define _volume_reset
	@printf "$(YELLOW) Stack leállítása...$(RESET)\n"
	docker compose -f $(1) $(ENV_FILE) down -v
	@printf "$(YELLOW) Stack indítása (postgres + redis)...$(RESET)\n"
	docker compose -f $(1) $(ENV_FILE) up -d bookforge-postgres bookforge-redis
	@printf "$(YELLOW) Várakozás az init-db.sh befejezésére (schema létezés)...$(RESET)\n"
	@P="$$(grep '^DB_PASSWORD=' 05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 until docker exec bookforge-postgres \
	     psql -U $(_DB_USER) -d $(_DB_NAME) \
	     -c "SELECT 1 FROM information_schema.schemata WHERE schema_name='$(_DB_SCHEMA)';" \
	     2>/dev/null | grep -q 1; do \
	         printf "."; sleep 3; \
	 done; \
	 printf "\n"
	@printf "$(YELLOW) Jelszó ellenőrzés (prod_user kapcsolat teszt)...$(RESET)\n"
	@P="$$(grep '^DB_PASSWORD=' 05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 if ! PGPASSWORD="$$P" docker exec -e PGPASSWORD="$$P" bookforge-postgres \
	     psql -U $(_DB_USER) -d $(_DB_NAME) -c "SELECT 1;" > /dev/null 2>&1; then \
	     printf "$(RED)✗ prod_user jelszó hiba! Scram-sha-256 fix futtatása...$(RESET)\n"; \
	     docker exec bookforge-postgres \
	         psql -U $(_DB_USER) -d $(_DB_NAME) \
	         -c "ALTER USER $(_DB_USER) WITH PASSWORD '$$P';"; \
	     printf "$(GREEN)✓ Jelszó reset kész$(RESET)\n"; \
	 fi
	@printf "$(GREEN)✓ PostgreSQL kész és hitelesítés OK$(RESET)\n"
endef

## ============================================
## Migrate segédfüggvény (compose fájl, backup fájlnév tájékoztatáshoz)
## ============================================
define _migrate_step
	@printf "$(YELLOW) Migráció futtatása...$(RESET)\n"
	@U="$$(grep '^DB_USER=' 05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 P="$$(grep '^DB_PASSWORD=' 05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 D="$$(grep '^DB_NAME=' 05_config/.env | cut -d= -f2- | tr -d '"')"; \
	docker compose -f $(1) $(ENV_FILE) run --rm \
		-e "DB_USER=$$U" \
		-e "DB_PASSWORD=$$P" \
		-e "DB_NAME=$$D" \
		-e "DATABASE_URL=host=bookforge-postgres port=5432 user=$$U password=$$P dbname=$$D sslmode=disable" \
		bookforge-migrate up \
	&& printf "$(GREEN)✓ Migráció kész$(RESET)\n" \
	|| { printf "$(RED)❌ Migráció sikertelen!$(RESET)\n"; exit 1; }
endef

## ============================================
## Restore segédfüggvény (backup fájl)
## ============================================
define _restore
	@printf "$(YELLOW) Visszatöltés: $(1) ...$(RESET)\n"
	@[ -f "$(1)" ] || { printf "$(RED)❌ Fájl nem található: $(1)$(RESET)\n"; exit 1; }
	@[ -s "$(1)" ] || { printf "$(RED)❌ A backup fájl üres: $(1)$(RESET)\n"; exit 1; }
	gunzip -c $(1) | docker exec -i bookforge-postgres psql \
		-U $(_DB_USER) -d $(_DB_NAME) \
	&& printf "$(GREEN)✓ Visszatöltés kész$(RESET)\n" \
	|| { \
		printf "$(RED)❌ Visszatöltés sikertelen!$(RESET)\n"; \
		printf "$(CYAN)   Kézi: gunzip -c $(1) | docker exec -i bookforge-postgres psql -U $(_DB_USER) -d $(_DB_NAME)$(RESET)\n"; \
		exit 1; \
	}
endef

## ============================================
## Seed segédfüggvény (compose fájl)
## ============================================
## A DB_PASSWORD-ban lévő # karaktert shell subshell-ben olvassuk ki,
## hogy a Make ne értelmezze kommentként
define _seed
	@printf "$(YELLOW) Seed futtatása (--with-subscriber)...$(RESET)\n"
	@U="$$(grep '^DB_USER='     05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 P="$$(grep '^DB_PASSWORD=' 05_config/.env | cut -d= -f2- | tr -d '"')"; \
	 D="$$(grep '^DB_NAME='     05_config/.env | cut -d= -f2- | tr -d '"')"; \
	docker compose -f $(1) $(ENV_FILE) build bookforge-backend \
	&& docker compose -f $(1) $(ENV_FILE) run --rm \
		-e "DB_USER=$$U" \
		-e "DB_PASSWORD=$$P" \
		-e "DB_NAME=$$D" \
		-e "DATABASE_URL=host=bookforge-postgres port=5432 user=$$U password=$$P dbname=$$D sslmode=disable" \
		--entrypoint ./seed \
		bookforge-backend --with-subscriber \
	&& printf "$(GREEN)✓ Seed kész$(RESET)\n" \
	|| { \
		printf "$(RED)❌ Seed sikertelen!$(RESET)\n"; \
		printf "$(CYAN)   Kézi újrafuttatás: make prod-reinit-db$(RESET)\n"; \
		exit 1; \
	}
endef

## Full stack restart segédfüggvény (compose fájl)
define _full_up
	@printf "$(YELLOW) Teljes stack indítása...$(RESET)\n"
	docker compose -f $(1) $(ENV_FILE) up -d \
	&& printf "$(GREEN)✓ Stack fut$(RESET)\n" \
	|| { printf "$(RED)❌ Stack indítás sikertelen!$(RESET)\n"; exit 1; }
endef

# ============================================
# Standalone backup
# ============================================

dev-backup-db: ## DEV: adatok mentése backups/dev_backup_TIMESTAMP.sql.gz
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	@printf "$(PURPLE)  DEV DB BACKUP                          $(RESET)\n"
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	$(call _backup,compose.dev.yaml,dev_backup_$(TIMESTAMP).sql.gz)

prod-backup-db: ## PROD: adatok mentése backups/prod_backup_TIMESTAMP.sql.gz
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	@printf "$(PURPLE)  PROD DB BACKUP                         $(RESET)\n"
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	$(call _backup,compose.prod.yaml,prod_backup_$(TIMESTAMP).sql.gz)

# ============================================
# Standalone seed
# ============================================

db-seed: ## DEV: seed futtatása (--with-subscriber) — DB-nek futnia kell
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	@printf "$(PURPLE)  DEV SEED                               $(RESET)\n"
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	$(call _seed,compose.dev.yaml)

db-seed-prod: ## PROD: seed futtatása (--with-subscriber) — DB-nek futnia kell
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	@printf "$(PURPLE)  PROD SEED                              $(RESET)\n"
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	$(call _seed,compose.prod.yaml)

# ============================================
# DEV reset / reinit
# ============================================

dev-reset-db: ## ⚠️  DEV: backup → volume reset → migrate → restore
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	@printf "$(PURPLE)  DEV DB RESET (backup + restore)        $(RESET)\n"
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	$(call _backup,compose.dev.yaml,dev_backup_$(TIMESTAMP).sql.gz)
	$(call _volume_reset,compose.dev.yaml)
	$(call _migrate_step,compose.dev.yaml,dev_backup_$(TIMESTAMP).sql.gz)
	$(call _restore,$(BACKUP_DIR)/dev_backup_$(TIMESTAMP).sql.gz)
	$(call _full_up,compose.dev.yaml)
	@printf "$(GREEN)✓ DEV reset + restore kész!$(RESET)\n"
	@printf "$(CYAN)  Backup: $(BACKUP_DIR)/dev_backup_$(TIMESTAMP).sql.gz$(RESET)\n"

dev-reinit-db: ## ⚠️  DEV: volume reset → migrate → seed (adatok elvesznek!)
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	@printf "$(PURPLE)  DEV DB REINIT (seed)                   $(RESET)\n"
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	@printf "$(RED)FIGYELEM: az összes adat törlődik! [y/N] $(RESET)"; \
	read ANSWER; \
	if [ "$$ANSWER" != "y" ] && [ "$$ANSWER" != "Y" ]; then \
		printf "$(GREEN)Megszakítva.$(RESET)\n"; exit 0; \
	fi
	$(call _volume_reset,compose.dev.yaml)
	$(call _migrate_step,compose.dev.yaml,-)
	$(call _seed,compose.dev.yaml)
	$(call _full_up,compose.dev.yaml)
	@printf "$(GREEN)✓ DEV reinit kész!$(RESET)\n"

dev-restore-db: ## DEV: kézi restore (usage: make dev-restore-db BACKUP=backups/dev_backup_X.sql.gz)
	@if [ -z "$(BACKUP)" ]; then \
		printf "$(RED)Error: BACKUP paraméter kötelező!$(RESET)\n"; \
		printf "$(CYAN)Usage: make dev-restore-db BACKUP=backups/dev_backup_20260416_120000.sql.gz$(RESET)\n"; \
		exit 1; \
	fi
	$(call _restore,$(BACKUP))

# ============================================
# PROD reset / reinit
# ============================================

prod-reset-db: ## ⚠️  PROD: backup → volume reset → migrate → restore
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	@printf "$(PURPLE)  PROD DB RESET (backup + restore)       $(RESET)\n"
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	$(call _backup,compose.prod.yaml,prod_backup_$(TIMESTAMP).sql.gz)
	$(call _volume_reset,compose.prod.yaml)
	$(call _migrate_step,compose.prod.yaml,prod_backup_$(TIMESTAMP).sql.gz)
	$(call _restore,$(BACKUP_DIR)/prod_backup_$(TIMESTAMP).sql.gz)
	$(call _full_up,compose.prod.yaml)
	@printf "$(GREEN)✓ PROD reset + restore kész!$(RESET)\n"
	@printf "$(CYAN)  Backup: $(BACKUP_DIR)/prod_backup_$(TIMESTAMP).sql.gz$(RESET)\n"

prod-reinit-db: ## ⚠️  PROD: volume reset → migrate → seed (adatok elvesznek!)
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	@printf "$(PURPLE)  PROD DB REINIT (seed)                  $(RESET)\n"
	@printf "$(PURPLE)══════════════════════════════════════════$(RESET)\n"
	@printf "$(RED)FIGYELEM: PROD adatok törlődnek! Írd be: REINIT$(RESET)\n"; \
	read ANSWER; \
	if [ "$$ANSWER" != "REINIT" ]; then \
		printf "$(GREEN)Megszakítva.$(RESET)\n"; exit 0; \
	fi
	$(call _volume_reset,compose.prod.yaml)
	$(call _migrate_step,compose.prod.yaml,-)
	$(call _seed,compose.prod.yaml)
	$(call _full_up,compose.prod.yaml)
	@printf "$(GREEN)✓ PROD reinit kész!$(RESET)\n"

prod-restore-db: ## PROD: kézi restore (usage: make prod-restore-db BACKUP=backups/prod_backup_X.sql.gz)
	@if [ -z "$(BACKUP)" ]; then \
		printf "$(RED)Error: BACKUP paraméter kötelező!$(RESET)\n"; \
		printf "$(CYAN)Usage: make prod-restore-db BACKUP=backups/prod_backup_20260416_120000.sql.gz$(RESET)\n"; \
		exit 1; \
	fi
	$(call _restore,$(BACKUP))


# ============================================
# Testing
# ============================================

test: ## Run all tests (unit + integration)
	@printf "$(YELLOW) Running all tests... $(RESET)\n"
	(cd 02_backend && go test ./... -count=1 -timeout 180s)
	@printf "$(GREEN)✓ All tests passed!$(RESET)\n"

test-unit: ## Run unit tests only (fast, no Docker needed)
	@printf "$(YELLOW) Running unit tests... $(RESET)\n"
	(cd 02_backend && go test $$(go list ./... | grep -v '/tests/integration') -count=1 -timeout 60s)
	@printf "$(GREEN)✓ Unit tests passed!$(RESET)\n"

test-email: ## Send a real test email via SMTP to verify the email service works (set TEST_EMAIL=you@example.com)
	@printf "$(YELLOW) Sending test email via SMTP... $(RESET)\n"
	@if [ -z "$(TEST_EMAIL)" ]; then echo "Usage: make test-email TEST_EMAIL=you@example.com"; exit 1; fi
	(cd 02_backend && go run ./cmd/test-email/main.go $(TEST_EMAIL))
	@printf "$(GREEN)✓ Test email sent — check $(TEST_EMAIL)$(RESET)\n"

test-integration: ## Run all integration tests (requires Docker)
	@printf "$(YELLOW) Running integration tests... $(RESET)\n"
	(cd 02_backend && go test ./tests/integration/... -v -count=1 -timeout 180s)
	@printf "$(GREEN)✓ Integration tests passed!$(RESET)\n"

test-integration-auth: ## Run auth API integration tests only
	@printf "$(YELLOW) Running auth integration tests... $(RESET)\n"
	(cd 02_backend && go test ./tests/integration/... -v -count=1 -timeout 120s -run TestAuthAPI)
	@printf "$(GREEN)✓ Auth integration tests passed!$(RESET)\n"

test-integration-health: ## Run health API integration tests only
	@printf "$(YELLOW) Running health integration tests... $(RESET)\n"
	(cd 02_backend && go test ./tests/integration/... -v -count=1 -timeout 120s -run TestHealthAPI)
	@printf "$(GREEN)✓ Health integration tests passed!$(RESET)\n"

test-integration-user: ## Run user API integration tests only
	@printf "$(YELLOW) Running user integration tests... $(RESET)\n"
	(cd 02_backend && go test ./tests/integration/... -v -count=1 -timeout 120s -run TestUserAPI)
	@printf "$(GREEN)✓ User integration tests passed!$(RESET)\n"

test-integration-org: ## Run organization API integration tests only
	@printf "$(YELLOW) Running org integration tests... $(RESET)\n"
	(cd 02_backend && go test ./tests/integration/... -v -count=1 -timeout 120s -run TestOrganizationAPI)
	@printf "$(GREEN)✓ Org integration tests passed!$(RESET)\n"

test-integration-members: ## Run members API integration tests only
	@printf "$(YELLOW) Running members integration tests... $(RESET)\n"
	(cd 02_backend && go test ./tests/integration/... -v -count=1 -timeout 120s -run TestMembersAPI)
	@printf "$(GREEN)✓ Members integration tests passed!$(RESET)\n"

test-integration-invitations: ## Run invitations API integration tests only
	@printf "$(YELLOW) Running invitations integration tests... $(RESET)\n"
	(cd 02_backend && go test ./tests/integration/... -v -count=1 -timeout 120s -run TestInvitationsAPI)
	@printf "$(GREEN)✓ Invitations integration tests passed!$(RESET)\n"

test-integration-apikeys: ## Run API keys integration tests only
	@printf "$(YELLOW) Running API keys integration tests... $(RESET)\n"
	(cd 02_backend && go test ./tests/integration/... -v -count=1 -timeout 120s -run TestAPIKeysAPI)
	@printf "$(GREEN)✓ API keys integration tests passed!$(RESET)\n"

e2e-test: ## Run headed e2e tests (automated manual tests)
	@printf "$(YELLOW) Running automated e2e tests... $(RESET)\n"
	mkdir -p e2e-testresults
	(cd e2e && PLAYWRIGHT_JSON_OUTPUT=../e2e-testresults/results_$$(date +%Y-%m-%d_%H-%M-%S).json npm test)
	@printf "$(GREEN)✓ automated e2e tests passed!$(RESET)\n"

e2e-headed: ## Run headed e2e tests (interactive, for debugging)
	@printf "$(YELLOW) Running headed e2e tests... $(RESET)\n"
	(cd e2e && npm run test:headed)
	@printf "$(GREEN)✓ automated headed e2e tests passed!$(RESET)\n"

vulncheck: ## Run govulncheck (Go vulnerability scanner)
	@printf "$(YELLOW) Running govulncheck... $(RESET)\n"
	(cd 02_backend && go run golang.org/x/vuln/cmd/govulncheck@latest ./...)
	@printf "$(GREEN)✓ No known vulnerabilities found!$(RESET)\n"

# ============================================
# Git helpers
# ============================================

git-new-branch: ## 1. Új ág létrehozása, feltöltése a GitHubra és upstream beállítása
	@CURRENT_BRANCH=$$(git rev-parse --abbrev-ref HEAD); \
	BRANCH_COUNT=$$(git branch | grep -v "main" | grep -v "master" | wc -l | tr -d ' '); \
	if [ "$$CURRENT_BRANCH" != "main" ] && [ "$$CURRENT_BRANCH" != "master" ]; then \
		echo "HIBA: Csak a main/master ágról indítható új branch!"; \
		exit 1; \
	fi; \
	if [ "$$BRANCH_COUNT" -gt 0 ]; then \
		echo "HIBA: Már létezik egy munkafolyamat ág! Fejezd be vagy töröld azt előbb."; \
		git branch | grep -v "main" | grep -v "master"; \
		exit 1; \
	fi; \
	NEW_BRANCH=feature/temp/$$(date +%Y-%m-%d_%H-%M-%S); \
	echo "Új branch létrehozása: $$NEW_BRANCH"; \
	git checkout -b "$$NEW_BRANCH" && \
	echo "Feltöltés a GitHubra és upstream beállítása..." && \
	git push -u origin "$$NEW_BRANCH"


git-return-to-main: ## 2. SIKERES MUNKA: Merge és takarítás (lokálisan és a GitHubon is)git-return-to-main:
	@CURRENT_BRANCH=$$(git rev-parse --abbrev-ref HEAD); \
	if [ "$$CURRENT_BRANCH" = "main" ] || [ "$$CURRENT_BRANCH" = "master" ]; then \
		echo "HIBA: Már a main ágon vagy!"; \
		exit 1; \
	fi; \
	echo "Visszatérés a main-re és $$CURRENT_BRANCH merge-elése..."; \
	git checkout main && \
	git merge "$$CURRENT_BRANCH" && \
	git push origin main && \
	git branch -d "$$CURRENT_BRANCH"; \
	if git ls-remote --exit-code --heads origin "$$CURRENT_BRANCH" > /dev/null 2>&1; then \
		echo "Sikeres merge után a távoli ág törlése a GitHub-ról..."; \
		git push origin --delete "$$CURRENT_BRANCH"; \
	else \
		echo "A távoli szerveren nem volt fent az ág, a lokális takarítás kész."; \
	fi

git-drop-feature: ## 3. KUDARC: Minden módosítás eldobása és ág kényszerített törlése (lokálisan és a GitHubon is)
	@CURRENT_BRANCH=$$(git rev-parse --abbrev-ref HEAD); \
	if [ "$$CURRENT_BRANCH" = "main" ] || [ "$$CURRENT_BRANCH" = "master" ]; then \
		echo "HIBA: A main ágat nem törölheted!"; \
		exit 1; \
	fi; \
	echo "Módosítások eldobása és ág törlése mindenhonnan: $$CURRENT_BRANCH"; \
	git reset --hard HEAD; \
	git checkout main; \
	git branch -D "$$CURRENT_BRANCH"; \
	if git ls-remote --exit-code --heads origin "$$CURRENT_BRANCH" > /dev/null 2>&1; then \
		echo "Távoli ág törlése a GitHub-ról..."; \
		git push origin --delete "$$CURRENT_BRANCH"; \
	else \
		echo "A távoli szerveren nem található ez az ág, csak lokálisan töröltem."; \
	fi


# ============================================
# Project information
# ============================================

info: ## Show project information
	@printf "$(PURPLE)╔══════════════════════════════════════════════════════╗$(RESET)\n"
	@printf "$(PURPLE)║  Bookforge - Home Library SaaS - Setup               ║$(RESET)\n"
	@printf "$(PURPLE)╚══════════════════════════════════════════════════════╝$(RESET)\n"
	@printf "\n$(YELLOW)Project Structure:$(RESET)\n"
	@printf "  02_backend/         Go API server\n"
	@printf "  03_frontend_htmx/   HTMX frontend\n"
	@printf "  04_common/          Shared libraries\n"
	@printf "\n$(YELLOW)Services:$(RESET)\n"
	@printf "  PostgreSQL:  localhost:$${DB_PORT:-5432}\n"
	@printf "  Redis:       localhost:$${REDIS_PORT:-6379}\n"
	@printf "  Backend API: localhost:$${API_PORT:-8082}\n"
	@printf "  Frontend:    localhost:$${FRONTEND_PORT:-3000}\n"
	@printf "\n$(GREEN)Run 'make help' for all commands$(RESET)\n"


# ============================================
# Help
# ============================================

help: ## Display this help message
	@printf "\n$(PURPLE)Bookforge Home Library SaaS$(RESET)\n\n"
	@printf "$(YELLOW)Usage:$(RESET) make $(CYAN)<target>$(RESET)\n\n"
	@awk 'BEGIN {FS = ":.*?## "} \
		/^# =+$$/ { \
			getline; \
			if ($$0 ~ /^# [^=]/) { \
				title = $$0; sub(/^# +/, "", title); \
				printf "\n\033[33m%s\033[0m\n", title; \
			} \
			next; \
		} \
		/^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 }' \
		$(MAKEFILE_LIST)

	@printf "\n$(PURPLE)Some other useful commands:$(RESET)\n"
	@printf "\n$(YELLOW)Git$(RESET)\n"
	@printf "  $(YELLOW)File history from git:$(RESET)\n"
	@printf "  $(CYAN)git log --oneline -- [filename]$(RESET)\n"
	@printf "\n  $(YELLOW)Commits diff from file history:$(RESET)\n"
	@printf "  $(CYAN)git diff [commit1] [commit2] -- [filename]$(RESET)\n"
	@printf "\n  $(YELLOW)Setup third party tool as diff and merge tool:$(RESET)\n"
	@printf "  $(CYAN)git config diff.tool meld$(RESET)\n"
	@printf "  $(CYAN)git config merge.tool meld$(RESET)\n"
	@printf "\n  $(YELLOW)Using the third party tool as git diff:$(RESET)\n"
	@printf "  $(CYAN)git difftool [commit1] [commit2] -- [filename]$(RESET)\n"
	@printf "\n  $(YELLOW)Quick git commit, comment and push$(RESET)\n"
	@printf "      and at the end of the message, it writes: Auto-save - [timestamp].\n"
	@printf "      The message is optional.\n"
	@printf "  $(CYAN)./git_save.sh {\"Message\"}$(RESET)\n\n"