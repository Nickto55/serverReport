# ServerReport

A comprehensive reporting system with website, Discord bot, and Telegram bot integration for managing user reports across multiple platforms.

## 🎯 Features

### Website
- User registration and authentication
- Report creation and management
- Admin dashboard with statistics
- User role management
- Report status tracking

### Discord Bot
- Create and manage reports via Discord
- Check report status
- User integration with Discord accounts
- Command-based interface

### Telegram Bot
- Create reports via Telegram
- Check report status
- List user reports
- Full report management

### Database
- PostgreSQL database with comprehensive schema
- User management
- Report tracking
- Integration management
- Comment system

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Node.js 18+ (for local development)
- PostgreSQL credentials

### Installation

1. Clone the repository
```bash
git clone <repo-url>
cd serverreport
```

2. Set up environment variables
```bash
cp config/.env.example config/.env
```

3. Edit the `.env` file with your configuration:
```bash
# Add your Discord and Telegram tokens
DISCORD_TOKEN=your_discord_bot_token
TELEGRAM_TOKEN=your_telegram_bot_token
JWT_SECRET=your_jwt_secret_key
```

4. Start the application with Docker Compose
```bash
cd docker
docker-compose up -d
```

The application will be available at:
- Website: http://localhost:3000
- Database: localhost:5432

## 📁 Project Structure

```
serverreport/
├── website/              # Express.js website
│   ├── routes/          # API routes
│   ├── middleware/      # Authentication middleware
│   ├── server.js        # Main server file
│   └── package.json
├── discord-bot/         # Discord.js bot
│   ├── commands/        # Discord commands
│   ├── events/          # Event handlers
│   ├── bot.js          # Bot entry point
│   └── package.json
├── telegram-bot/        # Telegraf bot
│   ├── commands/        # Telegram commands
│   ├── scenes/          # Conversation scenes
│   ├── bot.js          # Bot entry point
│   └── package.json
├── database/            # Database schemas
│   └── init.sql        # Initial database setup
├── docker/              # Docker configuration
│   └── docker-compose.yml
└── config/              # Configuration files
    └── .env.example
```

## 🔑 API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login

### Reports
- `POST /api/reports` - Create report
- `GET /api/reports` - Get user's reports
- `GET /api/reports/:id` - Get report details
- `PUT /api/reports/:id` - Update report
- `DELETE /api/reports/:id` - Delete report

### Admin
- `GET /api/admin/users` - Get all users
- `GET /api/admin/reports` - Get all reports
- `PUT /api/admin/reports/:reportId/status` - Update report status
- `GET /api/admin/stats` - Get system statistics

## 🤖 Discord Bot Commands

- `!report` - Create a new report
- `!status <id>` - Check report status

## 📱 Telegram Bot Commands

- `/start` - Initialize bot
- `/report` - Create a new report
- `/status <id>` - Check report status
- `/list` - List your reports
- `/help` - Show help message

## 🔒 Environment Variables

See `config/.env.example` for all available configuration options.

## 📝 Development

For local development without Docker:

1. Set up PostgreSQL database
2. Install dependencies in each directory:
```bash
cd website && npm install
cd ../discord-bot && npm install
cd ../telegram-bot && npm install
```

3. Run each component:
```bash
npm run dev  # in each directory
```

## 🐛 Troubleshooting

### Database connection issues
- Ensure PostgreSQL is running
- Check DATABASE_URL in environment variables
- Verify PostgreSQL credentials

### Bot tokens not working
- Verify Discord/Telegram bot tokens are correct
- Check bot has required permissions
- Ensure tokens are set in environment variables

## 📄 License

[Your License Here]

## 👥 Contributors

- Initial implementation team