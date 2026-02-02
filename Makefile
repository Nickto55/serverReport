.PHONY: help setup dev-up dev-down dev-logs dev-clean build pull ps shell-website shell-db shell-discord shell-telegram install test lint clean

help:
	@echo "ServerReport - Makefile Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make setup              - Initial project setup"
	@echo ""
	@echo "Docker Development:"
	@echo "  make dev-up             - Start all services"
	@echo "  make dev-down           - Stop all services"
	@echo "  make dev-logs           - View logs from all services"
	@echo "  make dev-logs-website   - View website logs"
	@echo "  make dev-logs-discord   - View Discord bot logs"
	@echo "  make dev-logs-telegram  - View Telegram bot logs"
	@echo "  make dev-logs-db        - View database logs"
	@echo "  make dev-clean          - Stop and remove all containers"
	@echo ""
	@echo "Docker Management:"
	@echo "  make build              - Build all Docker images"
	@echo "  make pull               - Pull base images"
	@echo "  make ps                 - Show running containers"
	@echo ""
	@echo "Shell Access:"
	@echo "  make shell-db           - Connect to database"
	@echo "  make shell-website      - Access website container"
	@echo "  make shell-discord      - Access Discord bot container"
	@echo "  make shell-telegram     - Access Telegram bot container"
	@echo ""
	@echo "Local Development:"
	@echo "  make install            - Install all dependencies"
	@echo "  make dev                - Start local development servers"
	@echo "  make test               - Run all tests"
	@echo "  make lint               - Run linters"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean              - Remove all node_modules and build artifacts"

setup:
	@echo "Setting up ServerReport..."
	@cp config/.env.example config/.env
	@echo "✅ .env file created. Please edit it with your bot tokens."
	@echo "Edit config/.env and then run: make dev-up"

install:
	@echo "Installing dependencies..."
	@cd website && npm install
	@cd ../discord-bot && npm install
	@cd ../telegram-bot && npm install
	@echo "✅ Dependencies installed"

dev-up:
	@echo "Starting Docker services..."
	@cd docker && docker-compose up -d
	@echo "✅ Services started"
	@sleep 3
	@make ps

dev-down:
	@echo "Stopping Docker services..."
	@cd docker && docker-compose down
	@echo "✅ Services stopped"

dev-logs:
	@cd docker && docker-compose logs -f

dev-logs-website:
	@cd docker && docker-compose logs -f website

dev-logs-discord:
	@cd docker && docker-compose logs -f discord-bot

dev-logs-telegram:
	@cd docker && docker-compose logs -f telegram-bot

dev-logs-db:
	@cd docker && docker-compose logs -f postgres

dev-clean:
	@echo "Cleaning up Docker resources..."
	@cd docker && docker-compose down -v
	@echo "✅ Cleaned up"

build:
	@echo "Building Docker images..."
	@cd docker && docker-compose build
	@echo "✅ Build complete"

pull:
	@echo "Pulling base images..."
	@docker pull node:18-alpine
	@docker pull postgres:15-alpine
	@echo "✅ Images pulled"

ps:
	@cd docker && docker-compose ps

shell-db:
	@docker exec -it serverreport-db psql -U serverreport -d serverreport

shell-website:
	@docker exec -it serverreport-website /bin/sh

shell-discord:
	@docker exec -it serverreport-discord-bot /bin/sh

shell-telegram:
	@docker exec -it serverreport-telegram-bot /bin/sh

dev:
	@echo "Starting local development servers..."
	@echo "Make sure PostgreSQL is running on localhost:5432"
	@echo "Starting in parallel (use separate terminals for better logs):"
	@echo "1. cd website && npm run dev"
	@echo "2. cd discord-bot && npm run dev"
	@echo "3. cd telegram-bot && npm run dev"

test:
	@echo "Running tests..."
	@cd website && npm test
	@cd ../discord-bot && npm test
	@cd ../telegram-bot && npm test

lint:
	@echo "Running linters..."
	@cd website && npm run lint 2>/dev/null || echo "No linter configured for website"
	@cd ../discord-bot && npm run lint 2>/dev/null || echo "No linter configured for discord-bot"
	@cd ../telegram-bot && npm run lint 2>/dev/null || echo "No linter configured for telegram-bot"

clean:
	@echo "Cleaning up..."
	@rm -rf website/node_modules
	@rm -rf discord-bot/node_modules
	@rm -rf telegram-bot/node_modules
	@rm -rf website/package-lock.json
	@rm -rf discord-bot/package-lock.json
	@rm -rf telegram-bot/package-lock.json
	@echo "✅ Cleaned"

.DEFAULT_GOAL := help
