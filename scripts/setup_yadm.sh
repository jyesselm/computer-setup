#!/bin/bash
# Set up yadm (Yet Another Dotfiles Manager)

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../common" && pwd)"

# Source common utilities
source "$COMMON_DIR/lib.sh"

# Default dotfiles repository
DOTFILES_REPO="https://github.com/jyesselm/dotfiles"

# Check if yadm is installed
check_yadm_installed() {
    if ! command_exists yadm; then
        log_error "yadm is not installed."
        echo ""
        echo "Installation options:"
        echo "  macOS (Homebrew):  brew install yadm"
        echo "  Linux:             See https://yadm.io/docs/install"
        echo ""
        
        if is_macos && command_exists brew; then
            if prompt_yes_no "Install yadm via Homebrew?" "y"; then
                log_info "Installing yadm via Homebrew..."
                brew install yadm
                log_success "yadm installed successfully"
                return 0
            fi
        elif is_linux; then
            if prompt_yes_no "Attempt to install yadm?" "y"; then
                local pm=$(command -v apt-get &> /dev/null && echo "apt" || \
                           command -v pacman &> /dev/null && echo "pacman" || \
                           echo "unknown")
                case "$pm" in
                    apt)
                        sudo apt-get update
                        sudo apt-get install -y yadm || {
                            log_info "Installing yadm manually..."
                            sudo curl -fsSLo /usr/local/bin/yadm https://github.com/TheLocehiliosan/yadm/raw/master/yadm
                            sudo chmod +x /usr/local/bin/yadm
                        }
                        ;;
                    pacman)
                        sudo pacman -S --noconfirm yadm
                        ;;
                    *)
                        log_error "Please install yadm manually. Visit: https://yadm.io/docs/install"
                        return 1
                        ;;
                esac
                log_success "yadm installed successfully"
                return 0
            fi
        fi
        
        log_error "Please install yadm first, then run this script again."
        return 1
    else
        log_success "yadm is installed: $(which yadm)"
        yadm --version
        return 0
    fi
}

# Clone or initialize yadm repository
init_yadm() {
    # Check if yadm repo is already initialized
    if yadm rev-parse --git-dir &> /dev/null; then
        log_success "yadm repository already exists."
        local current_remote=$(yadm remote get-url origin 2>/dev/null || echo "")
        if [ -n "$current_remote" ]; then
            log_info "Current remote: $current_remote"
        fi
        
        if prompt_yes_no "Would you like to pull latest changes?" "y"; then
            log_info "Pulling latest changes from remote..."
            yadm pull || log_warning "Pull failed or no remote configured"
        fi
    else
        log_info "yadm repository not found."
        
        # Check if we should clone the default repository
        local clone_url="$DOTFILES_REPO"
        if prompt_yes_no "Clone dotfiles from $DOTFILES_REPO?" "y"; then
            log_info "Cloning dotfiles repository..."
            yadm clone "$clone_url"
            log_success "Dotfiles repository cloned successfully"
            log_info "The bootstrap script (if present) will run automatically"
        else
            # Ask for custom URL or initialize empty
            if prompt_yes_no "Would you like to clone from a different repository?" "n"; then
                read -p "Enter repository URL: " clone_url
                if [ -n "$clone_url" ]; then
                    log_info "Cloning dotfiles repository..."
                    yadm clone "$clone_url"
                    log_success "Dotfiles repository cloned successfully"
                else
                    log_info "Initializing empty yadm repository..."
                    yadm init
                    log_success "Repository initialized"
                fi
            else
                log_info "Initializing empty yadm repository..."
                yadm init
                log_success "Repository initialized"
                
                if prompt_yes_no "Would you like to add a remote repository?" "n"; then
                    read -p "Enter remote URL: " remote_url
                    if [ -n "$remote_url" ]; then
                        yadm remote add origin "$remote_url"
                        log_success "Remote added: $remote_url"
                    fi
                fi
            fi
        fi
    fi
}

# Main function
main() {
    if ! check_yadm_installed; then
        exit 1
    fi
    
    echo ""
    init_yadm
    
    echo ""
    log_success "yadm setup complete"
    echo ""
    
    # Check if repository was cloned (has remote)
    if yadm rev-parse --git-dir &> /dev/null; then
        local has_remote=$(yadm remote get-url origin 2>/dev/null || echo "")
        if [ -n "$has_remote" ]; then
            echo "Your dotfiles are now set up from: $has_remote"
            echo ""
            echo "Next steps:"
            echo "  1. Restart your terminal to apply changes"
            echo "  2. Check status: yadm status"
            echo "  3. Pull updates: yadm pull"
            echo "  4. Make changes and commit: yadm commit -m 'Update config'"
            echo "  5. Push changes: yadm push"
        else
            echo "Next steps:"
            echo "  1. Add your dotfiles: yadm add ~/.zshrc"
            echo "  2. Create commits: yadm commit -m 'Add dotfiles'"
            echo "  3. Add remote: yadm remote add origin <your-repo-url>"
            echo "  4. Push to remote: yadm push -u origin master"
        fi
    else
        echo "Next steps:"
        echo "  1. Add your dotfiles: yadm add ~/.zshrc"
        echo "  2. Create commits: yadm commit -m 'Add dotfiles'"
        echo "  3. Add remote: yadm remote add origin <your-repo-url>"
        echo "  4. Push to remote: yadm push -u origin master"
    fi
    echo ""
}

main "$@"

