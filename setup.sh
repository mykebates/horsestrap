#!/bin/bash

# Horsestrap Docker Setup Script
# This script handles complete setup/deployment regardless of current state
# Zero-config deployment that just works!

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
DB_NAME="YourApp_Web"
REQUIRED_FILES=("docker-compose.yml" "Caddyfile")
SCRIPT_VERSION="2.0"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

show_banner() {
    echo -e "${BLUE}"
    echo "========================================="
    echo "   🚀 Horsestrap Setup Script v${SCRIPT_VERSION}"
    echo "   Zero-config Docker deployment"
    echo "========================================="
    echo -e "${NC}"
}

check_requirements() {
    log_step "Checking system requirements..."
    
    local missing_deps=0
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed!"
        log_info "Install Docker: https://docs.docker.com/get-docker/"
        missing_deps=1
    else
        log_debug "Docker: $(docker --version)"
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not available!"
        log_info "Install Docker Compose: https://docs.docker.com/compose/install/"
        missing_deps=1
    else
        log_debug "Docker Compose: $(docker compose version)"
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running!"
        log_info "Start Docker service and try again"
        missing_deps=1
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed!"
        log_info "Install git: sudo apt-get install git"
        missing_deps=1
    else
        log_debug "Git: $(git --version)"
    fi
    
    if [ $missing_deps -eq 1 ]; then
        log_error "Missing required dependencies. Please install them and try again."
        exit 1
    fi
    
    log_info "All system requirements satisfied ✓"
}

configure_git_auth() {
    log_step "Configuring git authentication..."
    
    if [ -n "$GITHUB_TOKEN" ]; then
        log_info "GitHub token detected, configuring authenticated git access"
        
        # Configure git to use the token for this repository
        if [ -d ".git" ]; then
            local repo_url=$(git remote get-url origin 2>/dev/null || echo "")
            if [[ "$repo_url" == *"github.com"* ]]; then
                # Convert SSH URLs to HTTPS with token
                if [[ "$repo_url" == "git@github.com:"* ]]; then
                    repo_url=$(echo "$repo_url" | sed 's|git@github.com:|https://github.com/|' | sed 's|\.git$||')
                fi
                
                # Set authenticated URL
                local auth_url=$(echo "$repo_url" | sed "s|https://github.com/|https://${GITHUB_TOKEN}@github.com/|")
                git remote set-url origin "$auth_url" 2>/dev/null || true
                log_debug "Configured git remote with token authentication"
            fi
        fi
        
        # Configure git credential helper to use token
        git config --global credential.helper store 2>/dev/null || true
        
    else
        log_warn "No GITHUB_TOKEN environment variable found"
        log_info "For private repositories, set GITHUB_TOKEN with a fine-grained personal access token"
        log_info "See: https://github.com/settings/personal-access-tokens/new"
    fi
}

check_required_files() {
    log_step "Validating required files..."
    
    local missing=0
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "Required file missing: $file"
            missing=1
        else
            log_debug "Found: $file ✓"
        fi
    done
    
    if [ $missing -eq 1 ]; then
        log_error "Please ensure all required files are present"
        log_info "Run this script from the project root directory"
        exit 1
    fi
    
    log_info "All required files present ✓"
}

detect_environment() {
    log_step "Detecting environment..."
    
    # Detect if we're in development or production
    # Check if project structure exists
        log_info "Development environment detected (source code present)"
        export DETECTED_ENV="Development"
    else
        log_info "Production environment detected (containerized deployment)"
        export DETECTED_ENV="Production"
    fi
    
    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        export DETECTED_OS="Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        export DETECTED_OS="macOS"
    else
        export DETECTED_OS="Unknown"
    fi
    
    log_debug "Environment: $DETECTED_ENV"
    log_debug "OS: $DETECTED_OS"
}

