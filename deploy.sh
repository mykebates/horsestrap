#!/bin/bash

# Horsestrap Deployment Script
# Handles zero-downtime updates and deployments

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_VERSION="1.0"
BACKUP_DIR="./backups/deployments"
MAX_BACKUP_COUNT=5

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
    echo "   🚀 Horsestrap Deploy Script v${SCRIPT_VERSION}"
    echo "   Zero-downtime deployment system"
    echo "========================================="
    echo -e "${NC}"
}

check_prerequisites() {
    log_step "Checking deployment prerequisites..."
    
    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ] || [ ! -f "setup.sh" ]; then
        log_error "Not in project root directory. Please run from mountaire.com root."
        exit 1
    fi
    
    # Check if services are running
    if ! docker compose ps | grep -q "mountaire"; then
        log_error "No running Horsestrap services found. Run ./setup.sh first."
        exit 1
    fi
    
    # Check git
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed!"
        exit 1
    fi
    
    # Check if we're in a git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository!"
        exit 1
    fi
    
    # Configure git authentication
    configure_git_auth
    
    log_info "Prerequisites satisfied ✓"
}

configure_git_auth() {
    log_debug "Configuring git authentication..."
    
    if [ -n "$GITHUB_TOKEN" ]; then
        log_debug "GitHub token detected, ensuring authenticated git access"
        
        # Configure git to use the token for this repository
        local repo_url=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$repo_url" == *"github.com"* ]]; then
            # Convert SSH URLs to HTTPS with token
            if [[ "$repo_url" == "git@github.com:"* ]]; then
                repo_url=$(echo "$repo_url" | sed 's|git@github.com:|https://github.com/|' | sed 's|\.git$||')
            fi
            
            # Set authenticated URL if not already set
            if [[ "$repo_url" != *"$GITHUB_TOKEN"* ]]; then
                local auth_url=$(echo "$repo_url" | sed "s|https://github.com/|https://${GITHUB_TOKEN}@github.com/|")
                git remote set-url origin "$auth_url" 2>/dev/null || true
                log_debug "Configured git remote with token authentication"
            fi
        fi
        
    else
        log_debug "No GITHUB_TOKEN found, assuming public repository or SSH key authentication"
    fi
}

create_backup() {
    log_step "Creating deployment backup..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_path="$BACKUP_DIR/$timestamp"
    
    mkdir -p "$backup_path"
    
    # Backup current commit info
    git rev-parse HEAD > "$backup_path/commit.txt"
    git log -1 --oneline > "$backup_path/commit_message.txt"
    
    # Backup environment files
    cp .env "$backup_path/" 2>/dev/null || log_warn "No .env file to backup"
    cp docker-compose.yml "$backup_path/"
    
    # Backup database if possible
    log_info "Creating database backup..."
    if docker exec mountaire-db /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$(grep SA_PASSWORD .env | cut -d'=' -f2)" -C \
        -Q "BACKUP DATABASE [$(grep DB_NAME .env | cut -d'=' -f2 || echo 'YourApp_Web')] TO DISK = '/var/opt/mssql/backups/pre_deploy_$timestamp.bak'" 2>/dev/null; then
        log_info "Database backup created ✓"
    else
        log_warn "Database backup failed - continuing deployment"
    fi
    
    # Cleanup old backups
    cleanup_old_backups
    
    log_info "Backup created: $backup_path ✓"
}

cleanup_old_backups() {
    if [ -d "$BACKUP_DIR" ]; then
        local backup_count=$(ls -1 "$BACKUP_DIR" | wc -l)
        if [ "$backup_count" -gt "$MAX_BACKUP_COUNT" ]; then
            log_info "Cleaning up old backups (keeping last $MAX_BACKUP_COUNT)..."
            ls -1t "$BACKUP_DIR" | tail -n +$((MAX_BACKUP_COUNT + 1)) | xargs -I {} rm -rf "$BACKUP_DIR/{}"
        fi
    fi
}

