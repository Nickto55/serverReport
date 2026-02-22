#!/bin/bash

# Quick deploy updated files to server

SERVER="root@144.31.166.109"
PROJECT_DIR="serverReport"

echo "Отправка обновленных файлов на сервер..."
echo ""

# Отправляем обновленные Dockerfiles
echo "→ Отправка Dockerfiles..."
scp website/Dockerfile ${SERVER}:${PROJECT_DIR}/website/
scp discord-bot/Dockerfile ${SERVER}:${PROJECT_DIR}/discord-bot/
scp telegram-bot/Dockerfile ${SERVER}:${PROJECT_DIR}/telegram-bot/

# Отправляем обновленный docker-compose.yml
echo "→ Отправка docker-compose.yml..."
scp docker/docker-compose.yml ${SERVER}:${PROJECT_DIR}/docker/

# Отправляем обновленный setup.sh
echo "→ Отправка setup.sh..."
scp setup.sh ${SERVER}:${PROJECT_DIR}/

echo ""
echo "✓ Все файлы отправлены!"
echo ""
echo "Теперь на сервере выполните:"
echo "  cd serverReport/docker"
echo "  docker-compose build"
echo "  docker-compose up -d"