setup_env() {
    log_step "Setting up environment configuration..."
    
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            log_info "Creating .env from .env.example"
            cp .env.example .env
            log_warn "Please review and update .env with your values if needed"
        else
            log_info "Creating default .env file..."
            create_default_env
        fi
    else
        log_info ".env file exists ✓"
    fi
    
    # Source the .env file FIRST before validating
    set -a
    source .env
    set +a
    
    # NOW validate after sourcing
    validate_env_vars
    
    # Set intelligent defaults
    export DB_NAME=${DB_NAME:-YourApp_Web}
    export DOMAIN=${DOMAIN:-localhost}
    
    log_debug "Database: $DB_NAME"
    log_debug "Domain: $DOMAIN"
}

create_default_env() {
    log_info "Creating default environment configuration..."
    
    # Generate a random strong password
    local random_pass=$(openssl rand -base64 32 2>/dev/null || date +%s | sha256sum | base64 | head -c 32)
    
    cat > .env << EOF
# Horsestrap Environment Configuration
# Essential variables only - see .env.example for all options

# Domain for Caddy SSL and Umbraco URLs
DOMAIN=localhost

# SQL Server SA password
SA_PASSWORD=${random_pass}!2024

# Database name
DB_NAME=YourApp_Web

# Environment (Production, Staging, Development)
ASPNETCORE_ENVIRONMENT=Production
EOF

    log_info "Created .env with generated secure password"
    log_warn "IMPORTANT: Update DOMAIN in .env file for production!"
}

validate_env_vars() {
    log_debug "Validating environment variables..."
    
    # Check critical variables
    if [ -z "$SA_PASSWORD" ]; then
        log_warn "SA_PASSWORD not set, generating one"
        # Only add if not already in file
        if ! grep -q "^SA_PASSWORD=" .env 2>/dev/null; then
            echo "SA_PASSWORD=$(openssl rand -base64 16)!2024" >> .env
            # Re-source to get the new password
            source .env
        fi
    fi
    
    if [ -z "$DOMAIN" ]; then
        log_warn "DOMAIN not set, using localhost" 
        # Only add if not already in file
        if ! grep -q "^DOMAIN=" .env 2>/dev/null; then
            echo "DOMAIN=localhost" >> .env
            # Re-source to get the new domain
            source .env
        fi
    fi
}

create_directories() {
    log_step "Creating project directories..."
    
    # Create all necessary directories
    mkdir -p sql-init media backups logs data
    
    log_info "Setting media directory permissions..."
    set_media_permissions
    
    log_info "Creating database initialization script..."
    create_db_init_script
    
    log_info "Directories and scripts created ✓"
}

set_media_permissions() {
    # The container runs as user 'app' with UID 1654 (not 1000)
    # Create media directory structure if it doesn't exist
    mkdir -p media
    
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        # If sudo is available and passwordless
        sudo chown -R 1654:1654 media 2>/dev/null || {
            log_warn "Could not set ownership to container user (1654), making world-writable..."
            sudo chmod -R 777 media
        }
        sudo chmod -R 755 media 2>/dev/null || true
    elif [ "$(id -u)" = "0" ]; then
        # If running as root
        chown -R 1654:1654 media 2>/dev/null || chmod -R 777 media
        chmod -R 755 media
    else
        # Fallback: make it world writable so container can write
        log_warn "Cannot set ownership, making media directory world-writable..."
        chmod -R 777 media
    fi
    
    log_debug "Media permissions configured for container user (UID 1654)"
}

create_db_init_script() {
    cat > sql-init/01-init-database.sql << 'EOF'
-- Auto-generated database initialization script for Horsestrap
-- This script creates the database if it doesn't exist

DECLARE @DbName NVARCHAR(128) = N'$(DB_NAME)'

-- Check if database exists
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = @DbName)
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = N'CREATE DATABASE [' + @DbName + N']'
    EXEC sp_executesql @SQL
    PRINT 'Database ' + @DbName + ' created successfully'
END
ELSE
BEGIN
    PRINT 'Database ' + @DbName + ' already exists'
END
GO

-- Switch to the database
USE [$(DB_NAME)]
GO

-- Set compatibility level
ALTER DATABASE [$(DB_NAME)] SET COMPATIBILITY_LEVEL = 150
GO

