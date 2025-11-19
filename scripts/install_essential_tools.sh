#!/bin/bash
# Install essential command-line tools

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMON_DIR="$ROOT_DIR/common"
CONFIG_DIR="$ROOT_DIR/config"

# Source common utilities
source "$COMMON_DIR/lib.sh"

# Essential tools list (fallback if config file not used)
ESSENTIAL_TOOLS=(
    "git"
    "yadm"
    "zsh"
    "vim"
    "tmux"
    "curl"
    "wget"
    "jq"
    "tree"
    "htop"
    "ripgrep"
    "fd"
    "bat"
    "exa"
)

# Install tools on macOS via Homebrew
install_macos_tools() {
    if ! command_exists brew; then
        log_error "Homebrew is not installed. Please run install_package_manager.sh first."
        return 1
    fi
    
    # Check if config file exists and user wants to use it
    local config_file="${CONFIG_DIR}/homebrew.yml"
    if [ -f "$config_file" ] && prompt_yes_no "Use Homebrew packages from config file?" "y"; then
        log_info "Using packages from config file: $config_file"
        # Use the dedicated script for config-based installation
        "$SCRIPT_DIR/install_homebrew_packages.sh" || {
            log_warning "Config-based installation had issues, falling back to default list"
            install_macos_tools_fallback
        }
    else
        install_macos_tools_fallback
    fi
}

# Fallback installation using hardcoded list
install_macos_tools_fallback() {
    log_info "Installing essential tools via Homebrew (using default list)..."
    
    for tool in "${ESSENTIAL_TOOLS[@]}"; do
        if brew list "$tool" &> /dev/null; then
            log_info "$tool is already installed"
        else
            log_info "Installing $tool..."
            brew install "$tool" || log_warning "Failed to install $tool"
        fi
    done
    
    log_success "Essential tools installation complete"
}

# Install tools on Linux
install_linux_tools() {
    local pm=$(command -v apt-get &> /dev/null && echo "apt" || \
               command -v yum &> /dev/null && echo "yum" || \
               command -v dnf &> /dev/null && echo "dnf" || \
               command -v pacman &> /dev/null && echo "pacman" || \
               command -v zypper &> /dev/null && echo "zypper" || \
               echo "unknown")
    
    case "$pm" in
        apt)
            log_info "Using apt-get (Debian/Ubuntu)"
            sudo apt-get update
            sudo apt-get install -y git zsh vim tmux curl wget jq tree htop
            
            # Install ripgrep, fd, bat, exa
            sudo apt-get install -y ripgrep fd-find bat exa || {
                log_warning "Some tools may need manual installation"
            }
            
            # Install yadm
            if ! command_exists yadm; then
                log_info "Installing yadm..."
                sudo apt-get install -y yadm || {
                    log_info "Installing yadm manually..."
                    sudo curl -fsSLo /usr/local/bin/yadm https://github.com/TheLocehiliosan/yadm/raw/master/yadm
                    sudo chmod +x /usr/local/bin/yadm
                }
            fi
            ;;
        yum|dnf)
            log_info "Using $pm (RHEL/CentOS/Fedora)"
            sudo $pm install -y git zsh vim tmux curl wget jq tree htop
            # Note: ripgrep, fd, bat, exa may need EPEL or manual installation
            ;;
        pacman)
            log_info "Using pacman (Arch Linux)"
            sudo pacman -S --noconfirm git zsh vim tmux curl wget jq tree htop ripgrep fd bat exa yadm
            ;;
        zypper)
            log_info "Using zypper (openSUSE)"
            sudo zypper install -y git zsh vim tmux curl wget jq tree htop
            ;;
        *)
            log_warning "Unknown Linux distribution. Please install tools manually."
            return 1
            ;;
    esac
    
    log_success "Essential tools installation complete"
}

# Main function
main() {
    if is_macos; then
        install_macos_tools
    elif is_linux; then
        install_linux_tools
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

main "$@"

