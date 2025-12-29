.PHONY: help up down stop restart clean-all logs shell migrate test test-clean env ui-install ui-start ui-dev ui-build ui-dev-start backup restore

NEXT_PUBLIC_USER_ID=$(USER)
NEXT_PUBLIC_API_URL=http://localhost:8765

# Default target
help:
	@echo "Available commands:"
	@echo "  make env       - Copy .env.example to .env"
	@echo "  make up        - Start the containers"
	@echo "  make stop      - Stop containers (keeps data)"
	@echo "  make restart   - Restart containers (keeps data)"
	@echo "  make down      - ⚠️  DANGER: Stop containers and DELETE ALL DATA"
	@echo "  make clean     - Clean Docker build cache"
	@echo "  make logs      - Show container logs"
	@echo "  make shell     - Open a shell in the api container"
	@echo "  make migrate   - Run database migrations"
	@echo "  make backup    - Create backup of all data"
	@echo "  make restore   - Restore from backup (interactive)"
	@echo "  make test      - Run tests in a new container"
	@echo "  make test-clean - Run tests and clean up volumes"
	@echo "  make ui-install - Install frontend dependencies"
	@echo "  make ui-start  - Start the frontend development server"
	@echo "  make ui-dev    - Install dependencies and start the frontend in dev mode"
	@echo "  make ui        - Install dependencies and start the frontend in production mode"


env:
	cd api && cp .env.example .env
	cd ui && cp .env.example .env

build:
	docker compose build --no-cache --pull

clean:
	docker builder prune -a

up:
	NEXT_PUBLIC_USER_ID=$(USER) NEXT_PUBLIC_API_URL=$(NEXT_PUBLIC_API_URL) docker compose up

stop:
	docker compose stop

restart:
	docker compose restart

down:
	@echo "⚠️  WARNING: This will DELETE ALL DATA (database + vector storage)!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	docker compose down -v
	rm -f api/openmemory.db
	@echo "✅ All data deleted"

logs:
	docker compose logs -f

shell:
	docker compose exec api bash

upgrade:
	docker compose exec api alembic upgrade head

migrate:
	docker compose exec api alembic upgrade head

downgrade:
	docker compose exec api alembic downgrade -1

backup:
	./backup-scripts/backup_all.sh

restore:
	./backup-scripts/restore_all.sh

ui-dev:
	cd ui && NEXT_PUBLIC_USER_ID=$(USER) NEXT_PUBLIC_API_URL=$(NEXT_PUBLIC_API_URL) pnpm install && pnpm dev
