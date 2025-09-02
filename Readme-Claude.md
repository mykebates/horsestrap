# 🐴 Horsestrap

**Zero-to-Hero Deployment Framework**  
*From git clone to production in 2 minutes or less*

## What is Horsestrap?

Horsestrap is a battle-tested, zero-configuration deployment framework that takes you from a fresh server to a fully deployed, production-ready application in minutes. No DevOps degree required.

### Core Philosophy
- **Zero Config Development**: `git clone` → `dotnet run` → coding
- **One-Command Deployment**: `./setup.sh` → fully deployed with SSL, database, backups
- **Production-First**: Every project starts production-ready
- **AI-Friendly**: Designed to work seamlessly with Claude Code and other AI assistants
- **Open Source**: Everything is public, forkable, and improvable

## 🚀 Quick Start (Coming Soon!)

### The Dream Install
```bash
# One-liner install (coming soon!)
curl -fsSL https://horsestrap.dev/install | bash

# Then create a new project
horsestrap new myproject --stack umbraco
cd myproject

# Local development (just works™)
dotnet run

# Deploy to production
horsestrap deploy production
```

### Current Method (Until horsestrap.dev launches)

```bash
# Clone the template directly
git clone https://github.com/mykebates/horsestrap-umbraco myproject
cd myproject

# Remove template git history and start fresh
rm -rf .git
git init
git add .
git commit -m "Initial Horsestrap project"

# Add your own remote
git remote add origin git@github.com:yourusername/myproject.git
git push -u origin main

# Local development
cd Src/MyProject
dotnet run

# Deploy to production (on your server)
git clone https://github.com/yourusername/myproject
cd myproject
echo "DOMAIN=yourdomain.com" >> .env
./setup.sh
```

**That's it.** SSL certificates, database, backups, monitoring - all handled.

## 🎯 The Horsestrap Promise

1. **2-Minute Deployments**: From fresh Ubuntu to live site
2. **Zero External Dependencies**: Just Docker and Git
3. **Self-Healing**: Automatic rollbacks on deployment failure
4. **Developer-First**: SQLite locally, SQL Server in production - seamlessly
5. **Production-Ready**: SSL, backups, health checks out of the box

## 📦 What's Included

### Development Experience
- **Local SQLite**: No database setup, just run
- **Hot Reload**: Code changes instantly reflected
- **Debug Mode**: Full debugging and detailed logging
- **No Docker Required**: Pure .NET development locally

### Production Infrastructure
- **Automated SSL**: Caddy with Let's Encrypt
- **SQL Server 2022**: Containerized and managed
- **Zero-Downtime Deploys**: Blue-green deployment pattern
- **Automatic Backups**: Database and file backups before each deploy
- **Health Monitoring**: Service health checks and auto-recovery

### Scripts & Automation
- `setup.sh`: Complete initial deployment
- `deploy.sh`: Zero-downtime updates with rollback
- `.env`: Simple, clean configuration
- GitHub Actions: Automated Docker image builds

## 🛠 Technical Stack

### Current Implementation (Umbraco CMS)
- **Runtime**: .NET 9.0
- **CMS**: Umbraco 16
- **Database**: SQLite (dev) / SQL Server 2022 (prod)
- **Proxy**: Caddy 2
- **Container**: Docker & Docker Compose
- **Registry**: GitHub Container Registry

### Adaptable to Any Stack
The Horsestrap pattern can be applied to any technology stack. The key is the zero-configuration philosophy and the setup/deploy scripts.

## 📋 Requirements

### Server Requirements
- Ubuntu 20.04+ (or any Linux with Docker)
- 2GB+ RAM (SQL Server requirement)
- Docker & Docker Compose
- Git

### Developer Requirements
- .NET SDK (for .NET projects)
- Git
- That's it!

## 🔧 Configuration

### Essential Variables Only
```bash
# .env file - that's all you need
DOMAIN=yourdomain.com
SA_PASSWORD=auto-generated-secure-password
DB_NAME=YourApp_DB
ASPNETCORE_ENVIRONMENT=Production
```

### Environment Hierarchy
1. Base configuration in `appsettings.json`
2. Environment overrides (`appsettings.Production.json`)
3. Environment variables (highest priority)

## 🚨 Common Issues & Solutions

### "SQL Server won't start"
- Need 2GB+ RAM minimum
- Check: `docker logs [container-name]`

### "Media folder permissions"
- Auto-fixed by setup script
- Manual: `chmod -R 777 media`

