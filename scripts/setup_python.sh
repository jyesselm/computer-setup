#!/bin/bash
# Set up Python development environment

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../common" && pwd)"

# Source common utilities
source "$COMMON_DIR/lib.sh"

# Python packages to install
PYTHON_PACKAGES=(
    "ipython"
    "jupyter"
    "black"
    "flake8"
    "mypy"
    "pytest"
    "virtualenv"
    "pipenv"
    "poetry"
)

# Install Python on macOS
install_macos_python() {
    if ! command_exists python3; then
        log_info "Installing Python via Homebrew..."
        brew install python@3.11
    else
        log_success "Python is already installed: $(python3 --version)"
    fi
}

# Install Python packages
install_python_packages() {
    if ! command_exists pip3; then
        log_error "pip3 is not available. Please install Python first."
        return 1
    fi
    
    log_info "Upgrading pip..."
    pip3 install --upgrade pip
    
    log_info "Installing Python packages..."
    for package in "${PYTHON_PACKAGES[@]}"; do
        log_info "Installing $package..."
        pip3 install --user "$package" || log_warning "Failed to install $package"
    done
    
    log_success "Python packages installed"
}

# Main function
main() {
    if is_macos; then
        if ! command_exists brew; then
            log_error "Homebrew is not installed. Please run install_package_manager.sh first."
            return 1
        fi
        install_macos_python
    elif is_linux; then
        if ! command_exists python3; then
            log_warning "Python3 is not installed. Please install it via your package manager."
            return 1
        else
            log_success "Python is already installed: $(python3 --version)"
        fi
    fi
    
    if prompt_yes_no "Install Python development packages?" "y"; then
        install_python_packages
    fi
}

main "$@"

