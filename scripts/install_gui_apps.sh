#!/bin/bash
# Install GUI applications (macOS only via Homebrew Casks)

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMON_DIR="$ROOT_DIR/common"
CONFIG_DIR="$ROOT_DIR/config"

# Source common utilities
source "$COMMON_DIR/lib.sh"

# GUI applications to install (fallback if config file not used)
GUI_APPS=(
    "iterm2"
    "visual-studio-code"
    "google-chrome"
    "firefox"
    "slack"
    "spotify"
)

# Parse casks from config file
parse_casks_from_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        return 1
    fi
    
    # Extract casks (stop at next top-level key)
    awk '/^casks:/{flag=1; next} /^[a-z_]+:/{flag=0} flag && /^[[:space:]]*-/ {gsub(/^[[:space:]]*-[[:space:]]*/, ""); gsub(/#.*$/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (length > 0) print}' "$config_file" | tr '\n' ' '
}

# Install GUI apps on macOS
install_macos_apps() {
    if ! is_macos; then
        log_warning "GUI apps installation is only supported on macOS"
        return 1
    fi
    
    if ! command_exists brew; then
        log_error "Homebrew is not installed. Please run install_package_manager.sh first."
        return 1
    fi
    
    # Check if config file exists and user wants to use it
    local config_file="${CONFIG_DIR}/homebrew.yml"
    local casks_from_config=""
    
    if [ -f "$config_file" ] && prompt_yes_no "Use Homebrew casks from config file?" "y"; then
        log_info "Using casks from config file: $config_file"
        casks_from_config=$(parse_casks_from_config "$config_file")
        
        if [ -n "$casks_from_config" ]; then
            log_info "Installing GUI applications via Homebrew Casks (from config)..."
            for cask in $casks_from_config; do
                if [ -n "$cask" ]; then
                    if brew list --cask "$cask" &> /dev/null; then
                        log_info "  $cask is already installed"
                    else
                        log_info "  Installing $cask..."
                        brew install --cask "$cask" || log_warning "Failed to install $cask"
                    fi
                fi
            done
            log_success "GUI applications installation complete"
            return 0
        else
            log_warning "No casks found in config file, falling back to default list"
        fi
    fi
    
    install_macos_apps_fallback
}

# Fallback installation using hardcoded list
install_macos_apps_fallback() {
    log_info "Installing GUI applications via Homebrew Casks (using default list)..."
    
    for app in "${GUI_APPS[@]}"; do
        if brew list --cask "$app" &> /dev/null; then
            log_info "$app is already installed"
        else
            log_info "Installing $app..."
            brew install --cask "$app" || log_warning "Failed to install $app"
        fi
    done
    
    log_success "GUI applications installation complete"
}

# Main function
main() {
    if ! is_macos; then
        log_info "This script is for macOS only. Skipping..."
        exit 0
    fi
    
    if prompt_yes_no "Install GUI applications?" "n"; then
        install_macos_apps
    else
        log_info "Skipping GUI applications installation"
    fi
}

main "$@"

