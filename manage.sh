#!/bin/bash

# ServerReport Management Panel
# Панель управления для ServerReport с Docker

# Цвета
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Пути
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$PROJECT_DIR/docker"
ENV_FILE="$PROJECT_DIR/config/.env"

# Названия сервисов
SERVICE_WEBSITE="website"
SERVICE_POSTGRES="postgres"
SERVICE_DISCORD="discord-bot"
SERVICE_TELEGRAM="telegram-bot"

# Функция очистки экрана и вывода заголовка
show_header() {
    clear
    echo -e "${WHITE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${NC}        ${CYAN}ServerReport Management Panel${NC}                 ${WHITE}║${NC}"
    echo -e "${WHITE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Функция получения статуса Docker сервиса
get_service_status() {
    local service=$1
    if [ ! -f "$DOCKER_DIR/docker-compose.yml" ]; then
        echo -e "${ORANGE}●${NC} Не настроен"
        return
    fi
    
    cd "$DOCKER_DIR" || return
    
    if docker-compose ps "$service" 2>/dev/null | grep -q "Up"; then
        echo -e "${GREEN}●${NC} Запущен"
    else
        echo -e "${RED}●${NC} Остановлен"
    fi
    
    cd "$PROJECT_DIR" || return
}

# Функция проверки Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}●${NC} Не установлен"
        return 1
    fi
    
    if docker ps &> /dev/null; then
        echo -e "${GREEN}●${NC} Готов"
        return 0
    else
        echo -e "${YELLOW}●${NC} Нет прав"
        return 1
    fi
}

# Главное меню
show_menu() {
    show_header
    
    echo -e "${WHITE}┌─ Статус сервисов ────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  Docker:        $(check_docker)"
    echo -e "${WHITE}│${NC}  Website:       $(get_service_status $SERVICE_WEBSITE)"
    echo -e "${WHITE}│${NC}  PostgreSQL:    $(get_service_status $SERVICE_POSTGRES)"
    echo -e "${WHITE}│${NC}  Discord Bot:   $(get_service_status $SERVICE_DISCORD)"
    echo -e "${WHITE}│${NC}  Telegram Bot:  $(get_service_status $SERVICE_TELEGRAM)"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}└───────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${WHITE}┌─ Управление ──────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  ${WHITE}1.${NC} Запустить все сервисы"
    echo -e "${WHITE}│${NC}  ${WHITE}2.${NC} Остановить все сервисы"
    echo -e "${WHITE}│${NC}  ${WHITE}3.${NC} Перезапустить все сервисы"
    echo -e "${WHITE}│${NC}  ${WHITE}4.${NC} Показать подробный статус"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  ${WHITE}5.${NC} Просмотр логов (все)"
    echo -e "${WHITE}│${NC}  ${WHITE}6.${NC} Просмотр логов Website"
    echo -e "${WHITE}│${NC}  ${WHITE}7.${NC} Просмотр логов PostgreSQL"
    echo -e "${WHITE}│${NC}  ${WHITE}8.${NC} Просмотр логов Discord Bot"
    echo -e "${WHITE}│${NC}  ${WHITE}9.${NC} Просмотр логов Telegram Bot"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  ${WHITE}10.${NC} Подключиться к контейнеру (shell)"
    echo -e "${WHITE}│${NC}  ${WHITE}11.${NC} Подключиться к PostgreSQL (psql)"
    echo -e "${WHITE}│${NC}  ${WHITE}12.${NC} Проверка здоровья сервисов"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  ${WHITE}13.${NC} Создать резервную копию БД"
    echo -e "${WHITE}│${NC}  ${WHITE}14.${NC} Восстановить БД из копии"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  ${WHITE}15.${NC} Собрать Docker образы"
    echo -e "${WHITE}│${NC}  ${WHITE}16.${NC} Пересобрать образы (без кеша)"
    echo -e "${WHITE}│${NC}  ${WHITE}17.${NC} Очистить контейнеры"
    echo -e "${WHITE}│${NC}  ${WHITE}18.${NC} Полная очистка (удалить всё!)"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  ${WHITE}19.${NC} Установить зависимости (npm)"
    echo -e "${WHITE}│${NC}  ${WHITE}20.${NC} Показать конфигурацию (.env)"
    echo -e "${WHITE}│${NC}  ${WHITE}21.${NC} Информация о сервисах"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  ${WHITE}22.${NC} Обновить проект (git pull)"
    echo -e "${WHITE}│${NC}  ${WHITE}23.${NC} Запустить полную установку (setup.sh)"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  ${WHITE}0.${NC} Выход"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}└───────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -n -e "${WHITE}Выберите действие: ${NC}"
}

