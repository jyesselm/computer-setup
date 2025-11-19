#!/bin/bash
# Set up conda/mamba/minimamba and install packages from configuration file

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMON_DIR="$ROOT_DIR/common"
CONFIG_DIR="$ROOT_DIR/config"

# Source common utilities
source "$COMMON_DIR/lib.sh"

# Default config file
CONFIG_FILE="${CONFIG_DIR}/conda.yml"

# Detect conda/mamba/minimamba
detect_conda_variant() {
    if command_exists mamba; then
        echo "mamba"
    elif command_exists minimamba; then
        echo "minimamba"
    elif command_exists conda; then
        echo "conda"
    else
        echo "none"
    fi
}

# Install conda/mamba/minimamba
install_conda_variant() {
    local variant="$1"
    
    if is_macos; then
        if ! command_exists brew; then
            log_error "Homebrew is not installed. Please run install_package_manager.sh first."
            return 1
        fi
        
        case "$variant" in
            mamba)
                log_info "Installing mambaforge via Homebrew..."
                brew install --cask mambaforge || {
                    log_warning "Homebrew cask not available, installing manually..."
                    install_mambaforge_manual
                }
                ;;
            conda)
                log_info "Installing miniconda via Homebrew..."
                brew install --cask miniconda || {
                    log_warning "Homebrew cask not available, installing manually..."
                    install_miniconda_manual
                }
                ;;
            *)
                log_error "Unknown variant: $variant"
                return 1
                ;;
        esac
        
        # Initialize conda for the current shell
        if [ -f "$HOME/mambaforge/etc/profile.d/conda.sh" ]; then
            source "$HOME/mambaforge/etc/profile.d/conda.sh"
        elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
            source "$HOME/miniconda3/etc/profile.d/conda.sh"
        elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
            source "$HOME/anaconda3/etc/profile.d/conda.sh"
        fi
        
    elif is_linux; then
        case "$variant" in
            mamba|minimamba)
                log_info "Installing mambaforge..."
                install_mambaforge_manual
                ;;
            conda)
                log_info "Installing miniconda..."
                install_miniconda_manual
                ;;
            *)
                log_error "Unknown variant: $variant"
                return 1
                ;;
        esac
    fi
}

# Manual installation of mambaforge
install_mambaforge_manual() {
    local installer_url="https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
    local installer_file="/tmp/mambaforge-installer.sh"
    
    log_info "Downloading mambaforge installer..."
    curl -fsSL "$installer_url" -o "$installer_file"
    
    log_info "Installing mambaforge..."
    bash "$installer_file" -b -p "$HOME/mambaforge"
    
    # Initialize
    "$HOME/mambaforge/bin/conda" init bash zsh
    
    log_success "Mambaforge installed to $HOME/mambaforge"
    log_info "Please restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
    
    rm "$installer_file"
}

# Manual installation of miniconda
install_miniconda_manual() {
    local installer_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-$(uname)-$(uname -m).sh"
    local installer_file="/tmp/miniconda-installer.sh"
    
    log_info "Downloading miniconda installer..."
    curl -fsSL "$installer_url" -o "$installer_file"
    
    log_info "Installing miniconda..."
    bash "$installer_file" -b -p "$HOME/miniconda3"
    
    # Initialize
    "$HOME/miniconda3/bin/conda" init bash zsh
    
    log_success "Miniconda installed to $HOME/miniconda3"
    log_info "Please restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
    
    rm "$installer_file"
}

# Parse YAML config file (simple parser)
parse_yaml_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Extract channels (stop at next top-level key)
    local channels=$(awk '/^channels:/{flag=1; next} /^[a-z_]+:/{flag=0} flag && /^[[:space:]]*-/ {gsub(/^[[:space:]]*-[[:space:]]*/, ""); gsub(/#.*$/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (length > 0) print}' "$config_file" | tr '\n' ' ')
    
    # Extract conda packages (stop at next top-level key)
    local conda_packages=$(awk '/^conda_packages:/{flag=1; next} /^[a-z_]+:/{flag=0} flag && /^[[:space:]]*-/ {gsub(/^[[:space:]]*-[[:space:]]*/, ""); gsub(/#.*$/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (length > 0) print}' "$config_file" | tr '\n' ' ')
    
    # Extract pip packages (stop at next top-level key)
    local pip_packages=$(awk '/^pip_packages:/{flag=1; next} /^[a-z_]+:/{flag=0} flag && /^[[:space:]]*-/ {gsub(/^[[:space:]]*-[[:space:]]*/, ""); gsub(/#.*$/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (length > 0) print}' "$config_file" | tr '\n' ' ')
    
    # Extract environment name (default to py3 if not specified)
    local env_name=$(grep "^environment_name:" "$config_file" | sed 's/^[[:space:]]*environment_name:[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's/#.*$//' | sed 's/null//' | sed 's/"//g' | sed "s/'//g" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    # Default to py3 if empty
    if [ -z "$env_name" ]; then
        env_name="py3"
    fi
    
    echo "$channels|$conda_packages|$pip_packages|$env_name"
}

