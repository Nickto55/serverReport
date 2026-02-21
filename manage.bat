@echo off
REM ServerReport - Management Script for Windows
REM Helper script for common operations

setlocal enabledelayedexpansion

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "DOCKER_DIR=%SCRIPT_DIR%docker"

REM ==========================================================================
REM Helper functions
REM ==========================================================================

:show_help
    echo.
    echo ServerReport - Management Script
    echo.
    echo Usage: manage.bat [command] [options]
    echo.
    echo Commands:
    echo   start              - Start all services
    echo   stop               - Stop all services
    echo   restart            - Restart all services
    echo   status             - Show services status
    echo   logs [service]     - Show logs (website/postgres/discord/telegram)
    echo   shell [service]    - Connect to service shell
    echo   build              - Build all Docker images
    echo   rebuild            - Rebuild all Docker images
    echo   clean              - Stop and remove containers
    echo   health-check       - Check services health
    echo   backup-db          - Backup database
    echo   db-shell           - Connect to PostgreSQL
    echo   install-deps       - Install npm dependencies
    echo   help               - Show this help message
    echo.
    goto :eof

:start_services
    echo.
    echo Starting Services...
    echo.
    cd /d "%DOCKER_DIR%"
    docker-compose up -d
    echo [OK] Services started
    cd /d "%SCRIPT_DIR%"
    goto :eof

:stop_services
    echo.
    echo Stopping Services...
    echo.
    cd /d "%DOCKER_DIR%"
    docker-compose down
    echo [OK] Services stopped
    cd /d "%SCRIPT_DIR%"
    goto :eof

:restart_services
    echo.
    echo Restarting Services...
    echo.
    cd /d "%DOCKER_DIR%"
    docker-compose restart
    echo [OK] Services restarted
    cd /d "%SCRIPT_DIR%"
    goto :eof

:status_services
    echo.
    echo Services Status:
    echo.
    cd /d "%DOCKER_DIR%"
    docker-compose ps
    cd /d "%SCRIPT_DIR%"
    goto :eof

:show_logs
    setlocal enabledelayedexpansion
    set "service=%~1"
    
    echo.
    echo Showing Logs...
    echo.
    
    cd /d "%DOCKER_DIR%"
    
    if "!service!"=="" (
        echo [INFO] Showing all logs (Ctrl+C to exit)...
        docker-compose logs -f
    ) else if "!service!"=="website" (
        docker-compose logs -f website
    ) else if "!service!"=="postgres" (
        docker-compose logs -f postgres
    ) else if "!service!"=="db" (
        docker-compose logs -f postgres
    ) else if "!service!"=="discord" (
        docker-compose logs -f discord-bot
    ) else if "!service!"=="telegram" (
        docker-compose logs -f telegram-bot
    ) else (
        echo [ERROR] Unknown service: !service!
        echo Available: website, postgres, discord, telegram
    )
    
    cd /d "%SCRIPT_DIR%"
    endlocal
    goto :eof

:shell_service
    setlocal enabledelayedexpansion
    set "service=%~1"
    
    if "!service!"=="" (
        echo [ERROR] Please specify service: website, postgres, discord, telegram
        goto :eof
    )
    
    echo.
    echo Connecting to !service!...
    echo.
    
    cd /d "%DOCKER_DIR%"
    
    if "!service!"=="website" (
        docker-compose exec website cmd
    ) else if "!service!"=="postgres" (
        docker-compose exec postgres bash
    ) else if "!service!"=="db" (
        docker-compose exec postgres bash
    ) else if "!service!"=="discord" (
        docker-compose exec discord-bot cmd
    ) else if "!service!"=="telegram" (
        docker-compose exec telegram-bot cmd
    ) else (
        echo [ERROR] Unknown service: !service!
    )
    
    cd /d "%SCRIPT_DIR%"
    endlocal
    goto :eof

:build_images
    echo.
    echo Building Docker Images...
    echo.
    cd /d "%DOCKER_DIR%"
    docker-compose build
    echo [OK] Docker images built
    cd /d "%SCRIPT_DIR%"
    goto :eof

:rebuild_images
    echo.
    echo Rebuilding Docker Images...
    echo.
    cd /d "%DOCKER_DIR%"
    docker-compose build --no-cache
    echo [OK] Docker images rebuilt
    cd /d "%SCRIPT_DIR%"
    goto :eof

:clean_services
    echo.
    echo Cleaning Services...
    echo [WARNING] This will stop and remove containers but keep data
    echo.
    cd /d "%DOCKER_DIR%"
    docker-compose down
    echo [OK] Services cleaned
    cd /d "%SCRIPT_DIR%"
    goto :eof

