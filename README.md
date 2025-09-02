# 🐴 Horsestrap

**The Anti-Framework Framework**

Zero-configuration deployment for distinguished applications. From git clone to production in 2 minutes.

> *"Deploy like you've got somewhere to be."*

## 🚀 Quick Start

### Install Horsestrap CLI

```bash
curl -fsSL https://horsestrap.com/install.sh | sudo bash
```

### Create a New Project

```bash
horsestrap init MyAwesome
cd MyAwesome
```

### Deploy to Production

```bash
horsestrap setup
```

**That's it!** Your site is live with SSL, database, and zero downtime updates.

## 🎯 What is Horsestrap?

Horsestrap is a zero-configuration deployment framework designed for developers who value their time. It's built around a simple philosophy:

**You shouldn't need to become a DevOps engineer to deploy your application.**

### The Horsestrap Way

- **Zero Config**: `git clone && dotnet run` for development
- **Production First**: Every project starts production-ready  
- **2-Minute Deployments**: Fresh server to live site
- **Self-Healing**: Automatic rollbacks on failure
- **No Lock-in**: Standard Docker & scripts you can modify

## 🛠 Core Commands

```bash
horsestrap init        # Create new project
horsestrap setup       # Interactive production deployment
horsestrap update      # Zero-downtime updates
horsestrap status      # Check service health
horsestrap logs        # View application logs
horsestrap backup      # Backup database and files
horsestrap rollback    # Rollback to previous version
```

## 📦 What You Get

### Production Stack
- **Framework**: .NET 9.0 (adaptable to any stack)
- **Database**: SQL Server with automatic migrations
- **Proxy**: Caddy with automatic HTTPS/SSL
- **Orchestration**: Docker Compose
- **Monitoring**: Health checks and logging

### Development Experience
- **Local Database**: SQLite (no setup required)
- **Hot Reload**: Instant feedback
- **Debug Support**: Full debugging enabled
- **IDE Ready**: Works with VS Code, Visual Studio, Rider

### Deployment Features
- **Zero Downtime**: Blue/green deployments
- **Automatic SSL**: Let's Encrypt integration
- **Health Checks**: Automatic rollback on failure
- **Backups**: Automated database and file backups
- **Monitoring**: Built-in service monitoring

## 🏗 Architecture

### Dual Environment Strategy
- **Development**: Pure framework with SQLite (no Docker needed)
- **Production**: Containerized with SQL Server, proxy, SSL

### Configuration Hierarchy
1. **Base**: Framework defaults (SQLite, localhost)
2. **Environment**: Production overrides (SQL Server, SSL)
3. **Variables**: `.env` file (highest priority)

### Container Services
- **web**: Your application
- **db**: SQL Server with health checks  
- **caddy**: Reverse proxy with automatic SSL

## 🎨 Philosophy

### The Anti-Framework Framework

Horsestrap is intentionally minimal. It provides:
- **Structure without constraints**
- **Defaults without lock-in**  
- **Automation without magic**
- **Production-ready without complexity**

### Core Principles

1. **Zero Configuration**: Works immediately after clone
2. **Production First**: Every project deploys to production
3. **2-Minute Rule**: Clone to production in under 2 minutes
4. **Self-Healing**: Automatic failure recovery
5. **No Dependencies**: Just Docker and Git

## 📁 Project Structure

```
your-project/
├── setup.sh                 # Production deployment
├── deploy.sh                # Zero-downtime updates
├── docker-compose.yml       # Service orchestration  
├── .env.example             # Configuration template
├── Caddyfile                # SSL and proxy config
├── YourApp.Web/             # Your application code
│   ├── appsettings.json           # Base config
│   ├── appsettings.Production.json # Production overrides
│   └── Dockerfile
└── media/                   # User uploads (persistent)
```

## ⚙️ Configuration

### Environment Variables (.env)
```bash
DOMAIN=yourdomain.com           # Your domain
SA_PASSWORD=SecurePassword123!  # Database password  
DB_NAME=YourApp_Web            # Database name
ASPNETCORE_ENVIRONMENT=Production
```

### Advanced Configuration
Override any framework setting via environment variables:
```bash
# Examples for .NET/Umbraco
Umbraco__CMS__Security__AllowConcurrentLogins=true
Serilog__MinimumLevel__Default=Debug
ConnectionStrings__DefaultConnection=your-connection-string
```

## 🚀 Getting Started

### Two-Step Process: Development → Production

**Step 1: Development (Your Local Machine)**
```bash
# Install Horsestrap CLI on your development machine
curl -fsSL https://horsestrap.com/install.sh | sudo bash

# Create new project
horsestrap init MyProject
cd MyProject

# Local development with .NET (no Docker required)
cd MyProject.Web
dotnet run
# Your site runs at http://localhost:5000
# Uses SQLite database - no setup required

# Build your application
# - Add features, content, styling
# - Test functionality locally
# - Commit code to Git repository

git add .
git commit -m "My awesome project"
git push origin main
```

**Step 2: Production (Your Ubuntu Server)**
```bash
# On your production server, install Horsestrap
curl -fsSL https://horsestrap.com/install.sh | sudo bash

# Clone your developed project
git clone https://github.com/yourusername/MyProject.git
cd MyProject

# Deploy to production (interactive setup)
horsestrap setup
# Prompts for domain, generates SSL certificates
# Automatically switches to SQL Server database
# Site goes live immediately

# For future updates from your dev machine:
git push origin main        # Push changes
# Then on server:
horsestrap update          # Zero-downtime deployment
```

