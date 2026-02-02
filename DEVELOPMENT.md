# Development Guide

This guide will help you set up the ServerReport project for development.

## Prerequisites

- Node.js 18+ (for local development)
- PostgreSQL 15+ (for database)
- Discord Bot Token (for Discord bot)
- Telegram Bot Token (for Telegram bot)
- Docker and Docker Compose (for containerized development)

## Quick Setup with Docker

The easiest way to get started is with Docker Compose:

```bash
# Copy environment template
cp config/.env.example config/.env

# Edit the .env file and add your bot tokens
nano config/.env

# Start all services
cd docker
docker-compose up -d

# View logs
docker-compose logs -f
```

## Local Development Setup

If you want to run components locally:

### 1. Database Setup

```bash
# Start PostgreSQL
# Option 1: Using Docker
docker run --name serverreport-db -e POSTGRES_PASSWORD=serverreport_pass -e POSTGRES_USER=serverreport -e POSTGRES_DB=serverreport -p 5432:5432 -d postgres:15-alpine

# Option 2: Using local PostgreSQL
psql -U postgres -c "CREATE DATABASE serverreport;"
psql -U postgres serverreport < database/init.sql
```

### 2. Website Development

```bash
cd website

# Install dependencies
npm install

# Create .env file
cat > .env << EOF
DATABASE_URL=postgresql://serverreport:serverreport_pass@localhost:5432/serverreport
JWT_SECRET=your_jwt_secret_key_change_this
PORT=3000
NODE_ENV=development
EOF

# Run development server
npm run dev

# The website will be available at http://localhost:3000
```

### 3. Discord Bot Development

```bash
cd discord-bot

# Install dependencies
npm install

# Create .env file
cat > .env << EOF
DISCORD_TOKEN=your_discord_bot_token
DATABASE_URL=postgresql://serverreport:serverreport_pass@localhost:5432/serverreport
NODE_ENV=development
EOF

# Run bot
npm run dev
```

### 4. Telegram Bot Development

```bash
cd telegram-bot

# Install dependencies
npm install

# Create .env file
cat > .env << EOF
TELEGRAM_TOKEN=your_telegram_bot_token
DATABASE_URL=postgresql://serverreport:serverreport_pass@localhost:5432/serverreport
NODE_ENV=development
EOF

# Run bot
npm run dev
```

## Environment Variables

### Shared Variables
- `NODE_ENV` - Set to `development` for local development
- `DATABASE_URL` - PostgreSQL connection string

### Website Variables
- `PORT` - Server port (default: 3000)
- `JWT_SECRET` - Secret key for JWT tokens

### Discord Bot Variables
- `DISCORD_TOKEN` - Your Discord bot token

### Telegram Bot Variables
- `TELEGRAM_TOKEN` - Your Telegram bot token

## API Testing

### Register User
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "testpass123"
  }'
```

### Login User
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpass123"
  }'
```

### Create Report
```bash
curl -X POST http://localhost:3000/api/reports \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "title": "Test Report",
    "description": "This is a test report for development",
    "category": "bug",
    "priority": "medium"
  }'
```

### Get Reports
```bash
curl http://localhost:3000/api/reports \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Database Queries

Connect to database directly:
```bash
# Using Docker
docker exec -it serverreport-db psql -U serverreport -d serverreport

# Using local PostgreSQL
psql -U serverreport -d serverreport
```

Useful queries:
```sql
-- View all users
SELECT * FROM users;

-- View all reports
SELECT * FROM reports;

-- View reports by status
SELECT * FROM reports WHERE status = 'open';

-- View bot integrations
SELECT * FROM discord_integrations;
SELECT * FROM telegram_integrations;
```

## Debugging

### Website Debug
```bash
cd website
DEBUG=* npm run dev
```

### Discord Bot Debug
Enable debug logs in bot.js:
```javascript
const client = new Client({
  intents: [...],
  debug: true,  // Add this
});
```

### View Docker Logs
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs website
docker-compose logs discord-bot
docker-compose logs telegram-bot
docker-compose logs postgres

# Follow logs
docker-compose logs -f website
```

## Common Issues

### Database Connection Failed
- Check PostgreSQL is running: `docker ps`
- Verify DATABASE_URL is correct
- Ensure database exists: `psql -U serverreport -d serverreport -c "SELECT 1;"`

### Bot Tokens Not Working
- Verify tokens are correct in .env
- Check bot has required permissions in Discord/Telegram
- Restart bot after changing tokens

### Port Already in Use
```bash
# Find process using port 3000
lsof -i :3000

# Kill process
kill -9 <PID>
```

## Testing

### Run Tests
```bash
# Website
cd website
npm test

# Discord Bot
cd discord-bot
npm test

# Telegram Bot
cd telegram-bot
npm test
```

## Building Docker Images

```bash
cd docker

# Build all images
docker-compose build

# Build specific service
docker-compose build website
docker-compose build discord-bot
docker-compose build telegram-bot
```

## Production Deployment

For production deployment:

1. Update `.env` with production values
2. Set `NODE_ENV=production`
3. Use strong JWT_SECRET and bot tokens
4. Enable HTTPS
5. Set up proper database backups
6. Monitor logs and metrics

See deployment documentation for more details.

## Contributing

1. Create a branch: `git checkout -b feature/my-feature`
2. Make changes and commit: `git commit -am 'Add feature'`
3. Push to branch: `git push origin feature/my-feature`
4. Submit a pull request

## Resources

- [Discord.js Documentation](https://discord.js.org)
- [Telegraf Documentation](https://telegraf.js.org)
- [Express.js Documentation](https://expressjs.com)
- [PostgreSQL Documentation](https://www.postgresql.org/docs)
