# A Justfile for managing dotfiles installation with stow.

# The base directory where dotfiles are located relative to the Justfile.
DOTFILES_DIR := "dotfiles"

# @arg targets: A space-separated list of dotfile targets to install.
install-dotfiles *targets:
    @pushd {{DOTFILES_DIR}} > /dev/null && \
    for target in {{targets}}; do \
        if stow -n -t ~ --dotfiles -S "$target" 2>&1 | grep -q -E '^(LINK|COPY|DELETE):'; then \
            if ! stow -t ~ --dotfiles -S "$target"; then \
                echo "Error: Failed to stow $target. Please check for conflicts or errors." >&2; \
            else \
                echo ":white_check_mark: Stowed $target."; \
            fi; \
        else \
            echo ":white_circle: No changes needed for $target."; \
        fi; \
    done && \
    popd > /dev/null
