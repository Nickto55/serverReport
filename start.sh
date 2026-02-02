#!/bin/bash

echo "🚀 ServerReport Setup Script"
echo "============================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"

# Create .env if it doesn't exist
if [ ! -f "config/.env" ]; then
    echo "📝 Creating .env file from template..."
    cp config/.env.example config/.env
    echo "⚠️  Please edit config/.env and add your Discord and Telegram tokens"
else
    echo "✅ .env file already exists"
fi

# Navigate to docker directory
cd docker

# Start services
echo "🔄 Starting services..."
docker-compose up -d

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 10

# Check if services are running
echo ""
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "✅ Setup complete!"
echo ""
echo "Services are now running:"
echo "  🌐 Website: http://localhost:3000"
echo "  📊 Database: localhost:5432"
echo "  🤖 Discord Bot: Running (logs: docker-compose logs discord-bot)"
echo "  📱 Telegram Bot: Running (logs: docker-compose logs telegram-bot)"
echo ""
echo "Next steps:"
echo "1. Edit config/.env with your tokens if not done already"
echo "2. Access the website at http://localhost:3000"
echo "3. Register a user account"
echo "4. Create your first report!"