### Alternative: Add to Existing Project
```bash
# If you have an existing .NET project
git clone https://github.com/mykebates/horsestrap.git temp-horsestrap
cp temp-horsestrap/{setup.sh,deploy.sh,docker-compose.yml,Caddyfile} /path/to/your-project/
rm -rf temp-horsestrap

# Edit docker-compose.yml to match your project structure
# Follow the two-step process above
```

## 🔧 Common Workflows

### Local Development
```bash
cd YourProject.Web
dotnet run
# Site runs at http://localhost:5000
# Uses SQLite, no Docker needed
```

### Production Deployment  
```bash
horsestrap setup
# Prompts for domain, passwords, etc.
# Automatically configures SSL, database
# Site goes live immediately
```

### Updates
```bash
git pull
horsestrap update
# Zero-downtime deployment
# Automatic rollback on failure
```

### Monitoring
```bash
horsestrap status    # Service health
horsestrap logs      # Application logs  
horsestrap logs --db # Database logs
```

## 🆘 Troubleshooting

### Service Issues
```bash
horsestrap status           # Check all services
horsestrap logs --web      # Web application logs
horsestrap restart         # Restart all services
```

### Common Problems

**"Site not accessible"**
- Verify DNS points to your server
- Check DOMAIN in `.env` file  
- Ensure ports 80/443 are open

**"Database connection failed"**
- Check SA_PASSWORD in `.env`
- Verify database service: `horsestrap status`

**"Permission denied"**  
- Fix media permissions: `sudo chown -R 1000:1000 media`

## 🔒 Security

- **Automatic HTTPS**: Let's Encrypt SSL certificates
- **Strong Passwords**: Generated automatically
- **Container Isolation**: Non-root user execution
- **Regular Updates**: Security patches via base images
- **Health Monitoring**: Automatic failure detection

## 🌟 Complete Workflow Examples

### Create a Blog

**Step 1: Development (Your Local Machine)**
```bash
# Install Horsestrap CLI locally
curl -fsSL https://horsestrap.com/install.sh | sudo bash

# Create new project
horsestrap init MyBlog
cd MyBlog

# Local development - build your blog
cd MyBlog.Web
dotnet run
# Site runs at http://localhost:5000
# Edit content, customize theme, add posts, etc.
# Commit your changes to Git
```

**Step 2: Production Deployment (Your Ubuntu Server)**
```bash
# On your Ubuntu server, install Horsestrap
curl -fsSL https://horsestrap.com/install.sh | sudo bash

# Clone your developed project
git clone https://github.com/yourusername/MyBlog.git
cd MyBlog

# Deploy to production
horsestrap setup --domain=myblog.com
# Site goes live at https://myblog.com with SSL
```

### E-commerce Site

**Step 1: Development (Your Local Machine)**
```bash
# Install Horsestrap CLI locally
curl -fsSL https://horsestrap.com/install.sh | sudo bash

# Create new project
horsestrap init MyStore
cd MyStore

# Local development - build your e-commerce features
cd MyStore.Web
dotnet run
# Site runs at http://localhost:5000
# Add products, shopping cart, payment integration, etc.
# Test thoroughly, commit changes
```

**Step 2: Production Deployment (Your Ubuntu Server)**
```bash
# On your Ubuntu server, install Horsestrap
curl -fsSL https://horsestrap.com/install.sh | sudo bash

# Clone your developed project
git clone https://github.com/yourusername/MyStore.git
cd MyStore

# Deploy to production with custom domain
horsestrap setup --domain=mystore.com
# Store goes live at https://mystore.com
```

### Corporate Website

**Step 1: Development (Your Local Machine)**
```bash
# Install Horsestrap CLI locally
curl -fsSL https://horsestrap.com/install.sh | sudo bash

# Create new project
horsestrap init CorporateSite
cd CorporateSite

# Local development - build corporate features
cd CorporateSite.Web
dotnet run
# Site runs at http://localhost:5000
# Add company pages, team bios, contact forms, etc.
# Perfect the design, test functionality
```

**Step 2: Production Deployment (Your Ubuntu Server)**
```bash
# On your Ubuntu server, install Horsestrap
curl -fsSL https://horsestrap.com/install.sh | sudo bash

# Clone your completed project
git clone https://github.com/yourcompany/CorporateSite.git
cd CorporateSite

# Deploy to production
horsestrap setup --domain=company.com
# Corporate site goes live at https://company.com
```

## 🖥 Server Requirements (Ubuntu)

**Minimum Requirements:**
- Ubuntu 20.04 LTS or newer
- 2GB RAM (for SQL Server)
- 10GB disk space
- Ports 80 and 443 open
- Domain pointing to server IP

**Quick Server Setup:**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Log out and back in for Docker permissions
# Install Horsestrap
curl -fsSL https://horsestrap.com/install.sh | sudo bash
```

## 📚 Documentation

- **Installation**: Get started quickly
- **Configuration**: Environment and advanced settings
- **Deployment**: Production deployment guide
- **Troubleshooting**: Common issues and solutions
- **Examples**: Real-world project examples

## 🤝 Contributing

Horsestrap is open source and welcomes contributions:

- **Bug Reports**: Found an issue? Let us know
- **Feature Requests**: Ideas for improvements  
- **Documentation**: Help others get started
- **Code**: Submit PRs for fixes and features

## 📄 License

MIT License - Use it, modify it, deploy it.

---

**Build your own damn tools.** 🐴

*Made with ☕ and strong opinions by developers who value their time.*