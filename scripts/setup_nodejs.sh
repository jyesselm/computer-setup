#!/bin/bash
# Set up Node.js and npm

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../common" && pwd)"

# Source common utilities
source "$COMMON_DIR/lib.sh"

# Global npm packages to install
NPM_PACKAGES=(
    "yarn"
    "pnpm"
    "typescript"
    "ts-node"
    "eslint"
    "prettier"
    "nodemon"
    "http-server"
)

# Install Node.js on macOS
install_macos_nodejs() {
    if ! command_exists brew; then
        log_error "Homebrew is not installed. Please run install_package_manager.sh first."
        return 1
    fi
    
    if ! command_exists node; then
        log_info "Installing Node.js via Homebrew..."
        brew install node
    else
        log_success "Node.js is already installed: $(node --version)"
    fi
}

# Install Node.js on Linux
install_linux_nodejs() {
    if command_exists node; then
        log_success "Node.js is already installed: $(node --version)"
        return 0
    fi
    
    log_info "Installing Node.js..."
    # Use NodeSource repository for latest LTS
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs || {
        log_warning "Failed to install via NodeSource. You may need to install manually."
        return 1
    }
}

# Install global npm packages
install_npm_packages() {
    if ! command_exists npm; then
        log_error "npm is not available. Please install Node.js first."
        return 1
    fi
    
    log_info "Installing global npm packages..."
    for package in "${NPM_PACKAGES[@]}"; do
        log_info "Installing $package..."
        npm install -g "$package" || log_warning "Failed to install $package"
    done
    
    log_success "npm packages installed"
}

# Main function
main() {
    if is_macos; then
        install_macos_nodejs
    elif is_linux; then
        if prompt_yes_no "Install Node.js?" "y"; then
            install_linux_nodejs
        fi
    fi
    
    if command_exists npm && prompt_yes_no "Install global npm packages?" "y"; then
        install_npm_packages
    fi
}

main "$@"