pull_latest_code() {
    log_step "Pulling latest code..."
    
    # Stash any local changes
    if ! git diff-index --quiet HEAD --; then
        log_warn "Uncommitted changes detected, stashing..."
        git stash push -m "Auto-stash before deployment $(date)"
    fi
    
    # Get current branch
    local current_branch=$(git branch --show-current)
    log_debug "Current branch: $current_branch"
    
    # Pull latest changes
    log_info "Fetching latest changes..."
    git fetch origin
    
    local old_commit=$(git rev-parse HEAD)
    git pull origin "$current_branch"
    local new_commit=$(git rev-parse HEAD)
    
    if [ "$old_commit" = "$new_commit" ]; then
        log_info "No new changes to deploy"
        return 0
    else
        log_info "Updated from $old_commit to $new_commit"
        git log --oneline "$old_commit..$new_commit"
        return 1  # Indicates there were changes
    fi
}

update_containers() {
    log_step "Updating application containers..."
    
    # Source environment
    set -a
    source .env
    set +a
    
    # Pull latest images
    log_info "Pulling latest Docker images..."
    docker compose pull
    
    # Check if images were updated
    local web_image_id_before=$(docker images --format "{{.ID}}" ghcr.io/mykebates/mountaire.com/mountaire-web:latest | head -1)
    
    # Recreate services with new images
    log_info "Recreating services with latest images..."
    docker compose up -d --force-recreate web caddy
    
    local web_image_id_after=$(docker images --format "{{.ID}}" ghcr.io/mykebates/mountaire.com/mountaire-web:latest | head -1)
    
    if [ "$web_image_id_before" != "$web_image_id_after" ]; then
        log_info "Web application image updated ✓"
    else
        log_info "Web application image unchanged"
    fi
    
    # Wait for services to be healthy
    wait_for_healthy_services
}

wait_for_healthy_services() {
    log_info "Waiting for services to be healthy..."
    
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local web_status=$(docker compose ps web --format "{{.Health}}" 2>/dev/null || echo "unknown")
        local caddy_status=$(docker compose ps caddy --format "{{.Status}}" 2>/dev/null || echo "unknown")
        
        if [[ "$caddy_status" == *"Up"* ]] && ( [[ "$web_status" == "healthy" ]] || [[ "$web_status" == "" ]] ); then
            log_info "All services are healthy ✓"
            return 0
        fi
        
        if [ $attempt -eq 1 ]; then
            echo -n "Waiting for services to be ready"
        fi
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo
    log_error "Services failed to become healthy after $max_attempts attempts"
    return 1
}

run_post_deploy_checks() {
    log_step "Running post-deployment checks..."
    
    # Source environment
    set -a
    source .env
    set +a
    
    # Check web application
    log_info "Testing web application..."
    local web_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null || echo "000")
    if [[ "$web_status" =~ ^(200|302|404)$ ]]; then
        log_info "Web application: RESPONDING ✓ (HTTP $web_status)"
    else
        log_error "Web application: NOT RESPONDING ❌ (HTTP $web_status)"
        return 1
    fi
    
    # Check external access if not localhost
    if [ "$DOMAIN" != "localhost" ]; then
        log_info "Testing external access..."
        local external_status=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" 2>/dev/null || echo "000")
        if [[ "$external_status" =~ ^(200|302|404)$ ]]; then
            log_info "External access: WORKING ✓ (HTTP $external_status)"
        else
            log_warn "External access: ISSUES ❌ (HTTP $external_status)"
            log_info "This may be temporary during SSL certificate renewal"
        fi
    fi
    
    # Check database connectivity
    log_info "Testing database connectivity..."
    if docker exec mountaire-db /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$SA_PASSWORD" -C \
        -Q "SELECT 'OK' as Status" &>/dev/null; then
        log_info "Database: CONNECTED ✓"
    else
        log_error "Database: CONNECTION FAILED ❌"
        return 1
    fi
    
    # Check disk space
    log_info "Checking disk space..."
    local disk_usage=$(df . | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 90 ]; then
        log_info "Disk space: OK (${disk_usage}% used) ✓"
    else
        log_warn "Disk space: HIGH (${disk_usage}% used) ⚠️"
    fi
    
    log_info "All post-deployment checks passed ✓"
}

