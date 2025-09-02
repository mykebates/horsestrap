#!/bin/bash

# Horsestrap Installer
# The distinguished way to deploy

set -e

# Colors for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ASCII Horse with top hat
show_horse() {
    echo -e "${BOLD}${BLUE}"
    cat << "EOF"
        🎩
       /|\
      / | \
     🐴 |  |
        |  |
       / \/ \
      /   \  \
EOF
    echo -e "${NC}"
}

# Print colored output
print_info() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_step() {
    echo -e "${BLUE}→${NC} $1"
}

# Main installation
main() {
    show_horse
    echo -e "${BOLD}Installing Horsestrap - The Anti-Framework Framework${NC}\n"
    
    # Detect OS
    OS="$(uname -s)"
    case "${OS}" in
        Linux*)     PLATFORM=linux;;
        Darwin*)    PLATFORM=macos;;
        *)          PLATFORM="UNKNOWN:${OS}"
    esac
    
    if [ "$PLATFORM" = "UNKNOWN:${OS}" ]; then
        print_error "Unsupported operating system: ${OS}"
        exit 1
    fi
    
    print_step "Detected platform: ${PLATFORM}"
    
    # Set installation directory
    INSTALL_DIR="/usr/local/bin"
    
    # Check for write permissions
    if [ ! -w "$INSTALL_DIR" ]; then
        print_error "No write permission to ${INSTALL_DIR}"
        echo "Try running with sudo: curl -fsSL https://horsestrap.com/install.sh | sudo bash"
        exit 1
    fi
    
    # Download the latest release from GitHub
    print_step "Downloading Horsestrap..."
    
    GITHUB_REPO="mykebates/horsestrap"
    DOWNLOAD_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/bin/horsestrap"
    
    # Create temp file
    TMP_FILE=$(mktemp)
    
    # Download with curl or wget
    if command -v curl > /dev/null; then
        curl -fsSL "$DOWNLOAD_URL" -o "$TMP_FILE"
    elif command -v wget > /dev/null; then
        wget -qO "$TMP_FILE" "$DOWNLOAD_URL"
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    # Make executable
    chmod +x "$TMP_FILE"
    
    # Move to installation directory
    print_step "Installing to ${INSTALL_DIR}/horsestrap..."
    mv "$TMP_FILE" "${INSTALL_DIR}/horsestrap"
    
    # Verify installation
    if command -v horsestrap > /dev/null; then
        INSTALLED_VERSION=$(horsestrap --version 2>/dev/null || echo "unknown")
        print_info "Horsestrap installed successfully!"
        echo -e "\n${BOLD}${GREEN}🎩 Installation complete!${NC}"
        echo -e "\nGet started with:"
        echo -e "  ${BLUE}horsestrap init${NC}      # Create a new project"
        echo -e "  ${BLUE}horsestrap setup${NC}     # Deploy to production"
        echo -e "  ${BLUE}horsestrap --help${NC}    # Show all commands"
        echo -e "\n${YELLOW}Remember: Build your own damn tools.${NC}"
    else
        print_error "Installation failed. Please check your PATH includes ${INSTALL_DIR}"
        exit 1
    fi
}

# Run main function
main "$@"