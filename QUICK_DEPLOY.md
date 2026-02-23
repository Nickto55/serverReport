# Быстрый старт ServerReport

## Установка проекта

### 1. Установка backend (через setup_website.sh)

```bash
cd website
./setup_website.sh
```

Скрипт спросит:
- **URL репозитория backend** (с Express.js сервером)
- **Имя главного HTML файла** (обычно `index.html`)

### 2. Размещение статических файлов

Разместите ваши HTML/CSS/JS файлы в директории `website/public/`:

```
website/public/
├── index.html       # Главный файл
├── css/
│   └── style.css
└── js/
    └── app.js
```

### 3. Настройка .env файлов

**website/.env** - настройки backend:
```env
PORT=3000
NODE_ENV=production
MAIN_HTML=index.html
DATABASE_URL=postgresql://...
JWT_SECRET=...
```

**docker/.env** - настройки для Docker:
```env
DB_USER=serverreport
DB_PASSWORD=serverreport_pass
DISCORD_TOKEN=ваш_токен
TELEGRAM_TOKEN=ваш_токен
```

### 4. Запуск через Docker

```bash
cd docker
docker-compose build --no-cache
docker-compose up -d
```

### 5. Проверка

Откройте в браузере:
- **http://ваш-сервер/** - основной сайт через nginx
- **http://ваш-сервер/api/health** - проверка работы API
- **http://ваш-сервер/api/debug/public-files** - список файлов в public

## Изменение главной страницы

Если нужно изменить главный HTML файл:

1. Отредактируйте `website/.env`:
```env
MAIN_HTML=home.html
```

2. Перезапустите контейнер:
```bash
cd docker
docker-compose restart website
```

## Структура проекта

### Backend репозиторий
```
backend/
├── package.json
├── server.js
├── db.js
├── routes/
│   ├── auth.js
│   ├── admin.js
│   └── reports.js
├── middleware/
│   └── auth.js
└── public/           # Статические файлы HTML/CSS/JS
    ├── index.html
    ├── css/
    └── js/
```

## Полезные команды

```bash
# Просмотр логов
docker-compose logs website -f

# Перезапуск сервисов
docker-compose restart

# Остановка всех сервисов
docker-compose down

# Полная пересборка
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```
