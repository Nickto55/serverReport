#!/bin/bash

# ServerReport Website Setup Script
# Скрипт настройки проекта сайта из Git репозитория

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Пути
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WEBSITE_DIR="$SCRIPT_DIR"
TEMP_DIR="/tmp/serverreport_website_temp"

# Глобальные переменные
AUTHENTICATED_GIT_URL=""

# Функция вывода заголовка
show_header() {
    clear
    echo -e "${WHITE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║${NC}        ${CYAN}ServerReport Website Setup${NC}                    ${WHITE}║${NC}"
    echo -e "${WHITE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Функция проверки установленного Git
check_git() {
    if ! command -v git &> /dev/null; then
        echo -e "${RED}✗ Git не установлен${NC}"
        echo -e "${YELLOW}Установите Git: https://git-scm.com/downloads${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ Git установлен${NC}"
    return 0
}

# Функция запроса Git URL
get_git_url() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}" >&2
    echo -e "${WHITE}Введите URL Git репозитория с проектом сайта${NC}" >&2
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}" >&2
    echo "" >&2
    echo -e "${YELLOW}Примеры:${NC}" >&2
    echo -e "  ${GREEN}Публичный HTTPS:${NC} https://github.com/username/project.git" >&2
    echo -e "  ${GREEN}SSH:${NC}          git@github.com:username/project.git" >&2
    echo "" >&2
    echo -n -e "${WHITE}URL репозитория: ${NC}" >&2
    read git_url
    
    if [ -z "$git_url" ]; then
        echo -e "${RED}✗ URL не может быть пустым${NC}" >&2
        return 1
    fi
    
    # Только URL выводим в stdout
    echo "$git_url"
    return 0
}

# Функция аутентификации для HTTPS репозиториев
authenticate_https() {
    local git_url=$1
    
    echo "" >&2
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}" >&2
    echo -e "${CYAN}  Аутентификация${NC}" >&2
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}" >&2
    echo "" >&2
    
    echo -e "${YELLOW}Репозиторий требует аутентификацию${NC}" >&2
    echo "" >&2
    echo -e "${WHITE}Выберите метод аутентификации:${NC}" >&2
    echo -e "  ${CYAN}1.${NC} Personal Access Token (рекомендуется)" >&2
    echo -e "  ${CYAN}2.${NC} Имя пользователя и пароль" >&2
    echo -e "  ${CYAN}3.${NC} Пропустить (попробовать без аутентификации)" >&2
    echo "" >&2
    echo -n -e "${WHITE}Выбор (1-3): ${NC}" >&2
    read auth_choice
    
    case $auth_choice in
        1)
            echo "" >&2
            echo -e "${YELLOW}Как получить Personal Access Token:${NC}" >&2
            echo -e "  ${CYAN}GitHub:${NC} Settings → Developer settings → Personal access tokens → Generate new token" >&2
            echo -e "  ${CYAN}GitLab:${NC} Settings → Access Tokens → Add new token" >&2
            echo -e "  ${CYAN}Bitbucket:${NC} Settings → App passwords → Create app password" >&2
            echo "" >&2
            echo -n -e "${WHITE}Введите токен: ${NC}" >&2
            read -s token
            echo "" >&2
            
            if [ -z "$token" ]; then
                echo -e "${RED}✗ Токен не может быть пустым${NC}" >&2
                return 1
            fi
            
            # Добавляем токен в URL
            if [[ $git_url =~ ^https://github.com/ ]]; then
                # GitHub формат: https://token@github.com/...
                authenticated_url=$(echo "$git_url" | sed "s|https://|https://${token}@|")
            elif [[ $git_url =~ ^https://gitlab.com/ ]]; then
                # GitLab формат: https://oauth2:token@gitlab.com/...
                authenticated_url=$(echo "$git_url" | sed "s|https://|https://oauth2:${token}@|")
            else
                # Общий формат
                authenticated_url=$(echo "$git_url" | sed "s|https://|https://${token}@|")
            fi
            
            # Только URL выводим в stdout
            echo "$authenticated_url"
            return 0
            ;;
        2)
            echo "" >&2
            echo -n -e "${WHITE}Имя пользователя: ${NC}" >&2
            read username
            echo -n -e "${WHITE}Пароль: ${NC}" >&2
            read -s password
            echo "" >&2
            
            if [ -z "$username" ] || [ -z "$password" ]; then
                echo -e "${RED}✗ Имя пользователя и пароль не могут быть пустыми${NC}" >&2
                return 1
            fi
            
            # Добавляем credentials в URL
            authenticated_url=$(echo "$git_url" | sed "s|https://|https://${username}:${password}@|")
            # Только URL выводим в stdout
            echo "$authenticated_url"
            return 0
            ;;
        3)
            # Только URL выводим в stdout
            echo "$git_url"
            return 0
            ;;
        *)
            echo -e "${RED}✗ Неверный выбор${NC}" >&2
            return 1
            ;;
    esac
}

