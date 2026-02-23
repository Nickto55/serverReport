# Website Setup - Быстрый старт

## Установка проекта из Git

### Способ 1: Через панель управления (рекомендуется)

```bash
cd /путь/к/serverReport
./manage.sh
# Выбрать: 24 - Настроить проект сайта (Git)
```

### Способ 2: Напрямую

```bash
cd /путь/к/serverReport/website
./setup_website.sh
```

## Примеры URL репозиториев

### Публичный репозиторий (HTTPS)
```
https://github.com/username/project.git
```
✓ Аутентификация не требуется

### Приватный репозиторий (HTTPS + Token)
```
https://github.com/username/project.git
```
При запросе выберите:
1. Personal Access Token
2. Вставьте ваш токен

**Как получить токен:**
- **GitHub**: Settings → Developer settings → Personal access tokens → Generate new token (classic)
  - Требуемые разрешения: `repo` (Full control of private repositories)
- **GitLab**: Settings → Access Tokens → Add new token
  - Требуемые права: `read_repository`
- **Bitbucket**: Settings → App passwords → Create app password
  - Требуемые права: `Repositories: Read`

### SSH репозиторий
```
git@github.com:username/project.git
```

**Настройка SSH ключа:**
```bash
# 1. Создайте SSH ключ
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. Скопируйте публичный ключ
cat ~/.ssh/id_ed25519.pub

# 3. Добавьте в GitHub/GitLab
# GitHub: Settings → SSH and GPG keys → New SSH key
# GitLab: Settings → SSH Keys → Add new key

# 4. Проверьте подключение
ssh -T git@github.com
```

## Процесс установки

Скрипт выполнит следующие шаги:

1. ✓ **Проверка Git** - наличие git в системе
2. ✓ **Проверка доступности репозитория** - подключение к Git
3. ✓ **Аутентификация** - при необходимости (для приватных репозиториев)
4. ✓ **Резервное копирование** - сохранение текущего проекта (опционально)
5. ✓ **Клонирование** - загрузка проекта из Git
6. ✓ **Проверка совместимости**:
   - Наличие `package.json` и `server.js`
   - Валидность JSON в package.json
   - Использование Express.js
   - Наличие зависимостей (express, pg, dotenv)
   - Структура директорий (routes/, middleware/)
7. ✓ **Копирование файлов** - в папку website
8. ✓ **Установка зависимостей** - npm install (опционально)
9. ✓ **Создание .env** - конфигурация по умолчанию

## Требования к проекту

### Обязательные файлы
- ✅ `package.json` - с валидным JSON
- ✅ `server.js` - использующий Express.js

### Рекомендуемые зависимости
- express
- pg (PostgreSQL client)
- dotenv (переменные окружения)
- bcryptjs (хеширование паролей)
- jsonwebtoken (JWT токены)
- cors
- helmet

### Рекомендуемая структура
```
проект/
├── package.json
├── server.js
├── db.js
├── routes/
│   ├── auth.js
│   ├── admin.js
│   └── reports.js
└── middleware/
    └── auth.js
```

## Типичные ошибки

### ❌ "Authentication failed"

**Решение для HTTPS:**
```
1. Используйте Personal Access Token
2. При запросе скрипта выберите опцию 1
3. Вставьте токен (без пробелов)
```

**Решение для SSH:**
```bash
# Убедитесь, что SSH ключ добавлен
ssh-add ~/.ssh/id_ed25519
ssh -T git@github.com
```

### ❌ "Repository not found"

**Проверьте:**
- ✓ Правильность URL
- ✓ Существование репозитория
- ✓ Права доступа (для приватных)

### ❌ "Проект несовместим"

**Убедитесь, что репозиторий содержит:**
- ✓ package.json с валидным JSON
- ✓ server.js с использованием Express
- ✓ Необходимые зависимости

## После установки

1. **Проверьте конфигурацию:**
   ```bash
   nano website/.env
   # Обновите DATABASE_URL, JWT_SECRET при необходимости
   ```

2. **Запустите сервисы:**
   ```bash
   ./manage.sh
   # Выбрать: 1 - Запустить все сервисы
   ```

3. **Проверьте работу:**
   ```bash
   curl http://localhost:3000/health
   # Ожидаемый ответ: {"status":"ok","timestamp":"..."}
   ```

## Документация

Полная документация: [WEBSITE.md](WEBSITE.md)

- API endpoints
- Конфигурация БД
- Docker интеграция
- Безопасность
- Мониторинг и логи
- Производительность
