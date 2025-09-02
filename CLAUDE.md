# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Horsestrap is a zero-configuration deployment framework for .NET Umbraco CMS applications. The project follows a "zero-to-hero" deployment philosophy - from git clone to production in 2 minutes or less.

**Current Implementation**: Umbraco CMS with .NET 9.0, but designed to be adaptable to any technology stack.

## Essential Commands

### Horsestrap CLI Commands
```bash
# Interactive setup (prompts for domain, passwords, etc.)
horsestrap setup

# Quick setup with defaults
horsestrap setup --auto

# Update to latest version with zero downtime
horsestrap update

# View logs for all services (or specific: --web, --db, --caddy)
horsestrap logs
horsestrap logs --web
horsestrap logs --db

# Check status of all services
horsestrap status

# Restart services
horsestrap restart
horsestrap restart --web

# Stop all services
horsestrap stop

# Complete cleanup (stops services, removes containers/volumes)
horsestrap clean

# Backup database and media
horsestrap backup

# Rollback to previous version
horsestrap rollback
```

### Development (Local - No Horsestrap needed)
```bash
# Run locally (uses SQLite, no Docker required)
cd YourProject.Web
dotnet run

# Build the project
dotnet build
```

### Underlying Commands (What Horsestrap runs)
For transparency, Horsestrap shows the actual commands being executed:
- `horsestrap setup` → `./setup.sh` with interactive prompts for `.env` creation
- `horsestrap update` → `./deploy.sh` with backup and health checks
- `horsestrap logs --web` → `docker compose logs -f web`
- `horsestrap status` → `docker compose ps` + service health checks
- `horsestrap stop` → `docker compose down`
- `horsestrap clean` → `docker compose down --volumes --remove-orphans`

## Architecture

### Dual Environment Strategy
- **Development**: Pure .NET with SQLite database (no Docker required)
- **Production**: Containerized with SQL Server, Caddy reverse proxy, and automated SSL

### Configuration Hierarchy
1. Base: `appsettings.json` (SQLite, localhost URLs)
2. Environment overrides: `appsettings.Production.json` (SQL Server configs)
3. Environment variables: `.env` file (highest priority)

### Container Architecture
- **web**: Umbraco application (ghcr.io/mykebates/mountaire.com/mountaire-web:latest)
- **db**: SQL Server 2022 Express with health checks
- **caddy**: Reverse proxy with automatic SSL via Let's Encrypt

## Key Files and Structure

```
├── setup.sh              # Complete deployment automation
├── deploy.sh              # Zero-downtime updates  
├── docker-compose.yml     # Service orchestration
├── Caddyfile             # SSL and reverse proxy config
├── .env.example          # Environment variables template
├── YourProject.Web/      # Main application project
│       ├── appsettings.json          # Base config (SQLite)
│       ├── appsettings.Development.json
│       ├── appsettings.Production.json  # SQL Server overrides
│       └── Dockerfile
└── media/                # Umbraco media files (needs write permissions)
```

## Development Workflow

### Local Development
1. Clone repository
2. `cd YourProject.Web && dotnet run`
3. No additional setup required (uses SQLite)

### Production Deployment (The Horsestrap Way)
1. `horsestrap setup` (interactive prompts for domain, passwords, etc.)
2. `horsestrap status` (verify all services are healthy)
3. `horsestrap update` (for future updates)

### Traditional Deployment (Direct scripts)
1. Set `DOMAIN=yourdomain.com` in `.env`
2. `./setup.sh` for initial deployment
3. `./deploy.sh` for updates

## Horsestrap CLI Design Philosophy

The `horsestrap` command abstracts away complexity while maintaining transparency:

### Interactive Setup Experience
```bash
$ horsestrap setup

🐴 Horsestrap Setup
==================
? What's your domain? (e.g., mysite.com): myawesome.site
? Generate secure password automatically? (Y/n): y
? Database name (YourApp_Web): MyAwesome_DB
? Environment (Production/Staging/Development): Production

✓ Creating .env configuration...
✓ Running: ./setup.sh --domain=myawesome.site --db=MyAwesome_DB
✓ Starting Docker services...
✓ Initializing database...
✓ Configuring SSL certificates...

🎉 Deployment complete! Your site is live at https://myawesome.site
```

### Command Transparency
Each command shows what it's doing:
```bash
$ horsestrap logs --web
📋 Running: docker compose logs -f web
[logs appear here]

$ horsestrap status
🔍 Checking service health...
📋 Running: docker compose ps
📋 Running: curl -f http://localhost:8080/health
✓ All services healthy
```

## Critical Configuration Notes

### Environment Variables (.env)
Keep to essential variables only (4-5 max):
- `DOMAIN`: Your domain name
- `SA_PASSWORD`: SQL Server password (auto-generated if not set)
- `DB_NAME`: Database name (defaults to YourApp_Web)
- `ASPNETCORE_ENVIRONMENT`: Environment mode

### Database Configuration
- **Development**: SQLite in `|DataDirectory|/YourApp.sqlite.db`
- **Production**: SQL Server with connection string injected via environment variables

### Media Directory Permissions
The `media/` directory requires write permissions for container UID 1654. The setup script handles this automatically.

### Docker Registry Authentication
For private images, set `GITHUB_TOKEN` environment variable with repo and read:packages permissions.

## Horsestrap Principles

1. **Zero Configuration**: Developers should `git clone && dotnet run`
2. **Production-First**: Every project starts production-ready
3. **2-Minute Deployments**: From fresh Ubuntu to live site
4. **Self-Healing**: Automatic rollbacks on deployment failure
5. **No External Dependencies**: Just Docker and Git required

## Common Issues

### SQL Server Won't Start
- Requires minimum 2GB RAM
- Check logs: `docker logs mountaire-db`

### Media Upload Issues
- Run setup script to fix permissions
- Manual fix: `chmod -R 777 media`

### Docker Image Pull Failures
- Set GitHub token: `export GITHUB_TOKEN=ghp_your_token`
- Token needs `repo` + `read:packages` scopes

## Making Changes

### Code Changes
- Edit files in `YourProject.Web/`
- Test locally with `dotnet run`
- Update production with `horsestrap update`

### Configuration Changes
- Prefer environment variables in `.env`
- Use appsettings overrides for complex configurations
- Follow ASP.NET Core configuration hierarchy

### Script Modifications
- Scripts must remain executable: `git update-index --chmod=+x script.sh`
- Test in both development and production scenarios
- Maintain backward compatibility with existing deployments