cleanup_old_images() {
    log_step "Cleaning up old Docker images..."
    
    # Remove dangling images
    local dangling=$(docker images -f "dangling=true" -q)
    if [ -n "$dangling" ]; then
        log_info "Removing dangling images..."
        docker rmi $dangling 2>/dev/null || true
    fi
    
    # Remove old versions of our images (keep last 3)
    local old_images=$(docker images ghcr.io/mykebates/mountaire.com/mountaire-web --format "{{.ID}}" | tail -n +4)
    if [ -n "$old_images" ]; then
        log_info "Removing old application images..."
        echo $old_images | xargs docker rmi 2>/dev/null || true
    fi
    
    log_info "Image cleanup completed ✓"
}

rollback_deployment() {
    log_error "Deployment failed! Initiating rollback..."
    
    local latest_backup=$(ls -1t "$BACKUP_DIR" 2>/dev/null | head -1)
    if [ -z "$latest_backup" ]; then
        log_error "No backup found for rollback!"
        exit 1
    fi
    
    log_warn "Rolling back to backup: $latest_backup"
    
    # Restore git state
    local backup_commit=$(cat "$BACKUP_DIR/$latest_backup/commit.txt")
    git reset --hard "$backup_commit"
    
    # Restore environment
    cp "$BACKUP_DIR/$latest_backup/.env" ./ 2>/dev/null || true
    cp "$BACKUP_DIR/$latest_backup/docker-compose.yml" ./
    
    # Restart services
    log_info "Restarting services with previous configuration..."
    docker compose down
    ./setup.sh --force
    
    log_warn "Rollback completed. Please investigate the deployment failure."
}

show_deployment_summary() {
    echo
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo
    
    # Source environment for display
    set -a
    source .env
    set +a
    
    log_info "🌐 Site: https://$DOMAIN"
    log_info "📊 Admin: https://$DOMAIN/umbraco"
    log_info "🗄️  Database: $DB_NAME"
    
    echo
    echo -e "${BLUE}📋 Useful commands:${NC}"
    echo "  docker compose logs -f web    # View web logs"
    echo "  docker compose ps             # Check status"
    echo "  ./deploy.sh                   # Deploy again"
    echo "  ./setup.sh                    # Full setup"
    echo
    
    # Show recent commits deployed
    echo -e "${PURPLE}📝 Recent changes deployed:${NC}"
    git log -3 --oneline
    echo
}

# Main execution
main() {
    show_banner
    
    local skip_code_update=false
    local force_deploy=false
    
    # Parse command line arguments
    for arg in "$@"; do
        case $arg in
            --skip-code)
                skip_code_update=true
                shift
                ;;
            --force)
                force_deploy=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
        esac
    done
    
    # Trap errors for rollback
    trap 'rollback_deployment' ERR
    
    log_info "Starting deployment process..."
    
    # Run deployment steps
    check_prerequisites
    create_backup
    
    local code_updated=false
    if [ "$skip_code_update" = false ]; then
        pull_latest_code || code_updated=true
    else
        log_info "Skipping code update (--skip-code flag)"
        code_updated=true
    fi
    
    # Only update containers if code changed or force flag is set
    if [ "$code_updated" = true ] || [ "$force_deploy" = true ]; then
        update_containers
        run_post_deploy_checks
        cleanup_old_images
        show_deployment_summary
    else
        log_info "No changes detected. Deployment skipped."
        log_info "Use --force to deploy anyway."
    fi
    
    # Disable error trap
    trap - ERR
    
    exit 0
}

show_help() {
    echo "Horsestrap Deployment Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --skip-code    Skip git pull, only update containers"
    echo "  --force        Force deployment even if no code changes"
    echo "  --help         Show this help message"
    echo
    echo "This script will:"
    echo "  1. Create a backup of current state"
    echo "  2. Pull latest code from git"
    echo "  3. Update Docker containers with latest images"
    echo "  4. Run health checks"
    echo "  5. Clean up old Docker images"
    echo "  6. Rollback automatically if anything fails"
}

# Run main function with all arguments
main "$@"