-- Basic optimization settings
ALTER DATABASE [$(DB_NAME)] SET AUTO_CLOSE OFF
GO
ALTER DATABASE [$(DB_NAME)] SET AUTO_SHRINK OFF
GO

PRINT 'Database initialization complete for $(DB_NAME)'
GO
EOF

    # Replace placeholder with actual DB name
    sed -i.bak "s/\$(DB_NAME)/${DB_NAME}/g" sql-init/01-init-database.sql 2>/dev/null || \
    sed -i "s/\$(DB_NAME)/${DB_NAME}/g" sql-init/01-init-database.sql
}

cleanup_existing_services() {
    log_step "Cleaning up existing services..."
    
    local containers_exist=false
    if docker ps -a --format "table {{.Names}}" | grep -q "mountaire"; then
        containers_exist=true
    fi
    
    if [ "$containers_exist" = true ]; then
        log_warn "Found existing Horsestrap containers"
        
        # In production, auto-cleanup. In development, ask.
        if [ "$DETECTED_ENV" = "Production" ] || [ "$1" = "--force" ]; then
            log_info "Auto-cleaning existing services..."
            cleanup_containers
        else
            read -p "Stop and remove existing containers? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cleanup_containers
            else
                log_info "Keeping existing containers"
            fi
        fi
    else
        log_info "No existing containers found"
    fi
}

cleanup_containers() {
    log_info "Stopping existing services..."
    docker compose down --remove-orphans || true
    
    # Extra cleanup for stuck containers
    docker rm -f mountaire-web-1 mountaire-db mountaire-caddy-1 2>/dev/null || true
    
    # Cleanup unused networks
    docker network prune -f 2>/dev/null || true
    
    log_info "Cleanup completed ✓"
}

wait_for_service() {
    local service=$1
    local max_attempts=${2:-30}
    local attempt=1
    
    log_info "Waiting for $service to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        # For web service, check if it's responding on port 8080
        if [ "$service" = "web" ]; then
            if docker exec mountairecom-web-1 sh -c "cat /proc/net/tcp | grep '1F90'" &>/dev/null; then
                log_info "$service is ready ✓"
                return 0
            fi
        # For other services, check normal status
        elif docker compose ps $service | grep -q "healthy\|running"; then
            log_info "$service is ready ✓"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo
    log_error "$service failed to start after $max_attempts attempts"
    return 1
}

create_database() {
    log_step "Setting up database..."
    
    local max_attempts=30
    local attempt=1
    
    # Wait for SQL Server to be ready
    while [ $attempt -le $max_attempts ]; do
        if docker exec mountaire-db /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U sa -P "$SA_PASSWORD" -C \
            -Q "SELECT 1" &>/dev/null; then
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_error "SQL Server failed to start after $max_attempts attempts"
            return 1
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo
    log_info "SQL Server is ready ✓"
    
    # Create database
    log_info "Creating database ${DB_NAME}..."
    docker exec mountaire-db /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$SA_PASSWORD" -C \
        -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'${DB_NAME}') CREATE DATABASE [${DB_NAME}]" \
        2>/dev/null || {
            log_error "Failed to create database"
            return 1
        }
    
    # Verify database was created
    if docker exec mountaire-db /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$SA_PASSWORD" -C \
        -Q "SELECT name FROM sys.databases WHERE name = '${DB_NAME}'" 2>/dev/null | grep -q "${DB_NAME}"; then
        log_info "Database ${DB_NAME} verified ✓"
    else
        log_error "Database ${DB_NAME} verification failed!"
        return 1
    fi
}

start_services() {
    log_step "Starting application services..."
    
    # Login to GitHub Container Registry if token is available
    if [ -n "$GITHUB_TOKEN" ]; then
        log_info "Authenticating with GitHub Container Registry..."
        echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$USER" --password-stdin 2>/dev/null || {
            log_warn "Docker login with \$USER failed, trying with token as username..."
            echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_TOKEN" --password-stdin
        }
    else
        log_warn "No GITHUB_TOKEN found. If using private images, authentication may fail."
    fi
    
    # Pull latest images
    log_info "Pulling latest Docker images..."
    docker compose pull
    
    # Start database first
    log_info "Starting database service..."
    docker compose up -d db
    
    # Create database
    create_database || exit 1
    
    # Start remaining services
    log_info "Starting web and proxy services..."
    docker compose up -d
    
    # Wait for services to be healthy
    wait_for_service "db" 30
    wait_for_service "web" 60
    
    log_info "All services started successfully ✓"
}

