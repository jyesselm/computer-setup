#!/bin/bash
# Install Homebrew packages and casks from configuration file (macOS only)

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMON_DIR="$ROOT_DIR/common"
CONFIG_DIR="$ROOT_DIR/config"

# Source common utilities
source "$COMMON_DIR/lib.sh"

# Default config file
CONFIG_FILE="${CONFIG_DIR}/homebrew.yml"

# Check if running on macOS
if ! is_macos; then
    log_error "This script is for macOS only."
    exit 1
fi

# Check if Homebrew is installed
check_homebrew() {
    if ! command_exists brew; then
        log_error "Homebrew is not installed. Please run install_package_manager.sh first."
        return 1
    fi
    log_success "Homebrew is installed: $(which brew)"
    return 0
}

# Parse YAML config file
parse_homebrew_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Extract taps (stop at next top-level key)
    local taps=$(awk '/^taps:/{flag=1; next} /^[a-z_]+:/{flag=0} flag && /^[[:space:]]*-/ {gsub(/^[[:space:]]*-[[:space:]]*/, ""); gsub(/#.*$/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (length > 0) print}' "$config_file" | tr '\n' ' ')
    
    # Extract packages (stop at next top-level key)
    local packages=$(awk '/^packages:/{flag=1; next} /^[a-z_]+:/{flag=0} flag && /^[[:space:]]*-/ {gsub(/^[[:space:]]*-[[:space:]]*/, ""); gsub(/#.*$/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (length > 0) print}' "$config_file" | tr '\n' ' ')
    
    # Extract casks (stop at next top-level key)
    local casks=$(awk '/^casks:/{flag=1; next} /^[a-z_]+:/{flag=0} flag && /^[[:space:]]*-/ {gsub(/^[[:space:]]*-[[:space:]]*/, ""); gsub(/#.*$/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (length > 0) print}' "$config_file" | tr '\n' ' ')
    
    echo "$taps|$packages|$casks"
}

# Install Homebrew taps
install_taps() {
    local taps="$1"
    
    if [ -z "$taps" ]; then
        return 0
    fi
    
    log_info "Adding Homebrew taps..."
    for tap in $taps; do
        if [ -n "$tap" ]; then
            if brew tap | grep -q "^${tap}$"; then
                log_info "  Tap $tap is already added"
            else
                log_info "  Adding tap: $tap"
                brew tap "$tap" || log_warning "Failed to add tap: $tap"
            fi
        fi
    done
}

# Install Homebrew packages
install_packages() {
    local packages="$1"
    
    if [ -z "$packages" ]; then
        return 0
    fi
    
    log_info "Installing Homebrew packages..."
    
    # Install packages one by one for better error handling
    for package in $packages; do
        if [ -n "$package" ]; then
            if brew list "$package" &> /dev/null; then
                log_info "  $package is already installed"
            else
                log_info "  Installing $package..."
                brew install "$package" || log_warning "Failed to install $package"
            fi
        fi
    done
}

# Install Homebrew casks
install_casks() {
    local casks="$1"
    
    if [ -z "$casks" ]; then
        return 0
    fi
    
    log_info "Installing Homebrew casks (GUI applications)..."
    
    # Install casks one by one for better error handling
    for cask in $casks; do
        if [ -n "$cask" ]; then
            if brew list --cask "$cask" &> /dev/null; then
                log_info "  $cask is already installed"
            else
                log_info "  Installing $cask..."
                brew install --cask "$cask" || log_warning "Failed to install $cask"
            fi
        fi
    done
}

# Main function
main() {
    if ! check_homebrew; then
        exit 1
    fi
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        log_warning "Configuration file not found: $CONFIG_FILE"
        log_info "Creating default configuration file..."
        # Config file should already exist, but if not, we'll note it
        log_error "Please create $CONFIG_FILE with your package configuration"
        exit 1
    fi
    
    log_info "Parsing configuration file: $CONFIG_FILE"
    local config_data=$(parse_homebrew_config "$CONFIG_FILE")
    local taps=$(echo "$config_data" | cut -d'|' -f1)
    local packages=$(echo "$config_data" | cut -d'|' -f2)
    local casks=$(echo "$config_data" | cut -d'|' -f3)
    
    # Update Homebrew
    log_info "Updating Homebrew..."
    brew update
    
    # Install taps
    if [ -n "$taps" ]; then
        if prompt_yes_no "Add Homebrew taps from config?" "y"; then
            install_taps "$taps"
            echo ""
        fi
    fi
    
    # Install packages
    if [ -n "$packages" ]; then
        if prompt_yes_no "Install Homebrew packages from config?" "y"; then
            install_packages "$packages"
            echo ""
        fi
    fi
    
    # Install casks
    if [ -n "$casks" ]; then
        if prompt_yes_no "Install Homebrew casks (GUI applications) from config?" "n"; then
            install_casks "$casks"
            echo ""
        fi
    fi
    
    log_success "Homebrew package installation complete"
}

main "$@"

