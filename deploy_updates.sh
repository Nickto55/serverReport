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

# Отправляем обновленные скрипты
echo "→ Отправка скриптов..."
scp setup.sh ${SERVER}:${PROJECT_DIR}/
scp manage.sh ${SERVER}:${PROJECT_DIR}/

# Делаем скрипты исполняемыми на сервере
echo "→ Установка прав на выполнение..."
ssh ${SERVER} "cd ${PROJECT_DIR} && chmod +x setup.sh manage.sh"

echo ""
echo "✓ Все файлы отправлены!"
echo ""
echo "Теперь на сервере выполните:"
echo "  ssh ${SERVER}"
echo "  cd ${PROJECT_DIR}"
echo "  sudo ./setup.sh"
echo ""
