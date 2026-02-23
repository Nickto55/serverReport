# Website - Технические требования

## Описание

Express.js веб-приложение (REST API) для управления пользователями и отчетами. Работает с PostgreSQL через Docker контейнер.

## Зависимости

- **Node.js**: 18+
- **npm**: 8+
- **PostgreSQL**: 15+ (контейнер `postgres`)

## Обязательные npm пакеты

```json
{
  "express": "^4.18.2",
  "pg": "^8.11.3",
  "bcryptjs": "^2.4.3",
  "jsonwebtoken": "^9.0.2",
  "dotenv": "^16.3.1",
  "cors": "^2.8.5",
  "helmet": "^7.1.0"
}
```

## Структура проекта

```
website/
├── setup_website.sh   # Установка из Git
├── server.js          # Главный файл
├── db.js              # Подключение к БД
├── package.json
├── middleware/
│   └── auth.js
└── routes/
    ├── auth.js
    ├── admin.js
    └── reports.js
```

## Конфигурация (.env)

### Обязательные переменные

```env
# Сервер
PORT=3000
NODE_ENV=production

# База данных (обязательно!)
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/serverreport

# JWT (обязательно - должен быть уникальным!)
JWT_SECRET=ваш_секретный_ключ_минимум_32_символа
JWT_EXPIRES_IN=7d

# CORS
CORS_ORIGIN=*
```

**Важно:** 
- `DATABASE_URL` должен указывать на контейнер `postgres`
- `JWT_SECRET` должен быть надежным и уникальным (генерируется автоматически при установке)

## База данных

### Требования

1. **PostgreSQL 15+** в контейнере `postgres`
2. База данных: `serverreport`
3. Инициализация через `database/init.sql` (автоматически при первом запуске)

### Необходимые таблицы

- `users` - пользователи
- `reports` - отчеты
- `comments` - комментарии
- `attachments` - вложения
- `discord_integrations` - Discord интеграция
- `telegram_integrations` - Telegram интеграция

### Подключение из кода

```javascript
const { Pool } = require('pg');
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});
```

## Docker

### Зависимости контейнеров

```yaml
website:
  depends_on:
    - postgres  # БД должна запуститься первой
  environment:
    - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/serverreport
```

### Порты

- **3000** - веб-сервер (внешний доступ)
- **5432** - PostgreSQL (внутри Docker сети)

## Безопасность (обязательно!)

1. **Helmet** - защита HTTP заголовков
2. **CORS** - настройка разрешенных источников
3. **Валидация** - проверка всех входных данных
4. **JWT** - аутентификация токенами
5. **Bcrypt** - хеширование паролей (salt rounds ≥ 10)

## Запуск

```bash
# Через manage.sh
./manage.sh → пункт 1

# Проверка работы
curl http://localhost:3000/health
```

## Критичные моменты

### 1. БД должна быть запущена ДО website

```bash
# Проверка
docker ps | grep postgres
```

### 2. DATABASE_URL должен указывать на контейнер

```env
# Правильно
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/serverreport

# Неправильно (localhost не работает в Docker)
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/serverreport
```

### 3. JWT_SECRET обязателен

```bash
# Генерация нового ключа
openssl rand -hex 32
```

### 4. Порт 3000 должен быть свободен

```bash
# Проверка
netstat -tuln | grep 3000
# или
docker ps | grep 3000
```

## Типичные ошибки

| Ошибка | Причина | Решение |
|--------|---------|---------|
| `ECONNREFUSED` | PostgreSQL не запущен | Запустить контейнер `postgres` |
| `jwt malformed` | Нет JWT_SECRET | Добавить в `.env` |
| `Port 3000 in use` | Порт занят | Изменить PORT в `.env` или остановить процесс |
| `relation "users" does not exist` | БД не инициализирована | Пересоздать контейнер postgres |

## Установка проекта

Для установки из Git используйте `setup_website.sh` (см. [README.md](README.md))