# Функции управления
start_all() {
    echo -e "${GREEN}Запуск всех сервисов...${NC}"
    
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${RED}✗ Файл $ENV_FILE не найден${NC}"
        echo -e "${YELLOW}Запустите сначала: ./setup.sh${NC}"
        read -p "Нажмите Enter для продолжения..."
        return
    fi
    
    cd "$DOCKER_DIR" || return
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Сервисы запущены${NC}"
        echo ""
        echo -e "${CYAN}Сервисы доступны по адресам:${NC}"
        echo -e "  ${GREEN}●${NC} Website: ${BLUE}http://localhost:3000${NC}"
        echo -e "  ${GREEN}●${NC} PostgreSQL: ${BLUE}localhost:5432${NC}"
    else
        echo -e "${RED}✗ Ошибка при запуске${NC}"
    fi
    
    cd "$PROJECT_DIR" || return
    echo ""
    sleep 3
}

stop_all() {
    echo -e "${YELLOW}Остановка всех сервисов...${NC}"
    
    cd "$DOCKER_DIR" || return
    docker-compose down
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Сервисы остановлены${NC}"
    else
        echo -e "${RED}✗ Ошибка при остановке${NC}"
    fi
    
    cd "$PROJECT_DIR" || return
    sleep 2
}

restart_all() {
    echo -e "${YELLOW}Перезапуск всех сервисов...${NC}"
    
    cd "$DOCKER_DIR" || return
    docker-compose restart
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Сервисы перезапущены${NC}"
    else
        echo -e "${RED}✗ Ошибка при перезапуске${NC}"
    fi
    
    cd "$PROJECT_DIR" || return
    sleep 2
}

