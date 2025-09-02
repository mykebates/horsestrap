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

### Option 1: New Project (Recommended)
```bash
# Install Horsestrap
curl -fsSL https://horsestrap.com/install.sh | sudo bash

# Create project
horsestrap init MyProject
cd MyProject

# Local development
cd MyProject.Web && dotnet run

# Production deployment
horsestrap setup
```

### Option 2: Add to Existing Project
```bash
# Clone Horsestrap template
git clone https://github.com/mykebates/horsestrap.git
cd horsestrap

# Copy deployment files to your project
cp setup.sh deploy.sh docker-compose.yml Caddyfile /path/to/your-project/

# Configure for your stack
# Edit docker-compose.yml, setup.sh as needed
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

## 🌟 Examples

### Create a Blog
```bash
horsestrap init MyBlog
cd MyBlog
# Edit content, customize theme
horsestrap setup --domain=myblog.com
```

### E-commerce Site
```bash
horsestrap init MyStore  
cd MyStore
# Add e-commerce features
horsestrap setup --domain=mystore.com
```

### Corporate Website
```bash
horsestrap init CorporateSite
cd CorporateSite  
# Customize for corporate needs
horsestrap setup --domain=company.com
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