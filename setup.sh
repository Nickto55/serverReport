#!/bin/bash

#############################################################################
# ServerReport - Complete Setup Script for Ubuntu/Linux
# This script handles full system installation and project configuration
#############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#############################################################################
# Helper Functions
#############################################################################

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}$1${NC}"
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

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "This script must be run as root"
        print_info "Run: sudo ./setup.sh"
        exit 1
    fi
    print_success "Running as root"
}

check_os() {
    if [[ ! "$OSTYPE" == "linux-gnu"* ]]; then
        print_error "This script is designed for Linux (Ubuntu/Debian)"
        exit 1
    fi
    print_success "Running on Linux"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        return 1
    fi
    return 0
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
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

install_docker() {
    print_header "Installing Docker"
    
    if command_exists docker; then
        print_success "Docker is already installed"
        docker --version
        return 0
    fi
    
    print_info "Installing Docker from official repository..."
    
    # Add Docker's official GPG key
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl gnupg lsb-release
    
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
    
    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Enable and start Docker
    systemctl enable docker
    systemctl start docker
    
    print_success "Docker installed successfully"
    docker --version
}

install_docker_compose_standalone() {
    print_header "Installing Docker Compose Standalone"
    
    if command_exists docker-compose; then
        print_success "Docker Compose is already installed"
        docker-compose --version
        return 0
    fi
    
    print_info "Installing Docker Compose standalone..."
    
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    print_success "Docker Compose installed successfully"
    docker-compose --version
}

install_dependencies() {
    print_header "Installing System Dependencies"
    
    print_info "Updating package list..."
    apt-get update -qq
    
    print_info "Installing required packages..."
    apt-get install -y -qq \
        curl \
        wget \
        git \
        nano \
        vim \
        net-tools \
        netcat-openbsd \
        postgresql-client
    
    print_success "System dependencies installed"
}

install_nodejs() {
    print_header "Installing Node.js 18+ (Optional)"
    
    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_success "Node.js is already installed: $NODE_VERSION"
        return 0
    fi
    
    read_input "Install Node.js 18+ for local development? (y/n)" "y" install_node
    
    if [ "$install_node" != "y" ]; then
        print_info "Skipping Node.js installation"
        return 0
    fi
    
    print_info "Installing Node.js 18+..."
    
    # Install NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y -qq nodejs
    
    print_success "Node.js installed successfully"
    node --version
    npm --version
}

setup_docker_group() {
    print_header "Setting up Docker User Group"
    
    if getent group docker > /dev/null; then
        print_info "Docker group already exists"
    else
        print_info "Creating docker group..."
        groupadd docker
    fi
    
    # Add current user to docker group
    if [ -n "$SUDO_USER" ]; then
        print_info "Adding $SUDO_USER to docker group..."
        usermod -aG docker "$SUDO_USER"
        print_warning "Run 'newgrp docker' or logout/login to activate docker group permissions"
    fi
}

#############################################################################
# Main Setup
#############################################################################

main() {
    print_header "ServerReport - Complete Ubuntu/Linux Setup"
    
    # Verify .env.example exists
    if [ ! -f "$SCRIPT_DIR/config/.env.example" ]; then
        print_error "config/.env.example not found!"
        print_info "Make sure you're running this script from the ServerReport root directory"
        exit 1
    fi
    
    # Step 0: Verify environment
    print_header "Step 0: Verifying Environment"
    check_root
    check_os
    
    # Step 1: Install system dependencies
    print_header "Step 1: Installing System Dependencies"
    install_dependencies
    
    # Step 2: Install Docker
    install_docker
    
    # Step 3: Install Docker Compose
    install_docker_compose_standalone
    
    # Step 4: Setup Docker group
    setup_docker_group
    
    # Step 5: Install Node.js (optional)
    install_nodejs
    
    # Step 6: Create .env file
    print_header "Step 2: Configuring Environment Variables"
    
    ENV_FILE="$SCRIPT_DIR/config/.env"
    
    if [ -f "$ENV_FILE" ]; then
        print_info ".env file already exists"
        read_input "Do you want to reconfigure it? (y/n)" "n" reconfigure
        if [ "$reconfigure" != "y" ]; then
            print_info "Keeping existing .env file"
            goto_skip_env=true
        fi
    fi
    
    if [ "$goto_skip_env" != "true" ] && [ ! -f "$ENV_FILE" ]; then
        print_info "Creating .env file from template..."
        
        if [ ! -f "$SCRIPT_DIR/config/.env.example" ]; then
            print_error ".env.example not found!"
            exit 1
        fi
        
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
        JWT_SECRET_GENERATED=$(openssl rand -base64 32)
        read_input "JWT secret" "$JWT_SECRET_GENERATED" JWT_SECRET
        
        read_input "Admin username" "admin" ADMIN_USER
        read_input "Admin password" "admin_password_change_this" ADMIN_PASSWORD
        
        # Update .env file
        print_info "Updating .env file..."
        
        sed -i "s|^DB_USER=.*|DB_USER=${DB_USER}|g" "$ENV_FILE"
        sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|g" "$ENV_FILE"
        sed -i "s|^DB_NAME=.*|DB_NAME=${DB_NAME}|g" "$ENV_FILE"
        sed -i "s|^DB_PORT=.*|DB_PORT=${DB_PORT}|g" "$ENV_FILE"
        sed -i "s|^WEBSITE_PORT=.*|WEBSITE_PORT=${WEBSITE_PORT}|g" "$ENV_FILE"
        sed -i "s|^NODE_ENV=.*|NODE_ENV=${NODE_ENV}|g" "$ENV_FILE"
        sed -i "s|^DISCORD_TOKEN=.*|DISCORD_TOKEN=${DISCORD_TOKEN}|g" "$ENV_FILE"
        sed -i "s|^TELEGRAM_TOKEN=.*|TELEGRAM_TOKEN=${TELEGRAM_TOKEN}|g" "$ENV_FILE"
        sed -i "s|^JWT_SECRET=.*|JWT_SECRET=${JWT_SECRET}|g" "$ENV_FILE"
        sed -i "s|^ADMIN_USER=.*|ADMIN_USER=${ADMIN_USER}|g" "$ENV_FILE"
        sed -i "s|^ADMIN_PASSWORD=.*|ADMIN_PASSWORD=${ADMIN_PASSWORD}|g" "$ENV_FILE"
        
        print_success ".env file created and configured"
    fi
    
    # Step 3: Build Docker images
    
    print_header "Step 3: Building Docker Images"
    
    read_input "Build Docker images now? (y/n)" "y" build_images
    
    if [ "$build_images" = "y" ]; then
        cd "$SCRIPT_DIR/docker"
        print_info "Building images (this may take several minutes)..."
        if ! docker-compose build; then
            print_error "Failed to build Docker images"
            exit 1
        fi
        print_success "Docker images built successfully"
        cd "$SCRIPT_DIR"
    fi
    
    # Step 8: Start services
    print_header "Step 4: Starting Services"
    
    read_input "Start Docker services now? (y/n)" "y" start_services
    
    if [ "$start_services" = "y" ]; then
        cd "$SCRIPT_DIR/docker"
        print_info "Starting services..."
        docker-compose up -d || { print_error "Failed to start services"; exit 1; }
        
        # Wait for database to be ready
        print_info "Waiting for database to be ready..."
        sleep 5
        
        local max_attempts=30
        local attempt=0
        local db_user=${DB_USER:-serverreport}
        
        while [ $attempt -lt $max_attempts ]; do
            if docker-compose exec -T postgres pg_isready -U "$db_user" &> /dev/null; then
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
    
    # Step 9: Verify services
    print_header "Step 5: Verifying Services"
    
    cd "$SCRIPT_DIR/docker"
    
    local services=("postgres" "website" "discord-bot" "telegram-bot")
    local all_running=true
    
    for service in "${services[@]}"; do
        if docker-compose ps | grep -q "$service.*Up"; then
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
    
    # Step 10: Installation complete
    print_header "Setup Complete! 🎉"
    
    echo -e "${GREEN}Your ServerReport installation is ready!${NC}\n"
    
    echo -e "${BLUE}📋 Quick Start Guide:${NC}"
    echo -e "1. ${YELLOW}View logs:${NC}"
    echo -e "   ${BLUE}cd docker${NC}"
    echo -e "   ${BLUE}docker-compose logs -f${NC}\n"
    
    echo -e "2. ${YELLOW}Access the website:${NC}"
    echo -e "   ${BLUE}http://localhost:${WEBSITE_PORT}${NC}\n"
    
    echo -e "3. ${YELLOW}Access the database:${NC}"
    echo -e "   ${BLUE}Host: localhost:${DB_PORT}${NC}"
    echo -e "   ${BLUE}User: ${DB_USER}${NC}\n"
    
    echo -e "4. ${YELLOW}Stop services:${NC}"
    echo -e "   ${BLUE}cd docker${NC}"
    echo -e "   ${BLUE}docker-compose down${NC}\n"
    
    echo -e "5. ${YELLOW}View this guide later:${NC}"
    echo -e "   ${BLUE}cat DEVELOPMENT.md${NC}\n"
    
    echo -e "${BLUE}📚 Documentation:${NC}"
    echo -e "- README.md - Project overview"
    echo -e "- DEVELOPMENT.md - Detailed development guide"
    echo -e "- API_REFERENCE.md - API documentation"
    echo -e "- IMPLEMENTATION.md - Implementation details"
    echo -e "- QUICK_START.md - Common commands\n"
    
    echo -e "${YELLOW}Important:${NC}"
    echo -e "- Discord/Telegram bots need valid tokens to function"
    echo -e "- Keep your .env file secure (it contains secrets)"
    echo -e "- Change admin password before production use"
    echo -e "- Use 'sudo ./manage.sh' or add docker group permissions\n"
    
    echo -e "${BLUE}Useful Commands:${NC}"
    echo -e "- ${BLUE}cd docker && docker-compose logs -f${NC} - View logs"
    echo -e "- ${BLUE}./manage.sh status${NC} - Check service status"
    echo -e "- ${BLUE}./manage.sh db-shell${NC} - Connect to database"
    echo -e "- ${BLUE}./manage.sh backup-db${NC} - Backup database\n"
    
    print_success "Setup script completed successfully!"
}

# Run main function
main "$@"