show_detailed_status() {
    show_header
    echo -e "${BLUE}┌─ Детальный статус ────────────────────────────────────────┐${NC}"
    echo ""
    
    cd "$DOCKER_DIR" || return
    
    echo -e "${WHITE}Docker Compose состояние:${NC}"
    docker-compose ps
    
    echo ""
    echo -e "${WHITE}Использование ресурсов:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" \
        $(docker-compose ps -q 2>/dev/null)
    
    echo ""
    echo -e "${WHITE}Используемые порты:${NC}"
    echo -e "  ${GREEN}●${NC} 3000 - Website (HTTP)"
    echo -e "  ${GREEN}●${NC} 5432 - PostgreSQL"
    
    cd "$PROJECT_DIR" || return
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

view_logs() {
    local service=$1
    
    # Проверяем наличие Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker не установлен${NC}"
        sleep 2
        return 1
    fi
    
    # Проверяем наличие docker-compose.yml
    if [ ! -f "$DOCKER_DIR/docker-compose.yml" ]; then
        echo -e "${RED}✗ Файл docker-compose.yml не найден${NC}"
        echo -e "${YELLOW}Путь: $DOCKER_DIR/docker-compose.yml${NC}"
        sleep 3
        return 1
    fi
    
    cd "$DOCKER_DIR" || return
    
    # Проверяем, что хотя бы один контейнер запущен
    if [ -z "$(docker-compose ps -q 2>/dev/null)" ]; then
        echo -e "${RED}✗ Нет запущенных контейнеров${NC}"
        echo ""
        echo -e "${YELLOW}Запустите сервисы: ./manage.sh (выберите пункт 1)${NC}"
        echo ""
        read -p "Нажмите Enter для продолжения..."
        cd "$PROJECT_DIR" || return
        return 1
    fi
    
    # Получаем информацию о сервере
    SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    SERVER_HOSTNAME=$(hostname 2>/dev/null)
    
    # Проверяем наличие домена в .env
    DOMAIN=""
    if [ -f "$ENV_FILE" ]; then
        DOMAIN=$(grep "^DOMAIN=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d ' "' | head -n1)
    fi
    
    if [ -z "$service" ]; then
        clear
        echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}  Логи всех сервисов${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        
        # Информация о сервере
        if [ -n "$SERVER_HOSTNAME" ]; then
            echo -e "${WHITE}Сервер:${NC} ${GREEN}$SERVER_HOSTNAME${NC}"
        fi
        if [ -n "$SERVER_IP" ]; then
            echo -e "${WHITE}IP:${NC} ${CYAN}$SERVER_IP${NC}"
        fi
        
        # Ссылки на сайт
        echo ""
        echo -e "${WHITE}Доступ к сайту:${NC}"
        if [ -n "$DOMAIN" ]; then
            echo -e "  ${GREEN}●${NC} ${BLUE}http://$DOMAIN:3000${NC} ${YELLOW}(домен)${NC}"
        fi
        if [ -n "$SERVER_IP" ]; then
            echo -e "  ${GREEN}●${NC} ${BLUE}http://$SERVER_IP:3000${NC}"
        fi
        echo -e "  ${GREEN}●${NC} ${BLUE}http://localhost:3000${NC} ${CYAN}(локально)${NC}"
        
        echo ""
        echo -e "${CYAN}─────────────────────────────────────────────────────────${NC}"
        echo -e "${YELLOW}Нажмите Ctrl+C для выхода${NC}"
        echo -e "${CYAN}─────────────────────────────────────────────────────────${NC}"
        echo ""
        
        docker-compose logs -f --tail=100
        
        # Пауза после выхода
        echo ""
        echo -e "${GREEN}Просмотр логов завершен${NC}"
        read -p "Нажмите Enter для возврата в меню..." -t 2 || true
    else
        clear
        echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}  Логи сервиса: $service${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        
        # Информация о сервере для конкретного сервиса
        if [ "$service" = "$SERVICE_WEBSITE" ]; then
            if [ -n "$SERVER_HOSTNAME" ]; then
                echo -e "${WHITE}Сервер:${NC} ${GREEN}$SERVER_HOSTNAME${NC}"
            fi
            if [ -n "$SERVER_IP" ]; then
                echo -e "${WHITE}IP:${NC} ${CYAN}$SERVER_IP${NC}"
            fi
            
            echo ""
            echo -e "${WHITE}Доступ к сайту:${NC}"
            if [ -n "$DOMAIN" ]; then
                echo -e "  ${GREEN}●${NC} ${BLUE}http://$DOMAIN:3000${NC} ${YELLOW}(домен)${NC}"
            fi
            if [ -n "$SERVER_IP" ]; then
                echo -e "  ${GREEN}●${NC} ${BLUE}http://$SERVER_IP:3000${NC}"
            fi
            echo -e "  ${GREEN}●${NC} ${BLUE}http://localhost:3000${NC} ${CYAN}(локально)${NC}"
            echo ""
        elif [ "$service" = "$SERVICE_POSTGRES" ]; then
            if [ -n "$SERVER_IP" ]; then
                echo -e "${WHITE}PostgreSQL:${NC} ${CYAN}$SERVER_IP:5432${NC}"
            fi
            echo ""
        fi
        
        echo -e "${CYAN}─────────────────────────────────────────────────────────${NC}"
        echo -e "${YELLOW}Нажмите Ctrl+C для выхода${NC}"
        echo -e "${CYAN}─────────────────────────────────────────────────────────${NC}"
        echo ""
        
        # Проверяем, существует ли сервис
        if ! docker-compose ps "$service" &>/dev/null; then
            echo -e "${RED}✗ Сервис '$service' не найден${NC}"
            echo ""
            echo -e "${WHITE}Доступные сервисы:${NC}"
            docker-compose ps --services 2>/dev/null || echo "  Нет запущенных сервисов"
            echo ""
            sleep 3
            cd "$PROJECT_DIR" || return
            return 1
        fi
        
        docker-compose logs -f --tail=100 "$service"
        
        # Пауза после выхода
        echo ""
        echo -e "${GREEN}Просмотр логов завершен${NC}"
        read -p "Нажмите Enter для возврата в меню..." -t 2 || true
    fi
    
    cd "$PROJECT_DIR" || return
}

shell_service() {
    show_header
    
    # Проверяем Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker не установлен${NC}"
        read -p "Нажмите Enter для продолжения..."
        return 1
    fi
    
    # Проверяем docker-compose.yml
    if [ ! -f "$DOCKER_DIR/docker-compose.yml" ]; then
        echo -e "${RED}✗ Файл docker-compose.yml не найден${NC}"
        read -p "Нажмите Enter для продолжения..."
        return 1
    fi
    
    echo -e "${CYAN}Выберите сервис для подключения:${NC}"
    echo ""
    echo -e "  ${WHITE}1.${NC} Website"
    echo -e "  ${WHITE}2.${NC} PostgreSQL"
    echo -e "  ${WHITE}3.${NC} Discord Bot"
    echo -e "  ${WHITE}4.${NC} Telegram Bot"
    echo -e "  ${WHITE}0.${NC} Отмена"
    echo ""
    echo -n -e "${WHITE}Ваш выбор: ${NC}"
    read service_choice
    
    case $service_choice in
        1) service_name="$SERVICE_WEBSITE" ;;
        2) service_name="$SERVICE_POSTGRES" ;;
        3) service_name="$SERVICE_DISCORD" ;;
        4) service_name="$SERVICE_TELEGRAM" ;;
        0) return ;;
        *)
            echo -e "${RED}Неверный выбор${NC}"
            sleep 1
            return
            ;;
    esac
    
    cd "$DOCKER_DIR" || return
    
    # Проверяем, запущен ли контейнер
    if ! docker-compose ps "$service_name" 2>/dev/null | grep -q "Up"; then
        echo ""
        echo -e "${RED}✗ Контейнер '$service_name' не запущен${NC}"
        echo ""
        echo -e "${YELLOW}Запустите сервисы командой: ./manage.sh (выберите пункт 1)${NC}"
        echo ""
        read -p "Нажмите Enter для продолжения..."
        cd "$PROJECT_DIR" || return
        return 1
    fi
    
    echo ""
    echo -e "${GREEN}Подключение к $service_name...${NC}"
    echo -e "${YELLOW}Для выхода введите 'exit'${NC}"
    echo ""
    
    # Пробуем bash, если не получается - sh
    if ! docker-compose exec "$service_name" /bin/bash 2>/dev/null; then
        docker-compose exec "$service_name" /bin/sh
    fi
    
    cd "$PROJECT_DIR" || return
}

