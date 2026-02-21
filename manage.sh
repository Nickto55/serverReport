#!/bin/bash

#############################################################################
# ServerReport - Management Script
# Helper script for common operations
#############################################################################

# Don't use 'set -e' to allow graceful error handling

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_DIR="$SCRIPT_DIR/docker"

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

show_help() {
    echo "ServerReport - Management Script"
    echo ""
    echo "Usage: ./manage.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  start              - Start all services"
    echo "  stop               - Stop all services"
    echo "  restart            - Restart all services"
    echo "  status             - Show services status"
    echo "  logs [service]     - Show logs (optional: website|postgres|discord|telegram)"
    echo "  shell [service]    - Connect to service shell"
    echo "  build              - Build all Docker images"
    echo "  rebuild            - Rebuild all Docker images"
    echo "  clean              - Stop and remove containers (keeps data)"
    echo "  clean-all          - Stop and remove everything (deletes data!)"
    echo "  install-deps       - Install npm dependencies locally"
    echo "  db-shell           - Connect to PostgreSQL"
    echo "  health-check       - Check services health"
    echo "  backup-db          - Backup database"
    echo "  restore-db [file]  - Restore database from backup"
    echo "  setup              - Run initial setup"
    echo "  help               - Show this help message"
    echo ""
}

start_services() {
    print_header "Starting Services"
    cd "$DOCKER_DIR"
    docker-compose up -d
    print_success "Services started"
    cd "$SCRIPT_DIR"
}

stop_services() {
    print_header "Stopping Services"
    cd "$DOCKER_DIR"
    docker-compose down
    print_success "Services stopped"
    cd "$SCRIPT_DIR"
}

restart_services() {
    print_header "Restarting Services"
    cd "$DOCKER_DIR"
    docker-compose restart
    print_success "Services restarted"
    cd "$SCRIPT_DIR"
}

status_services() {
    print_header "Services Status"
    cd "$DOCKER_DIR"
    docker-compose ps
    cd "$SCRIPT_DIR"
}

show_logs() {
    local service=$1
    print_header "Logs"
    
    cd "$DOCKER_DIR"
    
    if [ -z "$service" ]; then
        print_info "Showing all logs (Ctrl+C to exit)..."
        docker-compose logs -f
    else
        case $service in
            website)
                docker-compose logs -f website
                ;;
            postgres|db)
                docker-compose logs -f postgres
                ;;
            discord)
                docker-compose logs -f discord-bot
                ;;
            telegram)
                docker-compose logs -f telegram-bot
                ;;
            *)
                print_error "Unknown service: $service"
                echo "Available: website, postgres, discord, telegram"
                ;;
        esac
    fi
    
    cd "$SCRIPT_DIR"
}

shell_service() {
    local service=$1
    
    if [ -z "$service" ]; then
        print_error "Please specify service: website, postgres, discord, telegram"
        return 1
    fi
    
    print_header "Connecting to $service"
    
    cd "$DOCKER_DIR"
    
    case $service in
        website)
            docker-compose exec website sh
            ;;
        postgres|db)
            docker-compose exec postgres bash
            ;;
        discord)
            docker-compose exec discord-bot sh
            ;;
        telegram)
            docker-compose exec telegram-bot sh
            ;;
        *)
            print_error "Unknown service: $service"
            echo "Available: website, postgres, discord, telegram"
            ;;
    esac
    
    cd "$SCRIPT_DIR"
}

build_images() {
    print_header "Building Docker Images"
    cd "$DOCKER_DIR"
    docker-compose build
    print_success "Docker images built"
    cd "$SCRIPT_DIR"
}

rebuild_images() {
    print_header "Rebuilding Docker Images"
    cd "$DOCKER_DIR"
    docker-compose build --no-cache
    print_success "Docker images rebuilt"
    cd "$SCRIPT_DIR"
}

clean_services() {
    print_header "Cleaning Services"
    print_warning "This will stop and remove containers but keep data"
    
    cd "$DOCKER_DIR"
    docker-compose down
    print_success "Services cleaned"
    cd "$SCRIPT_DIR"
}

clean_all() {
    print_header "Complete Cleanup"
    print_warning "This will DELETE ALL DATA! Type 'yes' to confirm"
    
    read -p "Type 'yes' to continue: " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Cleanup cancelled"
        return
    fi
    
    cd "$DOCKER_DIR"
    docker-compose down -v
    print_success "All services and data removed"
    cd "$SCRIPT_DIR"
}

