#!/usr/bin/env bash
# LLM Environment Manager Installer

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="llm-env"
GITHUB_REPO="samestrin/llm-env"  # Update this with your actual repo
VERSION="main"  # Default to main branch, can be overridden
RAW_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/${VERSION}/${SCRIPT_NAME}"
OFFLINE_FILE=""  # For offline installation

print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    LLM Environment Manager                   ║"
    echo "║                         Installer                            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_requirements() {
    print_step "Checking requirements..."
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed. Please install curl first."
        exit 1
    fi
    
    # Check if we can write to install directory
    if [[ ! -w "$INSTALL_DIR" ]]; then
        print_warning "Cannot write to $INSTALL_DIR. You may need to run with sudo."
        if [[ $EUID -ne 0 ]]; then
            print_error "Please run with sudo: sudo $0"
            exit 1
        fi
    fi
    
    print_success "Requirements check passed"
}

download_script() {
    local temp_file
    temp_file=$(mktemp)
    
    if [[ -n "$OFFLINE_FILE" ]]; then
        print_step "Using offline file: $OFFLINE_FILE"
        
        if [[ ! -f "$OFFLINE_FILE" ]]; then
            print_error "Offline file not found: $OFFLINE_FILE"
            exit 1
        fi
        
        if ! cp "$OFFLINE_FILE" "$temp_file"; then
            print_error "Failed to copy offline file"
            exit 1
        fi
        
        print_success "Offline file copied successfully"
    else
        print_step "Downloading llm-env script from version: $VERSION"
        
        # Update RAW_URL with the current version
        RAW_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/${VERSION}/${SCRIPT_NAME}"
        
        if curl -fsSL "$RAW_URL" -o "$temp_file"; then
            print_success "Downloaded successfully from $RAW_URL"
        else
            print_error "Failed to download script from $RAW_URL"
            print_error "Please check your internet connection and try again."
            print_error "Available versions can be found at: https://github.com/$GITHUB_REPO/releases"
            rm -f "$temp_file"
            exit 1
        fi
    fi
    
    # Verify the script looks correct
    if ! grep -q "llm-env" "$temp_file"; then
        print_error "Downloaded file doesn't appear to be the correct script"
        print_error "This might be due to an invalid version or network issue."
        rm -f "$temp_file"
        exit 1
    fi
    
    # Add integrity verification (basic check)
    local file_size
    file_size=$(wc -c < "$temp_file")
    if [[ "$file_size" -lt 1000 ]]; then
        print_warning "Downloaded file seems unusually small ($file_size bytes)"
        print_warning "This might indicate a download issue or network error."
    else
        print_success "File integrity check passed ($file_size bytes)"
    fi
    
    # Install the script
    if mv "$temp_file" "$INSTALL_DIR/$SCRIPT_NAME"; then
        chmod 755 "$INSTALL_DIR/$SCRIPT_NAME"
        print_success "Installed to $INSTALL_DIR/$SCRIPT_NAME"
    else
        print_error "Failed to install script to $INSTALL_DIR"
        rm -f "$temp_file"
        exit 1
    fi
}

install_config_files() {
    print_step "Installing configuration files..."
    
    local config_dir="$HOME/.config/llm-env"
    local config_file="$config_dir/config.conf"
    
    # Create config directory
    if ! mkdir -p "$config_dir"; then
        print_error "Failed to create config directory: $config_dir"
        return 1
    fi
    
    # Check if config already exists
    if [[ -f "$config_file" ]]; then
        print_warning "Configuration file already exists: $config_file"
        return 0
    fi
    
    # Create default configuration file
    if cat > "$config_file" << 'EOF'
# LLM Environment Manager Configuration
# This file defines available LLM providers and their settings

[cerebras]
base_url=https://api.cerebras.ai/v1
api_key_var=LLM_CEREBRAS_API_KEY
default_model=qwen-3-coder-480b
description=Fast inference, great for coding
enabled=true

[openai]
base_url=https://api.openai.com/v1
api_key_var=LLM_OPENAI_API_KEY
default_model=gpt-5-2025-08-07
description=Industry standard, highest quality
enabled=true

[groq]
base_url=https://api.groq.com/openai/v1
api_key_var=LLM_GROQ_API_KEY
default_model=openai/gpt-oss-120b
description=Lightning-fast inference
enabled=true

[openrouter]
base_url=https://openrouter.ai/api/v1
api_key_var=LLM_OPENROUTER_API_KEY
default_model=deepseek/deepseek-chat-v3.1:free
description=Free tier option
enabled=true
EOF
    then
        print_success "Created default configuration: $config_file"
    else
        print_error "Failed to create configuration file"
        return 1
    fi
}

setup_shell_function() {
    print_step "Setting up shell integration..."
    
    local shell_config
    local function_code
    
    # Detect shell and config file
    case "$SHELL" in
        */zsh|*/bash)
            if [[ "$SHELL" == */zsh ]]; then
                shell_config="$HOME/.zshrc"
            else
                shell_config="$HOME/.bashrc"
                [[ ! -f "$shell_config" && -f "$HOME/.bash_profile" ]] && shell_config="$HOME/.bash_profile"
            fi
            function_code="
# LLM Environment Manager
llm-env() {
    source $INSTALL_DIR/$SCRIPT_NAME \"\$@\"
}"
            ;;
        */fish)
            shell_config="$HOME/.config/fish/config.fish"
            # Create fish config directory if it doesn't exist
            mkdir -p "$(dirname "$shell_config")"
            function_code="