# Install packages from config
install_from_config() {
    local config_file="$1"
    local variant="$2"
    
    log_info "Parsing configuration file: $config_file"
    
    local config_data=$(parse_yaml_config "$config_file")
    local channels=$(echo "$config_data" | cut -d'|' -f1)
    local conda_packages=$(echo "$config_data" | cut -d'|' -f2)
    local pip_packages=$(echo "$config_data" | cut -d'|' -f3)
    local env_name=$(echo "$config_data" | cut -d'|' -f4)
    
    # Initialize conda if not already initialized
    if ! command_exists conda; then
        if [ -f "$HOME/mambaforge/etc/profile.d/conda.sh" ]; then
            source "$HOME/mambaforge/etc/profile.d/conda.sh"
        elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
            source "$HOME/miniconda3/etc/profile.d/conda.sh"
        elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
            source "$HOME/anaconda3/etc/profile.d/conda.sh"
        fi
    fi
    
    # Determine target environment (default to py3)
    local target_env="${env_name:-py3}"
    
    # Create environment if it doesn't exist
    if ! conda env list | grep -q "^$target_env "; then
        log_info "Creating conda environment: $target_env"
        $variant create -n "$target_env" -y
    fi
    
    log_info "Using environment: $target_env"
    
    # Add channels
    if [ -n "$channels" ]; then
        log_info "Adding conda channels..."
        for channel in $channels; do
            if [ -n "$channel" ]; then
                log_info "  Adding channel: $channel"
                $variant config --add channels "$channel" 2>/dev/null || true
            fi
        done
    fi
    
    # Install conda packages
    if [ -n "$conda_packages" ]; then
        log_info "Installing conda packages..."
        local install_cmd="$variant install"
        if [ "$target_env" != "base" ]; then
            install_cmd="$install_cmd -n $target_env"
        fi
        install_cmd="$install_cmd -y"
        
        # Install packages one by one for better error handling
        for package in $conda_packages; do
            if [ -n "$package" ]; then
                log_info "  Installing $package..."
                $install_cmd "$package" || log_warning "Failed to install $package"
            fi
        done
    fi
    
    # Install pip packages
    if [ -n "$pip_packages" ]; then
        log_info "Installing pip packages..."
        local pip_cmd="pip"
        if [ "$target_env" != "base" ]; then
            pip_cmd="conda run -n $target_env pip"
        fi
        
        for package in $pip_packages; do
            if [ -n "$package" ]; then
                log_info "  Installing $package..."
                $pip_cmd install "$package" || log_warning "Failed to install $package"
            fi
        done
    fi
    
    log_success "Package installation complete"
}

# Main function
main() {
    local variant=$(detect_conda_variant)
    
    if [ "$variant" = "none" ]; then
        log_warning "No conda/mamba/minimamba found."
        if prompt_yes_no "Would you like to install mambaforge?" "y"; then
            install_conda_variant "mamba"
            variant="mamba"
            
            # Re-initialize conda
            if [ -f "$HOME/mambaforge/etc/profile.d/conda.sh" ]; then
                source "$HOME/mambaforge/etc/profile.d/conda.sh"
            fi
        else
            log_error "Cannot proceed without conda/mamba/minimamba"
            exit 1
        fi
    else
        log_success "Found $variant: $(which $variant)"
    fi
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        log_warning "Configuration file not found: $CONFIG_FILE"
        log_info "Creating default configuration file..."
        # Config file should already exist, but if not, we'll create it
        if [ ! -d "$CONFIG_DIR" ]; then
            mkdir -p "$CONFIG_DIR"
        fi
    fi
    
    if prompt_yes_no "Install packages from $CONFIG_FILE?" "y"; then
        install_from_config "$CONFIG_FILE" "$variant"
    else
        log_info "Skipping package installation"
    fi
}

main "$@"