run_health_checks() {
    log_step "Running health checks..."
    
    # Check container status
    log_debug "Container status:"
    docker compose ps
    
    echo
    
    # Test database connection
    log_info "Testing database connection..."
    if docker exec mountaire-db /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$SA_PASSWORD" -C \
        -Q "SELECT 'OK' as DatabaseStatus, name FROM sys.databases WHERE name = '${DB_NAME}'" 2>/dev/null | grep -q "${DB_NAME}"; then
        log_info "Database connection: HEALTHY ✓"
    else
        log_warn "Database connection: FAILED ❌"
    fi
    
    # Test web application
    log_info "Testing web application..."
    local web_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null || echo "000")
    if [[ "$web_status" =~ ^(200|302|404)$ ]]; then
        log_info "Web application: RESPONDING ✓ (HTTP $web_status)"
    else
        log_warn "Web application: NOT RESPONDING ❌ (HTTP $web_status)"
        log_info "This is normal during first-time setup. Umbraco may still be initializing."
    fi
    
    # Check external access
    if [ "$DOMAIN" != "localhost" ]; then
        log_info "Testing external access..."
        local external_status=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" 2>/dev/null || echo "000")
        if [[ "$external_status" =~ ^(200|302|404)$ ]]; then
            log_info "External access: WORKING ✓ (HTTP $external_status)"
        else
            log_warn "External access: ISSUES ❌ (HTTP $external_status)"
            log_info "Check DNS, firewall, and SSL certificate configuration"
        fi
    fi
}

show_completion_info() {
    echo
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo
    
    if [ "$DOMAIN" = "localhost" ]; then
        log_info "🌐 Local site: http://localhost:8080"
    else
        log_info "🌐 Your site: https://$DOMAIN"
    fi
    
    log_info "🗄️  Database: $DB_NAME"
    log_info "📊 Admin panel: https://$DOMAIN/umbraco (first visit will show setup)"
    echo
    
    echo -e "${BLUE}📋 Useful commands:${NC}"
    echo "  ./setup.sh                    # Re-run setup"
    echo "  ./deploy.sh                   # Deploy updates (coming soon)"
    echo "  docker compose logs -f web    # View web logs"
    echo "  docker compose ps             # Check status"
    echo "  docker compose restart web    # Restart web service"
    echo "  docker compose down           # Stop all services"
    echo
    
    if [ "$DETECTED_ENV" = "Development" ]; then
        echo -e "${PURPLE}👨‍💻 Developer info:${NC}"
        echo "  cd YourProject.Web && dotnet run  # Run locally with .NET"
        echo "  Uses SQLite for local development (no Docker needed)"
        echo
    fi
}

# Main execution
main() {
    show_banner
    
    log_info "Starting setup process..."
    
    # Parse command line arguments
    local force_cleanup=false
    for arg in "$@"; do
        case $arg in
            --force)
                force_cleanup=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
        esac
    done
    
    # Run all setup steps
    check_requirements
    check_required_files
    configure_git_auth
    detect_environment
    setup_env
    create_directories
    cleanup_existing_services $([ "$force_cleanup" = true ] && echo "--force")
    start_services
    run_health_checks
    show_completion_info
    
    exit 0
}

show_help() {
    echo "Horsestrap Setup Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --force    Force cleanup of existing containers without prompting"
    echo "  --help     Show this help message"
    echo
    echo "This script will:"
    echo "  1. Check system requirements"
    echo "  2. Set up configuration files"
    echo "  3. Create necessary directories"
    echo "  4. Start Docker services"
    echo "  5. Initialize the database"
    echo "  6. Run health checks"
}

# Trap errors and cleanup
trap 'log_error "Script failed at line $LINENO. Exit code: $?"' ERR

# Run main function with all arguments
main "$@"