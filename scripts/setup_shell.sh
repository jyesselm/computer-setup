#!/bin/bash
# Set up zsh as default shell and install Oh My Zsh

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../common" && pwd)"

# Source common utilities
source "$COMMON_DIR/lib.sh"

# Set up zsh as default shell
setup_zsh() {
    if ! command_exists zsh; then
        log_error "zsh is not installed. Please run install_essential_tools.sh first."
        return 1
    fi
    
    local current_shell=$(echo $SHELL)
    local zsh_path=$(which zsh)
    
    if [[ "$current_shell" != "$zsh_path" ]]; then
        log_info "Setting zsh as default shell..."
        if is_macos; then
            # On macOS, we need to add zsh to /etc/shells first
            if ! grep -q "$zsh_path" /etc/shells; then
                echo "$zsh_path" | sudo tee -a /etc/shells
            fi
        fi
        chsh -s "$zsh_path"
        log_success "zsh set as default shell (restart terminal to take effect)"
    else
        log_success "zsh is already the default shell"
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_success "Oh My Zsh is already installed"
        return 0
    fi
    
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh My Zsh installed"
}

# Main function
main() {
    if prompt_yes_no "Set up zsh as default shell?" "y"; then
        setup_zsh
    fi
    
    if prompt_yes_no "Install Oh My Zsh?" "y"; then
        install_oh_my_zsh
    fi
}

main "$@"