# LLM Environment Manager
function llm-env
    source $INSTALL_DIR/$SCRIPT_NAME \$argv
end"
            ;;
        */csh|*/tcsh)
            if [[ "$SHELL" == */csh ]]; then
                shell_config="$HOME/.cshrc"
            else
                shell_config="$HOME/.tcshrc"
                [[ ! -f "$shell_config" && -f "$HOME/.cshrc" ]] && shell_config="$HOME/.cshrc"
            fi
            function_code="
# LLM Environment Manager
alias llm-env 'source $INSTALL_DIR/$SCRIPT_NAME'"
            ;;
        *)
            print_warning "Unsupported shell: $SHELL. Please manually add the function to your shell config."
            print_warning "Add this to your shell config:"
            echo "alias llm-env='source $INSTALL_DIR/$SCRIPT_NAME'"
            return
            ;;
    esac
    
    # Check if function already exists
    if [[ -f "$shell_config" ]] && grep -q "llm-env()" "$shell_config"; then
        print_warning "llm-env function already exists in $shell_config"
        return
    fi
    
    # Add function to shell config
    if echo "$function_code" >> "$shell_config"; then
        print_success "Added llm-env function to $shell_config"
    else
        print_error "Failed to add function to $shell_config"
        print_warning "Please manually add this to your shell config:"
        echo "$function_code"
    fi
}

uninstall_llm_env() {
    print_step "Uninstalling LLM Environment Manager..."
    
    # Remove main script
    if [[ -f "$INSTALL_DIR/$SCRIPT_NAME" ]]; then
        if rm -f "$INSTALL_DIR/$SCRIPT_NAME"; then
            print_success "Removed $INSTALL_DIR/$SCRIPT_NAME"
        else
            print_error "Failed to remove $INSTALL_DIR/$SCRIPT_NAME"
        fi
    else
        print_warning "Script not found at $INSTALL_DIR/$SCRIPT_NAME"
    fi
    
    # Remove shell function from config files
    local shell_configs=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile")
    
    for config in "${shell_configs[@]}"; do
        if [[ -f "$config" ]] && grep -q "llm-env()" "$config"; then
            print_step "Removing function from $config..."
            
            # Create backup
            cp "$config" "$config.llm-env-backup"
            
            # Remove the function (from # LLM Environment Manager to the closing brace)
            sed -i.tmp '/# LLM Environment Manager/,/^llm-env()/d; /^llm-env()/,/^}/d' "$config" && rm "$config.tmp"
            
            print_success "Removed llm-env function from $config"
            print_warning "Backup created: $config.llm-env-backup"
        fi
    done
    
    # Ask about configuration files
    echo
    read -p "Remove configuration files? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local config_dir="$HOME/.config/llm-env"
        if [[ -d "$config_dir" ]]; then
            print_step "Creating backup of configuration..."
            local backup_dir
            backup_dir="$HOME/.config/llm-env-backup-$(date +%Y%m%d_%H%M%S)"
            if mv "$config_dir" "$backup_dir"; then
                print_success "Configuration backed up to: $backup_dir"
            else
                print_error "Failed to backup configuration"
            fi
        fi
    else
        print_warning "Configuration files preserved at $HOME/.config/llm-env"
    fi
    
    echo
    print_success "Uninstallation completed!"
    echo -e "${YELLOW}Note: You may need to reload your shell or restart your terminal.${NC}"
}

show_next_steps() {
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║                     Installation Complete!                   ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo
    echo "1. Reload your shell configuration:"
    echo -e "   ${BLUE}source ~/.bashrc${NC}  # or ~/.zshrc"
    echo
    echo "2. Set up your API keys in your shell config file:"
    echo -e "   ${BLUE}# Add these to ~/.bashrc or ~/.zshrc"
    echo -e "   export LLM_CEREBRAS_API_KEY=\"your_key_here\""
    echo -e "   export LLM_OPENAI_API_KEY=\"your_key_here\""
    echo -e "   export LLM_GROQ_API_KEY=\"your_key_here\""
    echo -e "   export LLM_OPENROUTER_API_KEY=\"your_key_here\"${NC}"
    echo
    echo "3. Test the installation:"
    echo -e "   ${BLUE}llm-env list${NC}"
    echo
    echo "4. Set your first provider:"
    echo -e "   ${BLUE}llm-env set cerebras${NC}"
    echo
    echo -e "${GREEN}Happy LLM switching! 🚀${NC}"
    echo
    echo "For more information, visit: https://github.com/$GITHUB_REPO"
}

# Main installation flow
main() {
    print_header
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install-dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --version)
                VERSION="$2"
                shift 2
                ;;
            --offline)
                OFFLINE_FILE="$2"
                shift 2
                ;;
            --uninstall)
                uninstall_llm_env
                exit 0
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --install-dir DIR    Install to custom directory (default: /usr/local/bin)"
                echo "  --version VERSION    Install specific version or branch (default: main)"
                echo "  --offline FILE       Install from local file instead of downloading"
                echo "  --uninstall          Remove LLM Environment Manager"
                echo "  --help, -h           Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                           # Install latest from main branch"
                echo "  $0 --version v1.0.0          # Install specific version"
                echo "  $0 --offline ./llm-env       # Install from local file"
                echo "  $0 --install-dir ~/.local/bin # Install to custom directory"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    check_requirements
    download_script
    install_config_files
    setup_shell_function
    show_next_steps
}

# Run main function
main "$@"