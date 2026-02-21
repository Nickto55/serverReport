# Quick Start Commands

Часто используемые команды для управления проектом ServerReport.

## 🚀 Первый запуск

### Linux/macOS

```bash
# Сделать скрипты исполняемыми
chmod +x setup.sh manage.sh

# Запустить установку
./setup.sh

# Следовать инструкциям скрипта
```

### Windows

```batch
# Просто запустите батники
setup.bat
manage.bat
```

---

## 📋 Основные команды управления

### Запуск/Остановка сервисов

```bash
# Запустить все сервисы
./manage.sh start
# или
manage.bat start

# Остановить сервисы
./manage.sh stop
# или
manage.bat stop

# Перезагрузить сервисы
./manage.sh restart
# или
manage.bat restart

# Просмотреть статус
./manage.sh status
# или
manage.bat status
```

### Логи

```bash
# Все логи (Ctrl+C для выхода)
./manage.sh logs
manage.bat logs

# Логи конкретного сервиса
./manage.sh logs website
./manage.sh logs postgres
./manage.sh logs discord
./manage.sh logs telegram

manage.bat logs website
manage.bat logs postgres
manage.bat logs discord
manage.bat logs telegram
```

### Доступ к сервисам

```bash
# PostgreSQL shell
./manage.sh db-shell
manage.bat db-shell

# Shell контейнера
./manage.sh shell website
./manage.sh shell postgres
./manage.sh shell discord
./manage.sh shell telegram

manage.bat shell website
manage.bat shell postgres
manage.bat shell discord
manage.bat shell telegram
```

---

## 🔧 Сборка и настройка

```bash
# Собрать Docker образы
./manage.sh build
manage.bat build

# Пересобрать образы без кэша
./manage.sh rebuild
manage.bat rebuild

# Установить npm зависимости локально
./manage.sh install-deps
manage.bat install-deps

# Проверка здоровья сервисов
./manage.sh health-check
manage.bat health-check
```

---

## 💾 База данных

### Резервные копии

```bash
# Создать резервную копию
./manage.sh backup-db
manage.bat backup-db

# Восстановить из резервной копии
./manage.sh restore-db backups/serverreport_20260222_120000.sql
manage.bat restore-db backups\serverreport_20260222_120000.sql
```

### Подключение к БД

```bash
# PostgreSQL shell
./manage.sh db-shell
manage.bat db-shell

# Или через Docker напрямую
cd docker
docker-compose exec postgres psql -U serverreport -d serverreport

# Полезные команды в psql:
# \dt                 - Список таблиц
# \d users            - Описание таблицы users
# SELECT * FROM users;  - Выбрать всех пользователей
# \q                  - Выход
```

---

## 🐳 Docker Compose команды

```bash
# Войти в директорию docker
cd docker

# Запустить в фоне
docker-compose up -d

# Остановить
docker-compose down

# Просмотреть логи
docker-compose logs -f

# Логи конкретного сервиса
docker-compose logs -f website
docker-compose logs -f postgres
docker-compose logs -f discord-bot
docker-compose logs -f telegram-bot

# Статус контейнеров
docker-compose ps

# Выполнить команду в контейнере
docker-compose exec website npm run dev
docker-compose exec postgres psql -U serverreport -d serverreport

# Пересобрать образы
docker-compose build

# Пересобрать без кэша
docker-compose build --no-cache

# Удалить контейнеры (данные сохраняются)
docker-compose down

# Удалить всё включая данные
docker-compose down -v
```

---

## 🌐 Веб-приложение

```bash
# Откройте в браузере
http://localhost:3000

# Health check
curl http://localhost:3000/health

# Регистрация
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'

# Вход
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# Получить токен из ответа и использовать его:
TOKEN="your_jwt_token_here"

# Создать отчёт
curl -X POST http://localhost:3000/api/reports \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Bug Report",
    "description": "Description of the bug",
    "category": "bug",
    "priority": "high"
  }'

# Получить отчёты
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/reports
```

---

## 🔍 Решение проблем

### Проверить запущенные контейнеры

```bash
docker ps
docker ps -a  # Включая остановленные

# Или через manage скрипт
./manage.sh status
manage.bat status
```

### Просмотреть логи ошибок

```bash
# Все логи
./manage.sh logs
manage.bat logs

# Логи конкретного сервиса
./manage.sh logs website
./manage.sh logs postgres

manage.bat logs website
manage.bat logs postgres
```

### Проверить здоровье

```bash
./manage.sh health-check
manage.bat health-check
```

### Убедиться, что порты свободны

```bash
# Linux/macOS
lsof -i :3000    # Проверить порт 3000
lsof -i :5432    # Проверить порт 5432

# Windows (PowerShell)
netstat -ano | findstr :3000
netstat -ano | findstr :5432

# Убить процесс (Linux/macOS)
kill -9 <PID>

# Убить процесс (Windows PowerShell)
Stop-Process -Id <PID> -Force
```

### Переустановить всё с нуля

```bash
# Остановить и удалить всё
./manage.sh clean-all
# или
manage.bat clean

# Удалить .env файл (опционально)
rm config/.env

# Запустить setup заново
./setup.sh
# или
setup.bat
```

---

## 🎯 Типичный рабочий день

```bash
# Утром - запустить сервисы
./manage.sh start

# Во время работы - смотреть логи
./manage.sh logs

# Проверить конкретный сервис
./manage.sh logs website

# Подключиться к БД
./manage.sh db-shell

# Вечером - остановить сервисы
./manage.sh stop

# Перед отпуском - создать резервную копию
./manage.sh backup-db
```

---

## 📚 Дополнительные ресурсы

- [INSTALLATION.md](INSTALLATION.md) - Полное руководство установки
- [DEVELOPMENT.md](DEVELOPMENT.md) - Разработка и локальный запуск
- [API_REFERENCE.md](API_REFERENCE.md) - Документация API
- [README.md](README.md) - Обзор проекта

---

## 💡 Совет

Добавьте скрипты в PATH для удобства:

```bash
# Linux/macOS
# Добавьте в ~/.bashrc или ~/.zshrc:
export PATH="/path/to/serverreport:$PATH"

# Затем используйте сокращённые команды:
setup.sh
manage.sh start
manage.sh logs
```

---

**Готово!** ✨ Используйте эти команды для управления вашим ServerReport проектом.
