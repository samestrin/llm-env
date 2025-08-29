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
RAW_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/${SCRIPT_NAME}"

print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    LLM Environment Manager                  ║"
    echo "║                         Installer                           ║"
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
    print_step "Downloading llm-env script..."
    
    local temp_file
    temp_file=$(mktemp)
    
    if curl -fsSL "$RAW_URL" -o "$temp_file"; then
        print_success "Downloaded successfully"
    else
        print_error "Failed to download script from $RAW_URL"
        print_error "Please check your internet connection and try again."
        rm -f "$temp_file"
        exit 1
    fi
    
    # Verify the script looks correct
    if ! grep -q "llm_manager.sh" "$temp_file"; then
        print_error "Downloaded file doesn't appear to be the correct script"
        rm -f "$temp_file"
        exit 1
    fi
    
    # Install the script
    if mv "$temp_file" "$INSTALL_DIR/$SCRIPT_NAME"; then
        chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
        print_success "Installed to $INSTALL_DIR/$SCRIPT_NAME"
    else
        print_error "Failed to install script to $INSTALL_DIR"
        rm -f "$temp_file"
        exit 1
    fi
}

setup_shell_function() {
    print_step "Setting up shell integration..."
    
    local shell_config
    local function_code
    
    # Detect shell and config file
    if [[ "$SHELL" == */zsh ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ "$SHELL" == */bash ]]; then
        shell_config="$HOME/.bashrc"
    else
        print_warning "Unknown shell: $SHELL. Please manually add the function to your shell config."
        return
    fi
    
    function_code="
# LLM Environment Manager
llm_manager() {
    source $INSTALL_DIR/$SCRIPT_NAME \"\$@\"
}"
    
    # Check if function already exists
    if [[ -f "$shell_config" ]] && grep -q "llm_manager()" "$shell_config"; then
        print_warning "llm_manager function already exists in $shell_config"
        return
    fi
    
    # Add function to shell config
    if echo "$function_code" >> "$shell_config"; then
        print_success "Added llm_manager function to $shell_config"
    else
        print_error "Failed to add function to $shell_config"
        print_warning "Please manually add this to your shell config:"
        echo "$function_code"
    fi
}

show_next_steps() {
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║                     Installation Complete!                  ║"
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
    echo -e "   ${BLUE}llm_manager list${NC}"
    echo
    echo "4. Set your first provider:"
    echo -e "   ${BLUE}llm_manager set cerebras${NC}"
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
            --help|-h)
                echo "Usage: $0 [--install-dir DIR]"
                echo "  --install-dir DIR    Install to custom directory (default: /usr/local/bin)"
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
    setup_shell_function
    show_next_steps
}

# Run main function
main "$@"