:install_deps
    echo.
    echo Installing Local Dependencies...
    echo.
    
    if exist "%SCRIPT_DIR%website\" (
        echo [INFO] Installing dependencies in website...
        cd /d "%SCRIPT_DIR%website"
        call npm install
    )
    
    if exist "%SCRIPT_DIR%discord-bot\" (
        echo [INFO] Installing dependencies in discord-bot...
        cd /d "%SCRIPT_DIR%discord-bot"
        call npm install
    )
    
    if exist "%SCRIPT_DIR%telegram-bot\" (
        echo [INFO] Installing dependencies in telegram-bot...
        cd /d "%SCRIPT_DIR%telegram-bot"
        call npm install
    )
    
    echo [OK] Dependencies installed
    cd /d "%SCRIPT_DIR%"
    goto :eof

:db_shell
    echo.
    echo PostgreSQL Shell...
    echo.
    
    cd /d "%DOCKER_DIR%"
    
    REM Get DB credentials from .env
    for /f "tokens=2 delims==" %%i in ('findstr /R "^DB_USER=" "%SCRIPT_DIR%config\.env"') do set "DB_USER=%%i"
    for /f "tokens=2 delims==" %%i in ('findstr /R "^DB_NAME=" "%SCRIPT_DIR%config\.env"') do set "DB_NAME=%%i"
    
    docker-compose exec postgres psql -U !DB_USER! -d !DB_NAME!
    
    cd /d "%SCRIPT_DIR%"
    goto :eof

:health_check
    echo.
    echo Health Check...
    echo.
    
    cd /d "%DOCKER_DIR%"
    
    echo [INFO] Checking services...
    
    docker-compose exec -T postgres pg_isready -U serverreport >nul 2>&1
    if !errorlevel! equ 0 (
        echo [OK] PostgreSQL is healthy
    ) else (
        echo [ERROR] PostgreSQL is not responding
    )
    
    curl -s http://localhost:3000/health >nul 2>&1
    if !errorlevel! equ 0 (
        echo [OK] Website is healthy
    ) else (
        echo [WARNING] Website is not responding
    )
    
    docker-compose ps | find "discord-bot" | find "Up" >nul
    if !errorlevel! equ 0 (
        echo [OK] Discord bot is running
    ) else (
        echo [WARNING] Discord bot is not running
    )
    
    docker-compose ps | find "telegram-bot" | find "Up" >nul
    if !errorlevel! equ 0 (
        echo [OK] Telegram bot is running
    ) else (
        echo [WARNING] Telegram bot is not running
    )
    
    cd /d "%SCRIPT_DIR%"
    goto :eof

:backup_db
    echo.
    echo Database Backup...
    echo.
    
    REM Create backups directory
    if not exist "%SCRIPT_DIR%backups" mkdir "%SCRIPT_DIR%backups"
    
    REM Generate timestamp
    for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
    for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
    
    set "BACKUP_FILE=%SCRIPT_DIR%backups\serverreport_!mydate!_!mytime!.sql"
    
    echo [INFO] Creating backup...
    
    cd /d "%DOCKER_DIR%"
    
    REM Get DB credentials from .env
    for /f "tokens=2 delims==" %%i in ('findstr /R "^DB_USER=" "%SCRIPT_DIR%config\.env"') do set "DB_USER=%%i"
    for /f "tokens=2 delims==" %%i in ('findstr /R "^DB_NAME=" "%SCRIPT_DIR%config\.env"') do set "DB_NAME=%%i"
    
    docker-compose exec -T postgres pg_dump -U !DB_USER! !DB_NAME! > "!BACKUP_FILE!"
    
    echo [OK] Database backed up to: !BACKUP_FILE!
    
    cd /d "%SCRIPT_DIR%"
    goto :eof

REM ==========================================================================
REM Main
REM ==========================================================================

:main
    setlocal enabledelayedexpansion
    
    set "cmd=%~1"
    
    if "!cmd!"=="" (
        call :show_help
        goto :end
    )
    
    if "!cmd!"=="start" (
        call :start_services
    ) else if "!cmd!"=="stop" (
        call :stop_services
    ) else if "!cmd!"=="restart" (
        call :restart_services
    ) else if "!cmd!"=="status" (
        call :status_services
    ) else if "!cmd!"=="logs" (
        call :show_logs "%~2"
    ) else if "!cmd!"=="shell" (
        call :shell_service "%~2"
    ) else if "!cmd!"=="build" (
        call :build_images
    ) else if "!cmd!"=="rebuild" (
        call :rebuild_images
    ) else if "!cmd!"=="clean" (
        call :clean_services
    ) else if "!cmd!"=="install-deps" (
        call :install_deps
    ) else if "!cmd!"=="db-shell" (
        call :db_shell
    ) else if "!cmd!"=="health-check" (
        call :health_check
    ) else if "!cmd!"=="backup-db" (
        call :backup_db
    ) else if "!cmd!"=="help" (
        call :show_help
    ) else (
        echo [ERROR] Unknown command: !cmd!
        echo.
        call :show_help
        exit /b 1
    )
    
    :end
    endlocal
    exit /b 0
