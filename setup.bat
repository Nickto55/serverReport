@echo off
REM ServerReport - Complete Setup Script for Windows
REM This script handles full project initialization and configuration

setlocal enabledelayedexpansion
cd /d "%~dp0"

REM Colors and variables
set "SCRIPT_DIR=%~dp0"
set "ENV_FILE=%SCRIPT_DIR%config\.env"

REM ==========================================================================
REM Helper functions
REM ==========================================================================

:header
    echo.
    echo ========================================================
    echo %~1
    echo ========================================================
    echo.
    goto :eof

:success
    echo [OK] %~1
    goto :eof

:error
    echo [ERROR] %~1
    goto :eof

:warning
    echo [WARNING] %~1
    goto :eof

:info
    echo [INFO] %~1
    goto :eof

REM ==========================================================================
REM Check prerequisites
REM ==========================================================================

:main
    call :header "ServerReport - Complete Setup"
    
    call :header "Step 1: Checking Prerequisites"
    
    setlocal enabledelayedexpansion
    set missing_tools=0
    
    REM Check Docker
    docker --version >nul 2>&1
    if errorlevel 1 (
        call :error "Docker is not installed"
        set /a missing_tools+=1
    ) else (
        call :success "Docker is installed"
    )
    
    REM Check Docker Compose
    docker-compose --version >nul 2>&1
    if errorlevel 1 (
        call :error "Docker Compose is not installed"
        set /a missing_tools+=1
    ) else (
        call :success "Docker Compose is installed"
    )
    
    REM Check Git
    git --version >nul 2>&1
    if errorlevel 1 (
        call :error "Git is not installed"
        set /a missing_tools+=1
    ) else (
        call :success "Git is installed"
    )
    
    if !missing_tools! gtr 0 (
        call :error "Please install missing tools and try again"
        exit /b 1
    )
    
    call :success "All prerequisites are installed"
    
    REM ==========================================================================
    REM Create .env file
    REM ==========================================================================
    
    call :header "Step 2: Configuring Environment Variables"
    
    if exist "%ENV_FILE%" (
        call :info ".env file already exists"
        set /p reconfigure="Do you want to reconfigure it? (y/n) [n]: "
        if "!reconfigure!"=="y" (
            del "%ENV_FILE%"
        ) else (
            call :info "Keeping existing .env file"
            goto :skip_env
        )
    )
    
    if not exist "%ENV_FILE%" (
        call :info "Creating .env file from template..."
        
        if not exist "%SCRIPT_DIR%config\.env.example" (
            call :error ".env.example not found!"
            exit /b 1
        )
        
        copy "%SCRIPT_DIR%config\.env.example" "%ENV_FILE%" >nul
        
        REM Database configuration
        call :header "Database Configuration"
        set /p DB_USER="Database user [serverreport]: "
        if "!DB_USER!"=="" set "DB_USER=serverreport"
        
        set /p DB_PASSWORD="Database password [serverreport_pass]: "
        if "!DB_PASSWORD!"=="" set "DB_PASSWORD=serverreport_pass"
        
        set /p DB_NAME="Database name [serverreport]: "
        if "!DB_NAME!"=="" set "DB_NAME=serverreport"
        
        set /p DB_PORT="Database port [5432]: "
        if "!DB_PORT!"=="" set "DB_PORT=5432"
        
        REM Website configuration
        call :header "Website Configuration"
        set /p WEBSITE_PORT="Website port [3000]: "
        if "!WEBSITE_PORT!"=="" set "WEBSITE_PORT=3000"
        
        set /p NODE_ENV="Node environment [development]: "
        if "!NODE_ENV!"=="" set "NODE_ENV=development"
        
        REM Bot configuration
        call :header "Discord Bot Configuration"
        call :warning "Get your Discord bot token from: https://discord.com/developers/applications"
        set /p DISCORD_TOKEN="Discord bot token: "
        
        if "!DISCORD_TOKEN!"=="" (
            call :warning "Discord token is empty - bot won't work without it"
        )
        
        call :header "Telegram Bot Configuration"
        call :warning "Get your Telegram bot token from: https://t.me/BotFather"
        set /p TELEGRAM_TOKEN="Telegram bot token: "
        
        if "!TELEGRAM_TOKEN!"=="" (
            call :warning "Telegram token is empty - bot won't work without it"
        )
        
        REM Security configuration
        call :header "Security Configuration"
        call :info "JWT secret (press Enter to use default)"
        set /p JWT_SECRET="JWT secret [auto-generated]: "
        if "!JWT_SECRET!"=="" set "JWT_SECRET=your_jwt_secret_key_change_this_in_production"
        
        set /p ADMIN_USER="Admin username [admin]: "
        if "!ADMIN_USER!"=="" set "ADMIN_USER=admin"
        
        set /p ADMIN_PASSWORD="Admin password [admin_password]: "
        if "!ADMIN_PASSWORD!"=="" set "ADMIN_PASSWORD=admin_password_change_this"
        
        REM Update .env file using PowerShell
        call :info "Updating .env file..."
        
        powershell -Command "(Get-Content '%ENV_FILE%') -replace '^DB_USER=.*', 'DB_USER=!DB_USER!' | Set-Content '%ENV_FILE%'"
        powershell -Command "(Get-Content '%ENV_FILE%') -replace '^DB_PASSWORD=.*', 'DB_PASSWORD=!DB_PASSWORD!' | Set-Content '%ENV_FILE%'"
        powershell -Command "(Get-Content '%ENV_FILE%') -replace '^DB_NAME=.*', 'DB_NAME=!DB_NAME!' | Set-Content '%ENV_FILE%'"
        powershell -Command "(Get-Content '%ENV_FILE%') -replace '^DB_PORT=.*', 'DB_PORT=!DB_PORT!' | Set-Content '%ENV_FILE%'"
        powershell -Command "(Get-Content '%ENV_FILE%') -replace '^WEBSITE_PORT=.*', 'WEBSITE_PORT=!WEBSITE_PORT!' | Set-Content '%ENV_FILE%'"
        powershell -Command "(Get-Content '%ENV_FILE%') -replace '^NODE_ENV=.*', 'NODE_ENV=!NODE_ENV!' | Set-Content '%ENV_FILE%'"
        powershell -Command "(Get-Content '%ENV_FILE%') -replace '^DISCORD_TOKEN=.*', 'DISCORD_TOKEN=!DISCORD_TOKEN!' | Set-Content '%ENV_FILE%'"
        powershell -Command "(Get-Content '%ENV_FILE%') -replace '^TELEGRAM_TOKEN=.*', 'TELEGRAM_TOKEN=!TELEGRAM_TOKEN!' | Set-Content '%ENV_FILE%'"
        powershell -Command "(Get-Content '%ENV_FILE%') -replace '^JWT_SECRET=.*', 'JWT_SECRET=!JWT_SECRET!' | Set-Content '%ENV_FILE%'"
        powershell -Command "(Get-Content '%ENV_FILE%') -replace '^ADMIN_USER=.*', 'ADMIN_USER=!ADMIN_USER!' | Set-Content '%ENV_FILE%'"
        powershell -Command "(Get-Content '%ENV_FILE%') -replace '^ADMIN_PASSWORD=.*', 'ADMIN_PASSWORD=!ADMIN_PASSWORD!' | Set-Content '%ENV_FILE%'"
        
        call :success ".env file created and configured"
    )
    
    :skip_env
    
    REM ==========================================================================
    REM Build Docker images
    REM ==========================================================================
    
    call :header "Step 3: Building Docker Images"
    
    set /p build_images="Build Docker images now? (y/n) [y]: "
    if "!build_images!"=="" set "build_images=y"
    
    if "!build_images!"=="y" (
        cd /d "%SCRIPT_DIR%docker"
        call :info "Building images (this may take several minutes)..."
        docker-compose build
        if errorlevel 1 (
            call :error "Failed to build Docker images"
            exit /b 1
        )
        call :success "Docker images built successfully"
        cd /d "%SCRIPT_DIR%"
    )
    
    REM ==========================================================================
    REM Start services
    REM ==========================================================================
    
    call :header "Step 4: Starting Services"
    
    set /p start_services="Start Docker services now? (y/n) [y]: "
    if "!start_services!"=="" set "start_services=y"
    
    if "!start_services!"=="y" (
        cd /d "%SCRIPT_DIR%docker"
        call :info "Starting services..."
        docker-compose up -d
        if errorlevel 1 (
            call :error "Failed to start services"
            exit /b 1
        )
        
        call :info "Waiting for database to be ready..."
        timeout /t 5 /nobreak
        
        call :success "Services started successfully"
        cd /d "%SCRIPT_DIR%"
    )
    
    REM ==========================================================================
    REM Verify services
    REM ==========================================================================
    
    call :header "Step 5: Verifying Services"
    
    cd /d "%SCRIPT_DIR%docker"
    
    docker-compose ps | find "serverreport-db" >nul && call :success "Database is running" || call :warning "Database is not running"
    docker-compose ps | find "serverreport-website" >nul && call :success "Website is running" || call :warning "Website is not running"
    docker-compose ps | find "serverreport-discord-bot" >nul && call :success "Discord bot is running" || call :warning "Discord bot is not running"
    docker-compose ps | find "serverreport-telegram-bot" >nul && call :success "Telegram bot is running" || call :warning "Telegram bot is not running"
    
    cd /d "%SCRIPT_DIR%"
    
    REM ==========================================================================
    REM Installation complete
    REM ==========================================================================
    
    call :header "Setup Complete!"
    
    echo.
    echo Quick Start Guide:
    echo.
    echo 1. View logs:
    echo    cd docker
    echo    docker-compose logs -f
    echo.
    echo 2. Access the website:
    echo    http://localhost:!WEBSITE_PORT!
    echo.
    echo 3. Access the database:
    echo    Host: localhost:!DB_PORT!
    echo    User: !DB_USER!
    echo.
    echo 4. Stop services:
    echo    cd docker
    echo    docker-compose down
    echo.
    echo 5. Documentation:
    echo    - README.md
    echo    - DEVELOPMENT.md
    echo    - API_REFERENCE.md
    echo    - IMPLEMENTATION.md
    echo.
    call :success "Setup script completed successfully!"
    
    endlocal
    exit /b 0