# Функция проверки доступности репозитория
check_repository_access() {
    local git_url=$1
    local is_retry=${2:-false}
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Проверка доступности репозитория${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}Проверка подключения к репозиторию...${NC}"
    
    # Проверка доступности репозитория без клонирования
    local error_output=$(git ls-remote "$git_url" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}✗ Не удалось подключиться к репозиторию${NC}"
        echo ""
        
        # Анализ ошибки
        if [[ $error_output == *"Authentication failed"* ]] || [[ $error_output == *"could not read Username"* ]] || [[ $error_output == *"403"* ]]; then
            echo -e "${YELLOW}⚠ Требуется аутентификация${NC}"
            echo ""
            
            if [ "$is_retry" = false ]; then
                # Предлагаем аутентификацию только если это HTTPS URL
                if [[ $git_url == https://* ]]; then
                    authenticated_url=$(authenticate_https "$git_url")
                    if [ $? -eq 0 ] && [ ! -z "$authenticated_url" ]; then
                        # Повторная проверка с аутентификацией
                        check_repository_access "$authenticated_url" true
                        return $?
                    else
                        return 1
                    fi
                else
                    echo -e "${YELLOW}Решения:${NC}"
                    echo -e "  ${CYAN}1.${NC} Для SSH: Настройте SSH ключи в вашем Git аккаунте"
                    echo -e "     ${WHITE}ssh-keygen -t ed25519 -C \"your_email@example.com\"${NC}"
                    echo -e "     ${WHITE}cat ~/.ssh/id_ed25519.pub${NC} - добавьте в GitHub/GitLab"
                    echo -e "  ${CYAN}2.${NC} Используйте HTTPS URL с токеном доступа"
                    echo ""
                    return 1
                fi
            else
                return 1
            fi
        elif [[ $error_output == *"Repository not found"* ]] || [[ $error_output == *"404"* ]]; then
            echo -e "${YELLOW}Причина:${NC} Репозиторий не найден"
            echo ""
            echo -e "${YELLOW}Проверьте:${NC}"
            echo -e "  ${CYAN}•${NC} Правильность URL репозитория"
            echo -e "  ${CYAN}•${NC} Существование репозитория"
            echo -e "  ${CYAN}•${NC} Права доступа (если приватный)"
            echo ""
            return 1
        elif [[ $error_output == *"Could not resolve host"* ]] || [[ $error_output == *"Temporary failure in name resolution"* ]]; then
            echo -e "${YELLOW}Причина:${NC} Проблемы с сетевым подключением"
            echo ""
            echo -e "${YELLOW}Проверьте:${NC}"
            echo -e "  ${CYAN}•${NC} Подключение к интернету"
            echo -e "  ${CYAN}•${NC} DNS настройки"
            echo -e "  ${CYAN}•${NC} Firewall/прокси настройки"
            echo ""
            return 1
        else
            echo -e "${YELLOW}Возможные причины:${NC}"
            echo -e "  ${RED}•${NC} Неверный URL репозитория"
            echo -e "  ${RED}•${NC} Репозиторий не существует или приватный"
            echo -e "  ${RED}•${NC} Нет прав доступа к репозиторию"
            echo -e "  ${RED}•${NC} Проблемы с сетевым подключением"
            echo -e "  ${RED}•${NC} Требуется аутентификация (SSH ключ или токен)"
            echo ""
            echo -e "${YELLOW}Детали ошибки:${NC}"
            echo -e "${WHITE}$error_output${NC}"
            echo ""
            
            # Предлагаем решения для HTTPS
            if [[ $git_url == https://* ]] && [ "$is_retry" = false ]; then
                echo -e "${CYAN}Попробовать аутентификацию? (y/n): ${NC}"
                read try_auth
                if [[ $try_auth =~ ^[Yy]$ ]]; then
                    authenticated_url=$(authenticate_https "$git_url")
                    if [ $? -eq 0 ] && [ ! -z "$authenticated_url" ]; then
                        check_repository_access "$authenticated_url" true
                        return $?
                    fi
                fi
            fi
            
            return 1
        fi
    fi
    
    echo -e "${GREEN}✓ Репозиторий доступен${NC}"
    
    # Сохраняем аутентифицированный URL для использования в клонировании
    AUTHENTICATED_GIT_URL="$git_url"
    
    return 0
}

# Функция проверки существующего проекта
check_existing_project() {
    # Проверяем файлы, исключая setup_website.sh, WEBSITE.md и .env
    local has_files=0
    for file in "$WEBSITE_DIR"/*; do
        filename=$(basename "$file")
        if [ "$filename" != "setup_website.sh" ] && [ "$filename" != "WEBSITE.md" ] && [ "$filename" != ".env" ] && [ "$filename" != "README.md" ]; then
            has_files=1
            break
        fi
    done
    
    if [ $has_files -eq 1 ]; then
        return 0  # Проект существует
    else
        return 1  # Проект не существует
    fi
}

# Функция обновления существующего проекта
update_project() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Обновление проекта${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Проверка наличия .git директории
    if [ ! -d "$WEBSITE_DIR/.git" ]; then
        echo -e "${RED}✗ Проект не является Git репозиторием${NC}"
        echo -e "${YELLOW}Невозможно обновить проект через git pull${NC}"
        echo -e "${WHITE}Используйте переустановку для обновления${NC}"
        echo ""
        return 1
    fi
    
    cd "$WEBSITE_DIR" || return 1
    
    # Проверка текущего remote URL
    echo -e "${YELLOW}Текущий репозиторий:${NC}"
    git remote -v | head -n 1
    echo ""
    
    # Сохранение изменений в .env если есть
    local env_changed=0
    if [ -f ".env" ]; then
        if git diff --quiet .env 2>/dev/null; then
            :  # .env не изменен
        else
            env_changed=1
            echo -e "${YELLOW}⚠ Обнаружены изменения в .env файле${NC}"
        fi
    fi
    
    # Сохранение локальных изменений
    echo -e "${YELLOW}Проверка локальных изменений...${NC}"
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo -e "${YELLOW}⚠ Обнаружены локальные изменения${NC}"
        echo -n -e "${WHITE}Сохранить изменения в stash? (y/n): ${NC}"
        read stash_confirm
        
        if [[ $stash_confirm =~ ^[Yy]$ ]]; then
            git stash push -m "Auto-stash before update $(date +%Y%m%d_%H%M%S)"
            echo -e "${GREEN}✓ Изменения сохранены в stash${NC}"
        fi
    fi
    
    # Получение обновлений
    echo ""
    echo -e "${YELLOW}Получение обновлений из репозитория...${NC}"
    
    if git pull; then
        echo -e "${GREEN}✓ Проект успешно обновлен${NC}"
        
        # Проверка изменений в package.json
        if git log HEAD@{1}..HEAD --name-only | grep -q "package.json"; then
            echo ""
            echo -e "${YELLOW}⚠ Обнаружены изменения в package.json${NC}"
            echo -n -e "${WHITE}Обновить зависимости? (y/n): ${NC}"
            read update_deps
            
            if [[ $update_deps =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Обновление зависимостей...${NC}"
                npm install
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ Зависимости обновлены${NC}"
                else
                    echo -e "${RED}✗ Ошибка при обновлении зависимостей${NC}"
                fi
            fi
        fi
        
        # Предложение перезапустить контейнеры
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✓ Обновление завершено успешно!${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${WHITE}Рекомендуется перезапустить контейнеры:${NC}"
        echo -e "  ${BLUE}cd $PROJECT_DIR/docker${NC}"
        echo -e "  ${BLUE}docker-compose restart website${NC}"
        echo ""
        
        cd "$PROJECT_DIR" || return
        return 0
    else
        echo -e "${RED}✗ Ошибка при обновлении проекта${NC}"
        echo ""
        echo -e "${YELLOW}Возможные причины:${NC}"
        echo -e "  ${CYAN}•${NC} Конфликты с локальными изменениями"
        echo -e "  ${CYAN}•${NC} Проблемы с подключением к репозиторию"
        echo -e "  ${CYAN}•${NC} Требуется аутентификация"
        echo ""
        
        cd "$PROJECT_DIR" || return
        return 1
    fi
}

# Функция меню для существующего проекта
show_update_menu() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}⚠ Обнаружен существующий проект сайта${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}Выберите действие:${NC}"
    echo -e "  ${CYAN}1.${NC} Обновить существующий проект (git pull)"
    echo -e "  ${CYAN}2.${NC} Переустановить проект (удалить и установить заново)"
    echo -e "  ${CYAN}3.${NC} Отмена"
    echo ""
    echo -n -e "${WHITE}Выбор (1-3): ${NC}"
    read action_choice
    
    case $action_choice in
        1)
            return 1  # Обновление
            ;;
        2)
            return 2  # Переустановка
            ;;
        3|*)
            return 0  # Отмена
            ;;
    esac
}

# Функция резервного копирования существующего проекта
backup_existing() {
    echo -e "${YELLOW}Найден существующий проект сайта${NC}"
    echo -n -e "${WHITE}Создать резервную копию перед переустановкой? (y/n): ${NC}"
    read backup_confirm
    
    if [[ $backup_confirm =~ ^[Yy]$ ]]; then
        BACKUP_DIR="$PROJECT_DIR/website_backup_$(date +%Y%m%d_%H%M%S)"
        echo -e "${YELLOW}Создание резервной копии в: $BACKUP_DIR${NC}"
        mkdir -p "$BACKUP_DIR"
        
        # Копируем все кроме setup_website.sh, WEBSITE.md и .env
        for file in "$WEBSITE_DIR"/*; do
            filename=$(basename "$file")
            if [ "$filename" != "setup_website.sh" ] && [ "$filename" != "WEBSITE.md" ] && [ "$filename" != ".env" ] && [ "$filename" != "README.md" ]; then
                cp -r "$file" "$BACKUP_DIR/"
            fi
        done
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Резервная копия создана${NC}"
        else
            echo -e "${RED}✗ Ошибка при создании резервной копии${NC}"
            return 1
        fi
    fi
    
    return 0
}

# Функция клонирования репозитория
clone_repository() {
    # Используем аутентифицированный URL если доступен, иначе оригинальный
    local git_url="${AUTHENTICATED_GIT_URL:-$1}"
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Клонирование репозитория${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Очистка и создание временной директории
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    echo -e "${YELLOW}Клонирование проекта...${NC}"
    
    # Переходим во временную директорию и клонируем прямо в неё
    cd "$TEMP_DIR" || return 1
    
    # Клонирование с перенаправлением вывода в файл (для безопасности токенов)
    # Используем "." чтобы клонировать содержимое прямо в текущую директорию
    if git clone "$git_url" . > /tmp/git_clone_output_$$.log 2>&1; then
        local clone_status=0
    else
        local clone_status=$?
        # Показываем ошибки, но фильтруем URL с токенами
        if [ -f /tmp/git_clone_output_$$.log ]; then
            grep -v "http" /tmp/git_clone_output_$$.log | tail -5
        fi
    fi
    
    # Удаляем лог файл
    rm -f /tmp/git_clone_output_$$.log
    
    # Возвращаемся обратно
    cd "$SCRIPT_DIR" || return 1
    
    if [ $clone_status -ne 0 ]; then
        echo -e "${RED}✗ Ошибка при клонировании репозитория${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # Проверяем, что файлы действительно клонировались (исключая только .git)
    local file_count=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' 2>/dev/null | wc -l)
    
    if [ "$file_count" -eq 0 ]; then
        echo -e "${RED}✗ Репозиторий пустой или не содержит файлов${NC}"
        echo -e "${YELLOW}Проверьте содержимое репозитория в браузере${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    echo -e "${GREEN}✓ Репозиторий успешно клонирован (файлов: $file_count)${NC}"
    
    # Очищаем переменную с credentials из памяти
    unset AUTHENTICATED_GIT_URL
    
    return 0
}

# Функция проверки структуры проекта
validate_project() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Проверка совместимости проекта${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local has_errors=0
    local warnings=()
    local errors=()
    
    # 1. Проверка обязательных файлов
    echo -e "${YELLOW}[1/5] Проверка обязательных файлов...${NC}"
    local required_files=("package.json" "server.js")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$TEMP_DIR/$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        echo -e "${RED}  ✗ Отсутствуют обязательные файлы:${NC}"
        for file in "${missing_files[@]}"; do
            echo -e "    ${RED}•${NC} $file"
            errors+=("Отсутствует файл: $file")
        done
        has_errors=1
    else
        echo -e "${GREEN}  ✓ Все обязательные файлы присутствуют${NC}"
    fi
    
    # 2. Проверка package.json
    echo -e "${YELLOW}[2/5] Проверка package.json...${NC}"
    if [ -f "$TEMP_DIR/package.json" ]; then
        # Проверка на валидность JSON
        if ! python3 -m json.tool "$TEMP_DIR/package.json" > /dev/null 2>&1 && ! node -e "require('$TEMP_DIR/package.json')" > /dev/null 2>&1; then
            echo -e "${RED}  ✗ package.json содержит невалидный JSON${NC}"
            errors+=("package.json содержит ошибки синтаксиса")
            has_errors=1
        else
            # Проверка обязательных зависимостей
            local required_deps=("express" "pg" "dotenv")
            local missing_deps=()
            
            for dep in "${required_deps[@]}"; do
                if ! grep -q "\"$dep\"" "$TEMP_DIR/package.json"; then
                    missing_deps+=("$dep")
                fi
            done
            
            if [ ${#missing_deps[@]} -gt 0 ]; then
                echo -e "${YELLOW}  ⚠ Отсутствуют рекомендуемые зависимости:${NC}"
                for dep in "${missing_deps[@]}"; do
                    echo -e "    ${YELLOW}•${NC} $dep"
                    warnings+=("Отсутствует зависимость: $dep")
                done
            else
                echo -e "${GREEN}  ✓ Основные зависимости присутствуют${NC}"
            fi
            
            # Проверка scripts
            if ! grep -q '"scripts"' "$TEMP_DIR/package.json"; then
                echo -e "${YELLOW}  ⚠ Не найден раздел 'scripts' в package.json${NC}"
                warnings+=("Отсутствует раздел scripts")
            fi
        fi
    fi
    
    # 3. Проверка структуры директорий
    echo -e "${YELLOW}[3/5] Проверка структуры директорий...${NC}"
    local recommended_dirs=("routes" "middleware")
    local missing_dirs=()
    
    for dir in "${recommended_dirs[@]}"; do
        if [ ! -d "$TEMP_DIR/$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [ ${#missing_dirs[@]} -gt 0 ]; then
        echo -e "${YELLOW}  ⚠ Отсутствуют рекомендуемые директории:${NC}"
        for dir in "${missing_dirs[@]}"; do
            echo -e "    ${YELLOW}•${NC} $dir/"
            warnings+=("Отсутствует директория: $dir/")
        done
    else
        echo -e "${GREEN}  ✓ Структура директорий соответствует рекомендациям${NC}"
    fi
    
    # 4. Проверка server.js
    echo -e "${YELLOW}[4/5] Проверка server.js...${NC}"
    if [ -f "$TEMP_DIR/server.js" ]; then
        # Проверка на наличие основных компонентов Express
        if ! grep -q "express" "$TEMP_DIR/server.js"; then
            echo -e "${RED}  ✗ server.js не использует Express${NC}"
            errors+=("server.js не содержит импорт Express")
            has_errors=1
        else
            echo -e "${GREEN}  ✓ server.js использует Express${NC}"
        fi
        
        # Проверка на наличие app.listen
        if ! grep -q "listen" "$TEMP_DIR/server.js"; then
            echo -e "${YELLOW}  ⚠ server.js может не запускать сервер${NC}"
            warnings+=("Не найден вызов app.listen()")
        fi
    fi
    
    # 5. Проверка на наличие Dockerfile (опционально)
    echo -e "${YELLOW}[5/5] Проверка Docker конфигурации...${NC}"
    if [ ! -f "$TEMP_DIR/Dockerfile" ]; then
        echo -e "${YELLOW}  ⚠ Dockerfile не найден (будет использован стандартный)${NC}"
        warnings+=("Dockerfile отсутствует")
    else
        echo -e "${GREEN}  ✓ Dockerfile присутствует${NC}"
    fi
    
    # Вывод результатов проверки
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}Результаты проверки совместимости:${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    
    # Критические ошибки
    if [ $has_errors -eq 1 ]; then
        echo ""
        echo -e "${RED}КРИТИЧЕСКИЕ ОШИБКИ (${#errors[@]}):${NC}"
        for error in "${errors[@]}"; do
            echo -e "  ${RED}✗${NC} $error"
        done
    fi
    
    # Предупреждения
    if [ ${#warnings[@]} -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}ПРЕДУПРЕЖДЕНИЯ (${#warnings[@]}):${NC}"
        for warning in "${warnings[@]}"; do
            echo -e "  ${YELLOW}⚠${NC} $warning"
        done
    fi
    
    echo ""
    
    # Финальное решение
    if [ $has_errors -eq 1 ]; then
        echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  ✗ ПРОЕКТ НЕСОВМЕСТИМ                                     ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}Проект не может быть установлен из-за критических ошибок.${NC}"
        echo -e "${WHITE}Убедитесь, что репозиторий содержит Express.js приложение${NC}"
        echo -e "${WHITE}с необходимыми файлами: package.json и server.js${NC}"
        return 1
    elif [ ${#warnings[@]} -gt 0 ]; then
        echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║  ⚠ ПРОЕКТ СОВМЕСТИМ С ПРЕДУПРЕЖДЕНИЯМИ                    ║${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -n -e "${WHITE}Продолжить установку? (y/n): ${NC}"
        read confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Установка отменена пользователем${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  ✓ ПРОЕКТ ПОЛНОСТЬЮ СОВМЕСТИМ                             ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    fi
    
    return 0
}

# Функция копирования файлов
copy_project() {
    echo ""
    echo -e "${YELLOW}Копирование файлов проекта...${NC}"
    
    # Сохраняем файлы, которые не нужно удалять
    local preserve_files=("setup_website.sh" "WEBSITE.md" ".env")
    
    # Удаляем все файлы кроме сохраняемых
    for file in "$WEBSITE_DIR"/*; do
        filename=$(basename "$file")
        local should_delete=1
        
        for preserve in "${preserve_files[@]}"; do
            if [ "$filename" = "$preserve" ]; then
                should_delete=0
                break
            fi
        done
        
        if [ $should_delete -eq 1 ]; then
            rm -rf "$file"
        fi
    done
    
    # Копирование файлов (исключая .git)
    rsync -av --exclude='.git' "$TEMP_DIR/" "$WEBSITE_DIR/"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Ошибка при копировании файлов${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Файлы успешно скопированы${NC}"
    
    # Очистка временной директории
    rm -rf "$TEMP_DIR"
    
    return 0
}

# Функция установки зависимостей
install_dependencies() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Установка зависимостей${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -n -e "${WHITE}Установить npm зависимости? (y/n): ${NC}"
    read install_confirm
    
    if [[ $install_confirm =~ ^[Yy]$ ]]; then
        cd "$WEBSITE_DIR" || return 1
        
        echo -e "${YELLOW}Установка зависимостей...${NC}"
        npm install
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Зависимости установлены${NC}"
        else
            echo -e "${RED}✗ Ошибка при установке зависимостей${NC}"
            cd "$PROJECT_DIR" || return
            return 1
        fi
        
        cd "$PROJECT_DIR" || return
    else
        echo -e "${YELLOW}Установка зависимостей пропущена${NC}"
    fi
    
    return 0
}

# Функция создания .env файла
setup_env() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Настройка конфигурации${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Запрос имени главного файла
    echo -e "${WHITE}Укажите имя главного HTML файла в директории public/${NC}"
    echo -n -e "${WHITE}Главный файл (по умолчанию 'index.html'): ${NC}"
    read main_html_file
    
    if [ -z "$main_html_file" ]; then
        main_html_file="index.html"
    fi
    
    echo ""
    
    if [ ! -f "$WEBSITE_DIR/.env" ]; then
        echo -e "${YELLOW}Создание .env файла...${NC}"
        
        cat > "$WEBSITE_DIR/.env" << EOF
# Server Configuration
PORT=3000
NODE_ENV=production
MAIN_HTML=$main_html_file

# Database Configuration
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/serverreport

# JWT Configuration
JWT_SECRET=$(openssl rand -hex 32)
JWT_EXPIRES_IN=7d

# CORS Configuration
CORS_ORIGIN=*
EOF
        
        echo -e "${GREEN}✓ Файл .env создан${NC}"
    else
        echo -e "${YELLOW}Файл .env уже существует${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Главный файл установлен: ${CYAN}$main_html_file${NC}"
    echo -e "${YELLOW}Разместите статические файлы в ${CYAN}$WEBSITE_DIR/public/${NC}"
    echo ""
    echo -e "${YELLOW}Отредактируйте $WEBSITE_DIR/.env для изменения настроек${NC}"
}

# Основная функция
main() {
    show_header
    
    # Проверка Git
    if ! check_git; then
        echo ""
        read -p "Нажмите Enter для выхода..."
        exit 1
    fi
    
    echo ""
    
    # Проверка существующего проекта
    if check_existing_project; then
        show_update_menu
        menu_result=$?
        
        case $menu_result in
            0)  # Отмена
                echo -e "${YELLOW}Операция отменена${NC}"
                echo ""
                read -p "Нажмите Enter для выхода..."
                exit 0
                ;;
            1)  # Обновление
                if update_project; then
                    echo ""
                    read -p "Нажмите Enter для выхода..."
                    exit 0
                else
                    echo ""
                    read -p "Нажмите Enter для выхода..."
                    exit 1
                fi
                ;;
            2)  # Переустановка
                echo ""
                echo -e "${YELLOW}Переустановка проекта...${NC}"
                echo ""
                # Создание резервной копии
                if ! backup_existing; then
                    echo ""
                    read -p "Нажмите Enter для выхода..."
                    exit 1
                fi
                # Продолжаем с обычной установкой
                ;;
        esac
    fi
    
    # Получение URL репозитория
    git_url=$(get_git_url)
    if [ $? -ne 0 ]; then
        echo ""
        read -p "Нажмите Enter для выхода..."
        exit 1
    fi
    
    # Проверка доступности репозитория
    if ! check_repository_access "$git_url"; then
        echo ""
        read -p "Нажмите Enter для выхода..."
        exit 1
    fi
    
    # Клонирование репозитория
    if ! clone_repository "$git_url"; then
        echo ""
        read -p "Нажмите Enter для выхода..."
        exit 1
    fi
    
    # Проверка структуры проекта
    if ! validate_project; then
        echo -e "${RED}✗ Проект не соответствует требуемой структуре${NC}"
        rm -rf "$TEMP_DIR"
        echo ""
        read -p "Нажмите Enter для выхода..."
        exit 1
    fi
    
    # Копирование файлов
    if ! copy_project; then
        echo ""
        read -p "Нажмите Enter для выхода..."
        exit 1
    fi
    
    # Установка зависимостей
    install_dependencies
    
    # Настройка .env
    setup_env
    
    # Завершение
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Настройка сайта завершена успешно!${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}Следующие шаги:${NC}"
    echo -e "  1. Проверьте конфигурацию в ${BLUE}$WEBSITE_DIR/.env${NC}"
    echo -e "  2. Разместите статические файлы (HTML/CSS/JS) в ${BLUE}$WEBSITE_DIR/public/${NC}"
    echo -e "  3. Пересоберите Docker контейнер:"
    echo -e "     ${BLUE}cd $PROJECT_DIR/docker${NC}"
    echo -e "     ${BLUE}docker-compose build --no-cache website${NC}"
    echo -e "     ${BLUE}docker-compose up -d${NC}"
    echo -e "  4. Проверьте работу сайта на ${BLUE}http://localhost${NC}"
    echo ""
    
    read -p "Нажмите Enter для выхода..."
}

# Запуск
main
