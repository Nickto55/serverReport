#!/bin/bash

#############################################################################
# ServerReport - Complete Setup Script
# This script handles full project initialization and configuration
#############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#############################################################################
# Helper Functions
#############################################################################

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed"
        return 1
    fi
    print_success "$1 is installed"
    return 0
}

check_port() {
    local port=$1
    local service=$2
    
    if nc -z localhost $port 2>/dev/null; then
        print_warning "Port $port ($service) is already in use"
        return 1
    fi
    return 0
}

read_input() {
    local prompt=$1
    local default=$2
    local var_name=$3
    
    if [ -z "$default" ]; then
        read -p "$(echo -e ${YELLOW}$prompt${NC}): " input
    else
        read -p "$(echo -e ${YELLOW}$prompt${NC}) [${BLUE}$default${NC}]: " input
        input=${input:-$default}
    fi
    
    eval "$var_name='$input'"
}

#############################################################################
# Main Setup
#############################################################################

main() {
    print_header "ServerReport - Complete Setup"
    
    # Step 1: Check prerequisites
    print_header "Step 1: Checking Prerequisites"
    
    local missing_tools=0
    
    if ! check_command docker; then
        missing_tools=$((missing_tools + 1))
    fi
    
    if ! check_command docker-compose; then
        missing_tools=$((missing_tools + 1))
    fi
    
    if ! check_command git; then
        missing_tools=$((missing_tools + 1))
    fi
    
    if [ $missing_tools -gt 0 ]; then
        print_error "Please install missing tools and try again"
        exit 1
    fi
    
    print_success "All prerequisites are installed"
    
    # Step 2: Check ports
    print_header "Step 2: Checking Port Availability"
    
    check_port 3000 "Website" || print_warning "Website port 3000 might conflict"
    check_port 5432 "Database" || print_warning "Database port 5432 might conflict"
    
    # Step 3: Create .env file
    print_header "Step 3: Configuring Environment Variables"
    
    ENV_FILE="$SCRIPT_DIR/config/.env"
    
    if [ -f "$ENV_FILE" ]; then
        print_info ".env file already exists"
        read_input "Do you want to reconfigure it? (y/n)" "n" reconfigure
        if [ "$reconfigure" != "y" ]; then
            print_info "Keeping existing .env file"
        else
            rm -f "$ENV_FILE"
        fi
    fi
    
    if [ ! -f "$ENV_FILE" ]; then
        print_info "Creating .env file from template..."
        
        cp "$SCRIPT_DIR/config/.env.example" "$ENV_FILE"
        
        # Database configuration
        print_header "Database Configuration"
        read_input "Database user" "serverreport" DB_USER
        read_input "Database password" "serverreport_pass" DB_PASSWORD
        read_input "Database name" "serverreport" DB_NAME
        read_input "Database port" "5432" DB_PORT
        
        # Website configuration
        print_header "Website Configuration"
        read_input "Website port" "3000" WEBSITE_PORT
        read_input "Node environment" "development" NODE_ENV
        
        # Bot configuration
        print_header "Discord Bot Configuration"
        print_warning "Get your Discord bot token from: https://discord.com/developers/applications"
        read_input "Discord bot token" "" DISCORD_TOKEN
        
        if [ -z "$DISCORD_TOKEN" ]; then
            print_warning "Discord token is empty - bot won't work without it"
        fi
        
        print_header "Telegram Bot Configuration"
        print_warning "Get your Telegram bot token from: https://t.me/BotFather"
        read_input "Telegram bot token" "" TELEGRAM_TOKEN
        
        if [ -z "$TELEGRAM_TOKEN" ]; then
            print_warning "Telegram token is empty - bot won't work without it"
        fi
        
        # Security configuration
        print_header "Security Configuration"
        print_info "Generating JWT secret (press Enter to auto-generate)"
        read_input "JWT secret" "$(openssl rand -base64 32)" JWT_SECRET
        
        read_input "Admin username" "admin" ADMIN_USER
        read_input "Admin password" "admin_password" ADMIN_PASSWORD
        
        # Update .env file
        print_info "Updating .env file..."
        
        sed -i "s/DB_USER=.*/DB_USER=$DB_USER/" "$ENV_FILE"
        sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" "$ENV_FILE"
        sed -i "s/DB_NAME=.*/DB_NAME=$DB_NAME/" "$ENV_FILE"
        sed -i "s/DB_PORT=.*/DB_PORT=$DB_PORT/" "$ENV_FILE"
        sed -i "s/WEBSITE_PORT=.*/WEBSITE_PORT=$WEBSITE_PORT/" "$ENV_FILE"
        sed -i "s/NODE_ENV=.*/NODE_ENV=$NODE_ENV/" "$ENV_FILE"
        sed -i "s/DISCORD_TOKEN=.*/DISCORD_TOKEN=$DISCORD_TOKEN/" "$ENV_FILE"
        sed -i "s/TELEGRAM_TOKEN=.*/TELEGRAM_TOKEN=$TELEGRAM_TOKEN/" "$ENV_FILE"
        sed -i "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" "$ENV_FILE"
        sed -i "s/ADMIN_USER=.*/ADMIN_USER=$ADMIN_USER/" "$ENV_FILE"
        sed -i "s/ADMIN_PASSWORD=.*/ADMIN_PASSWORD=$ADMIN_PASSWORD/" "$ENV_FILE"
        
        print_success ".env file created and configured"
    fi
    
    # Step 4: Build Docker images
    print_header "Step 4: Building Docker Images"
    
    read_input "Build Docker images now? (y/n)" "y" build_images
    
    if [ "$build_images" = "y" ]; then
        cd "$SCRIPT_DIR/docker"
        print_info "Building images (this may take several minutes)..."
        docker-compose build
        print_success "Docker images built successfully"
        cd "$SCRIPT_DIR"
    fi
    
    # Step 5: Start services
    print_header "Step 5: Starting Services"
    
    read_input "Start Docker services now? (y/n)" "y" start_services
    
    if [ "$start_services" = "y" ]; then
        cd "$SCRIPT_DIR/docker"
        print_info "Starting services..."
        docker-compose up -d
        
        # Wait for database to be ready
        print_info "Waiting for database to be ready..."
        sleep 5
        
        local max_attempts=30
        local attempt=0
        
        while [ $attempt -lt $max_attempts ]; do
            if docker-compose exec -T postgres pg_isready -U $DB_USER &> /dev/null; then
                print_success "Database is ready"
                break
            fi
            attempt=$((attempt + 1))
            sleep 1
        done
        
        if [ $attempt -eq $max_attempts ]; then
            print_warning "Database took too long to start, but continuing..."
        fi
        
        print_success "Services started successfully"
        cd "$SCRIPT_DIR"
    fi
    
    # Step 6: Verify services
    print_header "Step 6: Verifying Services"
    
    cd "$SCRIPT_DIR/docker"
    
    local services=("postgres" "website" "discord-bot" "telegram-bot")
    local all_running=true
    
    for service in "${services[@]}"; do
        if docker-compose ps $service | grep -q "Up"; then
            print_success "$service is running"
        else
            print_warning "$service is not running"
            all_running=false
        fi
    done
    
    if [ "$all_running" = true ]; then
        print_success "All services are running"
    else
        print_warning "Some services are not running. Check logs with: docker-compose logs"
    fi
    
    cd "$SCRIPT_DIR"
    
    # Step 7: Installation complete
    print_header "Setup Complete! 🎉"
    
    echo -e "${GREEN}Your ServerReport installation is ready!${NC}\n"
    
    echo -e "${BLUE}📋 Quick Start Guide:${NC}"
    echo -e "1. ${YELLOW}View logs:${NC}"
    echo -e "   ${BLUE}cd docker${NC}"
    echo -e "   ${BLUE}docker-compose logs -f${NC}\n"
    
    echo -e "2. ${YELLOW}Access the website:${NC}"
    echo -e "   ${BLUE}http://localhost:$WEBSITE_PORT${NC}\n"
    
    echo -e "3. ${YELLOW}Access the database:${NC}"
    echo -e "   ${BLUE}Host: localhost:$DB_PORT${NC}"
    echo -e "   ${BLUE}User: $DB_USER${NC}\n"
    
    echo -e "4. ${YELLOW}Stop services:${NC}"
    echo -e "   ${BLUE}cd docker${NC}"
    echo -e "   ${BLUE}docker-compose down${NC}\n"
    
    echo -e "5. ${YELLOW}View this guide later:${NC}"
    echo -e "   ${BLUE}cat DEVELOPMENT.md${NC}\n"
    
    echo -e "${BLUE}📚 Documentation:${NC}"
    echo -e "- README.md - Project overview"
    echo -e "- DEVELOPMENT.md - Detailed development guide"
    echo -e "- API_REFERENCE.md - API documentation"
    echo -e "- IMPLEMENTATION.md - Implementation details\n"
    
    echo -e "${YELLOW}Important:${NC}"
    echo -e "- Discord/Telegram bots need valid tokens to function"
    echo -e "- Keep your .env file secure"
    echo -e "- Change admin password before production use\n"
    
    print_success "Setup script completed successfully!"
}

# Run main function
main "$@"