db_shell() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  PostgreSQL Shell${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Подключение к PostgreSQL...${NC}"
    echo -e "${YELLOW}Для выхода введите \\q${NC}"
    echo ""
    
    # Проверяем .env файл
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${RED}✗ Файл $ENV_FILE не найден${NC}"
        echo -e "${YELLOW}Запустите: ./setup.sh${NC}"
        echo ""
        read -p "Нажмите Enter для продолжения..."
        return
    fi
    
    # Проверяем Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker не установлен${NC}"
        read -p "Нажмите Enter для продолжения..."
        return
    fi
    
    cd "$DOCKER_DIR" || return
    
    # Проверяем, запущен ли PostgreSQL
    if ! docker-compose ps postgres 2>/dev/null | grep -q "Up"; then
        echo -e "${RED}✗ PostgreSQL контейнер не запущен${NC}"
        echo ""
        echo -e "${YELLOW}Запустите сервисы: ./manage.sh (пункт 1)${NC}"
        echo ""
        read -p "Нажмите Enter для продолжения..."
        cd "$PROJECT_DIR" || return
        return
    fi
    
    # Получаем credentials из .env
    DB_USER=$(grep "^DB_USER=" "$ENV_FILE" | cut -d'=' -f2 | tr -d ' ')
    DB_NAME=$(grep "^DB_NAME=" "$ENV_FILE" | cut -d'=' -f2 | tr -d ' ')
    
    if [ -z "$DB_USER" ] || [ -z "$DB_NAME" ]; then
        echo -e "${RED}✗ Не удалось прочитать DB_USER или DB_NAME из $ENV_FILE${NC}"
        echo ""
        read -p "Нажмите Enter для продолжения..."
        cd "$PROJECT_DIR" || return
        return
    fi
    
    echo -e "${WHITE}Пользователь: ${CYAN}$DB_USER${NC}"
    echo -e "${WHITE}База данных: ${CYAN}$DB_NAME${NC}"
    echo ""
    
    docker-compose exec postgres psql -U "$DB_USER" -d "$DB_NAME"
    
    cd "$PROJECT_DIR" || return
}

