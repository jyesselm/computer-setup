#!/bin/bash
# Install package manager (Homebrew for Mac, or detect Linux package manager)

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../common" && pwd)"

# Source common utilities
source "$COMMON_DIR/lib.sh"

# Install Homebrew on macOS
install_homebrew() {
    if command_exists brew; then
        log_success "Homebrew is already installed"
        log_info "Updating Homebrew..."
        brew update
        return 0
    fi
    
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        log_info "Added Homebrew to PATH (Apple Silicon)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        log_info "Added Homebrew to PATH (Intel)"
    fi
    
    log_success "Homebrew installed successfully"
}

# Detect Linux package manager
detect_linux_pm() {
    if command_exists apt-get; then
        echo "apt"
    elif command_exists yum; then
        echo "yum"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists zypper; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Main function
main() {
    if is_macos; then
        install_homebrew
    elif is_linux; then
        local pm=$(detect_linux_pm)
        log_info "Detected package manager: $pm"
        log_success "Package manager detection complete (no installation needed)"
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

main "$@"

