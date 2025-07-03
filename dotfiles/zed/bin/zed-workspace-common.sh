#!/usr/bin/env bash

# Zed Workspace Common Functions
# Shared logic for all Zed workspace scripts

# Configuration: Projects directory
# Set ZED_PROJECTS_DIR environment variable to customize, defaults to ~/projects
ZED_PROJECTS_DIR="${ZED_PROJECTS_DIR:-$HOME/projects}"

open_zed_workspace() {
    local workspace_name="$1"
    shift
    local workspace_dirs=("$@")

    # Check if any directories were provided
    if [[ ${#workspace_dirs[@]} -eq 0 ]]; then
        echo "No workspace directories defined for $workspace_name"
        exit 1
    fi

    # Print what we are opening
    echo "Opening Zed $workspace_name workspace with:"

    # Filter to only existing directories and show status
    local existing_dirs=()
    for dir in "${workspace_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo "  ✓ $(basename "$dir")"
            existing_dirs+=("$dir")
        else
            echo "  ✗ $(basename "$dir") (NOT FOUND)"
        fi
    done

    # Open with Zed
    if [[ ${#existing_dirs[@]} -gt 0 ]]; then
        echo "Opening ${#existing_dirs[@]} directories in Zed..."
        zed "${existing_dirs[@]}"
    else
        echo "No valid directories found to open"
        exit 1
    fi
}

# Simple function to build workspace using regex matching with auto-anchoring
build_workspace_dirs() {
    local projects_dir="$ZED_PROJECTS_DIR"
    local workspace_specs=("$@")
    local workspace_dirs=()

    for spec in "${workspace_specs[@]}"; do
        # Auto-anchor regex patterns (add ^ and $ if not present)
        local anchored_spec="$spec"
        if [[ ! "$anchored_spec" =~ ^\^ ]]; then
            anchored_spec="^$anchored_spec"
        fi
        if [[ ! "$anchored_spec" =~ \$$ ]]; then
            anchored_spec="$anchored_spec$"
        fi

        # Use regex matching for all patterns
        for dir in "$projects_dir"/*; do
            if [[ -d "$dir" ]]; then
                local basename_dir=$(basename "$dir")
                if [[ "$basename_dir" =~ $anchored_spec ]]; then
                    workspace_dirs+=("$dir")
                fi
            fi
        done
    done

    echo "${workspace_dirs[@]}"
}
