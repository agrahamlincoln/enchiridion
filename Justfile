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
    #!/usr/bin/env bash
    set -euo pipefail

    echo "--- 🚀 Starting Full Environment Setup ---"

    # --- System Package Installation ---
    echo -e "\n--- 📦 Checking System Packages ---"
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "🍏 Detected macOS."
        if ! command -v brew &>/dev/null; then
            echo "-> Homebrew not found. Installing..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            echo "- Homebrew is already installed."
        fi
        if ! brew list stow &>/dev/null; then
            echo "-> stow not found. Installing..."
            brew install stow
        else
            echo "- stow is already installed."
        fi
    elif [[ "$(uname)" == "Linux" ]]; then
        echo "🐧 Detected Linux."
        if ! command -v stow &>/dev/null; then
            echo "-> stow not found. Installing..."
            sudo pacman -S --noconfirm --needed stow
        else
            echo "- stow is already installed."
        fi
        if ! command -v paru &>/dev/null; then
            echo "❌ AUR helper 'paru' not found. Please install it to proceed." >&2
            exit 1
        else
            echo "- paru is already installed."
        fi
    else
        echo "❌ Unsupported OS: $(uname)" >&2
        exit 1
    fi

    # --- Python Dependency Installation ---
    echo -e "\n--- 🐍 Checking Python Dependencies ---"
    REQUIRED_PY_PKGS_PIP="python-dotenv requests numpy"
    REQUIRED_PY_PKGS_PACMAN="python-dotenv python-requests python-numpy"
    if [[ "$(uname)" == "Darwin" ]]; then
        # On macOS, check with pip
        if ! pip list | grep -q -E "python-dotenv|requests|numpy"; then
            echo "-> Installing Python packages with pip..."
            pip install --user $REQUIRED_PY_PKGS_PIP
        else
            echo "- All required Python packages are already installed."
        fi
    elif [[ "$(uname)" == "Linux" ]]; then
        # On Linux, check with pacman before calling paru to avoid sudo prompt
        if ! pacman -Q $REQUIRED_PY_PKGS_PACMAN &>/dev/null; then
            echo "-> Installing Python packages with paru..."
            paru -S --noconfirm --needed $REQUIRED_PY_PKGS_PACMAN
        else
            echo "- All required Python packages are already installed."
        fi
    fi

    # --- Dotfiles Installation ---
    echo -e "\n--- 🤖 Installing Dotfiles ---"
    if [[ "$(uname)" == "Darwin" ]]; then
        just -f {{justfile()}} install-dotfiles kitty yabai skhd zed vim
    else
        just -f {{justfile()}} install-dotfiles kitty hypr waybar zed vim gammastep
    fi

    # --- Final Configuration ---
    echo -e "\n--- ⚙️  Configuring Environment ---"
    just -f {{justfile()}} install-bashinit
    just -f {{justfile()}} setup-env

    echo -e "\n--- ✅ Full Setup Complete ---"

# Securely fetches a GitHub Personal Access Token (PAT) from Bitwarden and
# creates a local .env file for use by other scripts. This target is idempotent.
setup-env:
    #!/usr/bin/env bash
    set -euo pipefail

    if [ -f .env ] && grep -q "GITHUB_TOKEN=." .env; then
        echo "- GITHUB_TOKEN already exists in .env file."
        exit 0
    fi

    echo "-> GITHUB_TOKEN not found. Proceeding with Bitwarden fetch..."

    if ! command -v bw &> /dev/null; then
        echo "-> Bitwarden CLI ('bw') not found. Please install it to continue." >&2
        exit 1
    fi
    if ! command -v jq &> /dev/null; then
        echo "-> 'jq' is not installed. Please install it to continue." >&2
        exit 1
    fi

    echo "-> Unlocking Bitwarden vault..."
    export BW_SESSION=$(bw unlock --raw)
    if [ -z "$BW_SESSION" ]; then
        echo "❌ Failed to unlock Bitwarden vault. Aborting." >&2
        exit 1
    fi
    echo "✅ Vault unlocked."

    echo "-> Fetching GitHub PAT..."
    GITHUB_PAT=$(bw get item deb260f9-2769-4089-922e-ab6d004c43c2 | jq -r '.fields[0].value')
    if [ -z "$GITHUB_PAT" ]; then
        echo "❌ Could not retrieve GitHub PAT." >&2
        bw lock
        exit 1
    fi
    echo "✅ Token fetched."

    echo "-> Writing token to .env file..."
    echo "GITHUB_TOKEN=$GITHUB_PAT" > .env
    echo "✅ .env file created."

    echo "-> Locking Bitwarden vault..."
    bw lock
    echo "✅ Vault locked."