### "Can't pull Docker images"
- Create GitHub classic token with `repo` + `read:packages`
- Set: `export GITHUB_TOKEN=ghp_your_token`

## 🤖 AI Assistant Integration

### Starting a New Session with Claude Code

```markdown
I'm starting a new Horsestrap project. Here's my HORSESTRAP.md file:

[paste this entire file]

Project specifics:
- Project name: [YourProject]
- Domain: [yourdomain.com]
- Stack: [Umbraco CMS / Next.js / etc]

Please help me:
1. Set up the initial project structure
2. Create the setup.sh and deploy.sh scripts
3. Configure Docker and docker-compose.yml
4. Set up GitHub Actions for automated builds

Following Horsestrap principles:
- Zero configuration for developers
- 2-minute production deployments
- Production-ready from day one
```

### Key Points for AI Assistants

1. **Always prefer editing over creating files**
2. **Keep .env to 4-5 essential variables max**
3. **Use proper ASP.NET Core configuration hierarchy**
4. **Scripts must be executable in git** (`git update-index --chmod=+x`)
5. **Docker login before pulling private images**
6. **Health checks must actually verify the service is ready**
7. **Media/upload directories need proper permissions (777 or container UID)**

## 📚 Project Structure

```
your-project/
├── setup.sh                 # 🚀 Zero-config deployment
├── deploy.sh                # 🔄 Zero-downtime updates
├── docker-compose.yml       # 🐳 Service orchestration
├── Caddyfile               # 🔒 SSL & reverse proxy
├── .env.example            # ⚙️  Configuration template
├── .github/
│   └── workflows/
│       └── docker-publish.yml  # 📦 Automated builds
├── Src/
│   └── YourApp/            # 💻 Application source
│       ├── appsettings.json              # Base config
│       ├── appsettings.Development.json  # Dev overrides
│       ├── appsettings.Production.json   # Prod overrides
│       └── Dockerfile
├── HORSESTRAP.md           # 🐴 This file
├── README.md               # 📖 Project-specific docs
└── DEVELOPER.md            # 👨‍💻 Developer guide
```

## 🎨 The Horsestrap Way

### Development Flow
```bash
git clone → dotnet run → code → commit → push
```

### Deployment Flow
```bash
git pull → ./deploy.sh → automatic rollback on failure → done
```

### No Middle Steps. No Configuration. No Complexity.

## 🏗 Architecture Vision

### The Horsestrap CLI (Coming Soon)
```bash
# Global installation
curl -fsSL https://horsestrap.dev/install | bash

# Commands that will be available
horsestrap new [project] --stack [umbraco|nextjs|rails]
horsestrap deploy [environment]
horsestrap rollback
horsestrap status
horsestrap logs
horsestrap backup
```

### How It Works
1. **Templates Repository**: GitHub org with starter templates for each stack
2. **CLI Tool**: Bash/Go binary that orchestrates everything
3. **User's Repository**: Their own project with Horsestrap scripts baked in
4. **Production Server**: Just needs Docker + Git + Horsestrap

### The Flow
```
horsestrap new → clones template → removes .git → user commits to their repo
                                                ↓
                                    developer works locally (zero config)
                                                ↓
                                    pushes to their GitHub
                                                ↓
horsestrap deploy → pulls their repo → runs setup.sh → site is live
```

## 🔮 Roadmap

### Phase 1: Template Repository (NOW)
- [x] Umbraco CMS template with full Horsestrap setup
- [x] Battle-tested setup.sh and deploy.sh scripts
- [x] Docker Compose orchestration
- [ ] Extract to standalone template repo

### Phase 2: CLI Tool
- [ ] Bash script installer from horsestrap.dev
- [ ] `horsestrap new` command with template selection
- [ ] `horsestrap deploy` with environment management
- [ ] Update notifications and self-update

### Phase 3: Multi-Stack
- [ ] Next.js + PostgreSQL template
- [ ] Rails + PostgreSQL template  
- [ ] Laravel + MySQL template
- [ ] Custom stack generator

### Phase 4: Advanced Features
- [ ] Multi-environment deployments
- [ ] Secrets management
- [ ] Backup/restore commands
- [ ] Monitoring dashboard
- [ ] Kubernetes option for scale

## 💪 Why "Horsestrap"?

Because Bootstrap was taken, and horses are strong, reliable, and get you where you need to go fast. Plus, "pulling yourself up by your horsestraps" sounds way cooler.

---

**Horsestrap**: *When you need to go from zero to galloping in production.*

Created by [@mykebates](https://github.com/mykebates) | Powered by coffee and stubbornness