health_check() {
    show_header
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Проверка здоровья сервисов${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    cd "$DOCKER_DIR" || return
    
    # PostgreSQL
    echo -n -e "${WHITE}PostgreSQL:${NC} "
    if docker-compose exec -T postgres pg_isready -U serverreport >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Здоров${NC}"
    else
        echo -e "${RED}✗ Не отвечает${NC}"
    fi
    
    # Website
    echo -n -e "${WHITE}Website:${NC} "
    if curl -sf http://localhost:3000/health >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Здоров${NC}"
    else
        echo -e "${YELLOW}⚠ Не отвечает (может быть не настроен /health endpoint)${NC}"
    fi
    
    # Discord Bot
    echo -n -e "${WHITE}Discord Bot:${NC} "
    if docker-compose ps | grep -q "discord-bot.*Up"; then
        echo -e "${GREEN}✓ Запущен${NC}"
    else
        echo -e "${RED}✗ Не запущен${NC}"
    fi
    
    # Telegram Bot
    echo -n -e "${WHITE}Telegram Bot:${NC} "
    if docker-compose ps | grep -q "telegram-bot.*Up"; then
        echo -e "${GREEN}✓ Запущен${NC}"
    else
        echo -e "${RED}✗ Не запущен${NC}"
    fi
    
    cd "$PROJECT_DIR" || return
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

backup_db() {
    show_header
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Резервное копирование базы данных${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${RED}✗ Файл $ENV_FILE не найден${NC}"
        read -p "Нажмите Enter для продолжения..."
        return
    fi
    
    # Создаем директорию для бэкапов
    BACKUP_DIR="$PROJECT_DIR/backups"
    mkdir -p "$BACKUP_DIR"
    
    # Генерируем имя файла с датой и временем
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/serverreport_$TIMESTAMP.sql"
    
    cd "$DOCKER_DIR" || return
    
    # Получаем credentials из .env
    DB_USER=$(grep "^DB_USER=" "$ENV_FILE" | cut -d'=' -f2 | tr -d ' ')
    DB_NAME=$(grep "^DB_NAME=" "$ENV_FILE" | cut -d'=' -f2 | tr -d ' ')
    
    echo -e "${YELLOW}Создание резервной копии...${NC}"
    echo -e "${WHITE}Файл: ${CYAN}$BACKUP_FILE${NC}"
    echo ""
    
    if docker-compose exec -T postgres pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"; then
        FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        echo -e "${GREEN}✓ Резервная копия создана${NC}"
        echo -e "${WHITE}Размер: ${CYAN}$FILE_SIZE${NC}"
    else
        echo -e "${RED}✗ Ошибка при создании резервной копии${NC}"
    fi
    
    cd "$PROJECT_DIR" || return
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

restore_db() {
    show_header
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Восстановление базы данных${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    BACKUP_DIR="$PROJECT_DIR/backups"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR"/*.sql 2>/dev/null)" ]; then
        echo -e "${RED}✗ Резервные копии не найдены${NC}"
        echo -e "${YELLOW}Директория: $BACKUP_DIR${NC}"
        read -p "Нажмите Enter для продолжения..."
        return
    fi
    
    echo -e "${WHITE}Доступные резервные копии:${NC}"
    echo ""
    
    # Показываем список бэкапов
    local i=1
    declare -a backups
    for backup in $(ls -1t "$BACKUP_DIR"/*.sql 2>/dev/null); do
        backups[$i]="$backup"
        local size=$(du -h "$backup" | cut -f1)
        local date=$(stat -c %y "$backup" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
        echo -e "  ${WHITE}$i.${NC} $(basename "$backup") ${CYAN}[$size]${NC} ${YELLOW}($date)${NC}"
        ((i++))
    done
    
    echo ""
    echo -n -e "${WHITE}Выберите номер файла (0 - отмена): ${NC}"
    read backup_choice
    
    if [ "$backup_choice" = "0" ] || [ -z "$backup_choice" ]; then
        echo -e "${YELLOW}Отменено${NC}"
        sleep 1
        return
    fi
    
    if [ -z "${backups[$backup_choice]}" ]; then
        echo -e "${RED}Неверный выбор${NC}"
        sleep 1
        return
    fi
    
    BACKUP_FILE="${backups[$backup_choice]}"
    
    echo ""
    echo -e "${RED}ВНИМАНИЕ!${NC} ${YELLOW}Это действие перезапишет текущую базу данных!${NC}"
    echo -e "${WHITE}Файл для восстановления: ${CYAN}$(basename "$BACKUP_FILE")${NC}"
    echo ""
    echo -n -e "${WHITE}Продолжить? Введите 'yes': ${NC}"
    read confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}Отменено${NC}"
        sleep 1
        return
    fi
    
    cd "$DOCKER_DIR" || return
    
    # Получаем credentials из .env
    DB_USER=$(grep "^DB_USER=" "$ENV_FILE" | cut -d'=' -f2 | tr -d ' ')
    DB_NAME=$(grep "^DB_NAME=" "$ENV_FILE" | cut -d'=' -f2 | tr -d ' ')
    
    echo ""
    echo -e "${YELLOW}Восстановление базы данных...${NC}"
    
    if docker-compose exec -T postgres psql -U "$DB_USER" "$DB_NAME" < "$BACKUP_FILE"; then
        echo -e "${GREEN}✓ База данных восстановлена${NC}"
    else
        echo -e "${RED}✗ Ошибка при восстановлении${NC}"
    fi
    
    cd "$PROJECT_DIR" || return
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

build_images() {
    echo -e "${CYAN}Сборка Docker образов...${NC}"
    
    cd "$DOCKER_DIR" || return
    docker-compose build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Образы собраны${NC}"
    else
        echo -e "${RED}✗ Ошибка при сборке${NC}"
    fi
    
    cd "$PROJECT_DIR" || return
    sleep 2
}

rebuild_images() {
    echo -e "${CYAN}Пересборка Docker образов без кеша...${NC}"
    echo -e "${YELLOW}Это может занять несколько минут${NC}"
    echo ""
    
    cd "$DOCKER_DIR" || return
    docker-compose build --no-cache
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Образы пересобраны${NC}"
    else
        echo -e "${RED}✗ Ошибка при сборке${NC}"
    fi
    
    cd "$PROJECT_DIR" || return
    sleep 2
}

clean_containers() {
    echo -e "${YELLOW}Очистка контейнеров...${NC}"
    
    cd "$DOCKER_DIR" || return
    docker-compose down
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Контейнеры удалены${NC}"
    else
        echo -e "${RED}✗ Ошибка при очистке${NC}"
    fi
    
    cd "$PROJECT_DIR" || return
    sleep 2
}

clean_all() {
    show_header
    echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  ПОЛНАЯ ОЧИСТКА${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${RED}ВНИМАНИЕ!${NC} ${YELLOW}Это действие удалит:${NC}"
    echo -e "  ${RED}●${NC} Все контейнеры"
    echo -e "  ${RED}●${NC} Все Docker образы проекта"
    echo -e "  ${RED}●${NC} Все данные (включая базу данных!)"
    echo ""
    echo -e "${WHITE}Резервные копии НЕ будут удалены${NC}"
    echo ""
    echo -n -e "${WHITE}Продолжить? Введите 'yes': ${NC}"
    read confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}Отменено${NC}"
        sleep 1
        return
    fi
    
    cd "$DOCKER_DIR" || return
    
    echo ""
    echo -e "${YELLOW}Удаление контейнеров, образов и данных...${NC}"
    docker-compose down -v --rmi all
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Полная очистка завершена${NC}"
        echo -e "${CYAN}Для повторного запуска выполните: ./setup.sh${NC}"
    else
        echo -e "${RED}✗ Ошибка при очистке${NC}"
    fi
    
    cd "$PROJECT_DIR" || return
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

install_deps() {
    show_header
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Установка npm зависимостей${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local services=("website" "discord-bot" "telegram-bot")
    local success_count=0
    local fail_count=0
    
    for service in "${services[@]}"; do
        if [ -d "$PROJECT_DIR/$service" ] && [ -f "$PROJECT_DIR/$service/package.json" ]; then
            echo -e "${YELLOW}Установка зависимостей для $service...${NC}"
            cd "$PROJECT_DIR/$service" || continue
            
            if npm install; then
                echo -e "${GREEN}✓ $service - зависимости установлены${NC}"
                ((success_count++))
            else
                echo -e "${RED}✗ $service - ошибка установки${NC}"
                ((fail_count++))
            fi
            echo ""
        fi
    done
    
    cd "$PROJECT_DIR" || return
    
    echo -e "${CYAN}─────────────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}Успешно: ${GREEN}$success_count${NC}"
    echo -e "${WHITE}Ошибок: ${RED}$fail_count${NC}"
    echo -e "${CYAN}─────────────────────────────────────────────────────────${NC}"
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

show_config() {
    show_header
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Конфигурация проекта${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${RED}✗ Файл $ENV_FILE не найден${NC}"
        echo -e "${YELLOW}Запустите: ./setup.sh${NC}"
        read -p "Нажмите Enter для продолжения..."
        return
    fi
    
    echo -e "${WHITE}Переменные окружения:${NC}"
    echo ""
    
    while IFS='=' read -r key value; do
        # Пропускаем пустые строки и комментарии
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
        
        # Скрываем чувствительные данные
        if [[ "$key" =~ (PASSWORD|TOKEN|SECRET|KEY) ]]; then
            echo -e "  ${YELLOW}$key${NC}=${RED}***hidden***${NC}"
        else
            echo -e "  ${YELLOW}$key${NC}=${CYAN}$value${NC}"
        fi
    done < "$ENV_FILE"
    
    echo ""
    echo -e "${WHITE}Путь к файлу: ${CYAN}$ENV_FILE${NC}"
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

show_info() {
    show_header
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Информация о сервисах${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${WHITE}┌─ Website ──────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  ${GREEN}●${NC} Express.js веб-сервер"
    echo -e "${WHITE}│${NC}  ${GREEN}●${NC} Порт: ${CYAN}3000${NC}"
    echo -e "${WHITE}│${NC}  ${GREEN}●${NC} Маршруты: /api, /admin, /auth, /reports"
    echo -e "${WHITE}│${NC}  ${GREEN}●${NC} JWT аутентификация"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${WHITE}┌─ PostgreSQL ───────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  ${GREEN}●${NC} PostgreSQL 15"
    echo -e "${WHITE}│${NC}  ${GREEN}●${NC} Порт: ${CYAN}5432${NC}"
    echo -e "${WHITE}│${NC}  ${GREEN}●${NC} База данных и хранение данных"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${WHITE}┌─ Discord Bot ──────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  ${GREEN}●${NC} Discord.js v14"
    echo -e "${WHITE}│${NC}  ${GREEN}●${NC} Команды: /report, /status"
    echo -e "${WHITE}│${NC}  ${GREEN}●${NC} Интеграция с серверными отчетами"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${WHITE}┌─ Telegram Bot ─────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}│${NC}  ${GREEN}●${NC} Telegraf"
    echo -e "${WHITE}│${NC}  ${GREEN}●${NC} Автоматизированные отчеты"
    echo -e "${WHITE}│${NC}  ${GREEN}●${NC} Telegram интеграция"
    echo -e "${WHITE}│${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    read -p "Нажмите Enter для продолжения..."
}

update_project() {
    show_header
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Обновление проекта из Git${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if ! command -v git &> /dev/null; then
        echo -e "${RED}✗ Git не установлен${NC}"
        read -p "Нажмите Enter для продолжения..."
        return
    fi
    
    if [ ! -d "$PROJECT_DIR/.git" ]; then
        echo -e "${RED}✗ Это не git репозиторий${NC}"
        echo -e "${YELLOW}Обновление через git недоступно${NC}"
        read -p "Нажмите Enter для продолжения..."
        return
    fi
    
    CURRENT_BRANCH=$(git branch --show-current)
    echo -e "${WHITE}Текущая ветка: ${CYAN}$CURRENT_BRANCH${NC}"
    echo -e "${WHITE}Последний коммит:${NC}"
    git log -1 --oneline --color
    echo ""
    
    # Проверка изменений
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}⚠ Обнаружены локальные изменения:${NC}"
        git status --short
        echo ""
        echo -n -e "${WHITE}Продолжить? Изменения могут быть потеряны (y/n): ${NC}"
        read confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Отменено${NC}"
            sleep 1
            return
        fi
    fi
    
    echo -e "${YELLOW}Проверка обновлений...${NC}"
    git fetch origin
    
    if [ -n "$(git log HEAD..origin/$CURRENT_BRANCH --oneline)" ]; then
        echo -e "${GREEN}Доступные обновления:${NC}"
        git log HEAD..origin/$CURRENT_BRANCH --oneline --decorate --color
        echo ""
        
        echo -n -e "${WHITE}Применить обновления? (y/n): ${NC}"
        read confirm
        
        if [[ $confirm =~ ^[Yy]$ ]]; then
            # Останавливаем сервисы
            echo -e "${YELLOW}Остановка сервисов...${NC}"
            cd "$DOCKER_DIR" && docker-compose down
            cd "$PROJECT_DIR" || return
            
            # Обновляем
            echo -e "${YELLOW}Обновление кода...${NC}"
            git pull origin $CURRENT_BRANCH
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Проект обновлен${NC}"
                
                # Пересборка образов
                echo -e "${YELLOW}Пересборка Docker образов...${NC}"
                cd "$DOCKER_DIR" && docker-compose build
                
                # Запуск сервисов
                echo -e "${YELLOW}Запуск сервисов...${NC}"
                docker-compose up -d
                cd "$PROJECT_DIR" || return
                
                echo -e "${GREEN}✓ Обновление завершено${NC}"
            else
                echo -e "${RED}✗ Ошибка при обновлении${NC}"
            fi
        else
            echo -e "${YELLOW}Отменено${NC}"
        fi
    else
        echo -e "${GREEN}✓ Проект уже актуален${NC}"
    fi
    
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

run_setup() {
    show_header
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Запуск полной установки${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ ! -f "$PROJECT_DIR/setup.sh" ]; then
        echo -e "${RED}✗ Файл setup.sh не найден${NC}"
        read -p "Нажмите Enter для продолжения..."
        return
    fi
    
    echo -e "${YELLOW}Запуск setup.sh...${NC}"
    echo ""
    
    bash "$PROJECT_DIR/setup.sh"
    
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

# Основной цикл
while true; do
    show_menu
    read choice
    
    case $choice in
        1) start_all ;;
        2) stop_all ;;
        3) restart_all ;;
        4) show_detailed_status ;;
        5) view_logs "" ;;
        6) view_logs "$SERVICE_WEBSITE" ;;
        7) view_logs "$SERVICE_POSTGRES" ;;
        8) view_logs "$SERVICE_DISCORD" ;;
        9) view_logs "$SERVICE_TELEGRAM" ;;
        10) shell_service ;;
        11) db_shell ;;
        12) health_check ;;
        13) backup_db ;;
        14) restore_db ;;
        15) build_images ;;
        16) rebuild_images ;;
        17) clean_containers ;;
        18) clean_all ;;
        19) install_deps ;;
        20) show_config ;;
        21) show_info ;;
        22) update_project ;;
        23) run_setup ;;
        0)
            echo -e "${GREEN}Выход...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Неверный выбор${NC}"
            sleep 1
            ;;
    esac
done
