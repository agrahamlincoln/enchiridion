# A Justfile for managing dotfiles installation with stow.

# The base directory where dotfiles are located relative to the Justfile.
DOTFILES_DIR := "dotfiles"

# @arg targets: A space-separated list of dotfile targets to install.
install-dotfiles *targets:
    @pushd {{DOTFILES_DIR}} > /dev/null && \
    for target in {{targets}}; do \
        if stow -n -t ~ --dotfiles -S "$target" 2>&1 | grep -q -E '^(LINK|COPY|DELETE):'; then \
            if ! stow -t ~ --dotfiles -S "$target"; then \
                echo "❌ Error: Failed to stow $target. Please check for conflicts or errors." >&2; \
            else \
                echo "✅ Stowed $target."; \
            fi; \
        else \
            echo "- No changes needed for $target."; \
        fi; \
    done && \
    popd > /dev/null

# Installs the bashinit dotfiles and configures .bashrc idempotently.
install-bashinit:
    @if ! grep -q "source ~/.config/bashinit/bashinit.sh" ~/.bashrc; then \
        echo "source ~/.config/bashinit/bashinit.sh" >> ~/.bashrc; \
        echo "✅ Added source line to ~/.bashrc."; \
    else \
        echo "- ~/.bashrc already configured for bashinit."; \
    fi

# Sets up dotfiles based on the operating system.
setup:
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "🍏 Detected macOS. Checking for Homebrew and stow..."; \
        if ! command -v brew &> /dev/null; then \
            echo "Homebrew not found. Installing Homebrew..."; \
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
        fi; \
        if ! brew list stow &> /dev/null; then \
            echo "stow not found. Installing stow..."; \
            brew install stow; \
        fi; \
        just install-dotfiles kitty yabai skhd zed vim; \
    elif [ "$(uname)" = "Linux" ]; then \
        echo "🐧 Detected Linux. Checking for stow..."; \
        if ! command -v stow &> /dev/null; then \
            echo "stow not found. Installing stow..."; \
            sudo pacman -Sy stow --noconfirm; \
        fi; \
        just install-dotfiles kitty hypr waybar zed vim gammastep; \
    else \
        echo "❌ Unsupported OS: $(uname)" >&2; \
        exit 1; \
    fi; \
    just install-bashinit