install_deps() {
    print_header "Installing Local Dependencies"
    
    local dirs=("website" "discord-bot" "telegram-bot")
    
    for dir in "${dirs[@]}"; do
        if [ -d "$SCRIPT_DIR/$dir" ]; then
            print_info "Installing dependencies in $dir..."
            cd "$SCRIPT_DIR/$dir"
            npm install
        fi
    done
    
    print_success "Dependencies installed"
    cd "$SCRIPT_DIR"
}

db_shell() {
    print_header "PostgreSQL Shell"
    print_info "Type \\q to exit"
    
    cd "$DOCKER_DIR"
    
    # Get DB credentials from .env
    DB_USER=$(grep "^DB_USER=" "$SCRIPT_DIR/config/.env" | cut -d'=' -f2)
    DB_NAME=$(grep "^DB_NAME=" "$SCRIPT_DIR/config/.env" | cut -d'=' -f2)
    
    docker-compose exec postgres psql -U "$DB_USER" -d "$DB_NAME"
    
    cd "$SCRIPT_DIR"
}

health_check() {
    print_header "Health Check"
    
    cd "$DOCKER_DIR"
    
    print_info "Checking services..."
    
    docker-compose exec -T postgres pg_isready -U serverreport >/dev/null 2>&1 && \
        print_success "PostgreSQL is healthy" || \
        print_error "PostgreSQL is not responding"
    
    curl -s http://localhost:3000/health >/dev/null 2>&1 && \
        print_success "Website is healthy" || \
        print_warning "Website is not responding"
    
    docker-compose ps | grep -q "discord-bot.*Up" && \
        print_success "Discord bot is running" || \
        print_warning "Discord bot is not running"
    
    docker-compose ps | grep -q "telegram-bot.*Up" && \
        print_success "Telegram bot is running" || \
        print_warning "Telegram bot is not running"
    
    cd "$SCRIPT_DIR"
}

backup_db() {
    print_header "Database Backup"
    
    local backup_dir="$SCRIPT_DIR/backups"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$backup_dir/serverreport_$timestamp.sql"
    
    if [ ! -d "$backup_dir" ]; then
        mkdir -p "$backup_dir"
    fi
    
    print_info "Creating backup..."
    
    cd "$DOCKER_DIR"
    
    DB_USER=$(grep "^DB_USER=" "$SCRIPT_DIR/config/.env" | cut -d'=' -f2)
    DB_NAME=$(grep "^DB_NAME=" "$SCRIPT_DIR/config/.env" | cut -d'=' -f2)
    
    docker-compose exec -T postgres pg_dump -U "$DB_USER" "$DB_NAME" > "$backup_file"
    
    print_success "Database backed up to: $backup_file"
    print_info "Backup size: $(du -h "$backup_file" | cut -f1)"
    
    cd "$SCRIPT_DIR"
}

restore_db() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        print_error "Please specify backup file"
        print_info "Usage: ./manage.sh restore-db [backup_file]"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi
    
    print_header "Database Restore"
    print_warning "This will overwrite your current database! Type 'yes' to confirm"
    
    read -p "Type 'yes' to continue: " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Restore cancelled"
        return
    fi
    
    print_info "Restoring database from $backup_file..."
    
    cd "$DOCKER_DIR"
    
    DB_USER=$(grep "^DB_USER=" "$SCRIPT_DIR/config/.env" | cut -d'=' -f2)
    DB_NAME=$(grep "^DB_NAME=" "$SCRIPT_DIR/config/.env" | cut -d'=' -f2)
    
    docker-compose exec -T postgres psql -U "$DB_USER" "$DB_NAME" < "$backup_file"
    
    print_success "Database restored"
    
    cd "$SCRIPT_DIR"
}

setup() {
    print_info "Running setup script..."
    "$SCRIPT_DIR/setup.sh"
}

# Main
case "${1:-help}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        status_services
        ;;
    logs)
        show_logs "$2"
        ;;
    shell)
        shell_service "$2"
        ;;
    build)
        build_images
        ;;
    rebuild)
        rebuild_images
        ;;
    clean)
        clean_services
        ;;
    clean-all)
        clean_all
        ;;
    install-deps)
        install_deps
        ;;
    db-shell)
        db_shell
        ;;
    health-check)
        health_check
        ;;
    backup-db)
        backup_db
        ;;
    restore-db)
        restore_db "$2"
        ;;
    setup)
        setup
        ;;
    help)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
