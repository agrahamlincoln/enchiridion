#!/bin/bash

# Zed workspace management
# Add Zed bin directory to PATH

# Configuration: Projects directory
# Set ZED_PROJECTS_DIR environment variable to customize, defaults to ~/projects
ZED_PROJECTS_DIR="${ZED_PROJECTS_DIR:-$HOME/projects}"

ZED_BIN_DIR="$ZED_PROJECTS_DIR/enchiridion/dotfiles/zed/bin"

if [[ -d "$ZED_BIN_DIR" ]]; then
    export PATH="$ZED_BIN_DIR:$PATH"
fi

# Primary z command for Zed workspace management
z() {
    local cmd="$1"

    case "$cmd" in
        "ls"|"list")
            echo "Available Zed workspaces:"
            for script in "$ZED_PROJECTS_DIR/enchiridion/dotfiles/zed/bin"/zed-*-workspace; do
                if [[ -f "$script" ]]; then
                    local workspace_name=$(basename "$script" | sed "s/zed-\(.*\)-workspace/\1/")
                    echo "  $workspace_name"
                fi
            done
            ;;
        "create")
            shift
            create-zed-workspace "$@"
            ;;
        "")
            echo "Usage: z <workspace-name> | z ls | z create <name> <projects...>"
            echo ""
            echo "Examples:"
            echo "  z actions               # Launch actions workspace"
            echo "  z release              # Launch release workspace"
            echo "  z ls                   # List all workspaces"
            echo "  z create frontend app1 app2  # Create new workspace"
            ;;
        *)
            # Launch workspace by name
            local workspace_script="$ZED_PROJECTS_DIR/enchiridion/dotfiles/zed/bin/zed-$cmd-workspace"
            if [[ -f "$workspace_script" ]]; then
                "$workspace_script"
            else
                echo "Workspace '$cmd' not found."
                echo "Available workspaces:"
                z ls
            fi
            ;;
    esac
}

# Note: If you use the z directory navigation tool and want to avoid conflicts,
# you can use zw (zed workspace) instead by uncommenting the line below:
# alias zw=z


# Fast cached completion for z command
# Global cache variables
_Z_PROJECTS_CACHE=""
_Z_PROJECTS_CACHE_TIME=0
_Z_WORKSPACES_CACHE=""
_Z_WORKSPACES_CACHE_TIME=0

# Fast function to get cached project list
_z_get_projects() {
    local projects_dir="$ZED_PROJECTS_DIR"
    local current_time=$(date +%s)
    local cache_duration=300  # 5 minutes

    # Check if cache is still valid (and exists)
    if [[ -n "$_Z_PROJECTS_CACHE" ]] && (( current_time - _Z_PROJECTS_CACHE_TIME < cache_duration )); then
        echo "$_Z_PROJECTS_CACHE"
        return
    fi

    # Rebuild cache using fast glob expansion
    local projects=""
    local count=0
    for dir in "$projects_dir"/*; do
        if [[ -d "$dir" ]]; then
            local basename_dir="${dir##*/}"  # Fast basename using parameter expansion
            if [[ "$basename_dir" != "enchiridion" ]]; then
                projects="$projects $basename_dir"
                ((count++))
            fi
        fi
    done

    # Update cache
    _Z_PROJECTS_CACHE="$projects"
    _Z_PROJECTS_CACHE_TIME=$current_time

    echo "$projects"
}

# Fast function to get cached workspace list
_z_get_workspaces() {
    local current_time=$(date +%s)
    local cache_duration=300  # 5 minutes

    # Check if cache is still valid
    if [[ -n "$_Z_WORKSPACES_CACHE" ]] && (( current_time - _Z_WORKSPACES_CACHE_TIME < cache_duration )); then
        echo "$_Z_WORKSPACES_CACHE"
        return
    fi

    # Rebuild workspace cache
    local workspaces=""
    for script in "$ZED_PROJECTS_DIR/enchiridion/dotfiles/zed/bin"/zed-*-workspace; do
        if [[ -f "$script" ]]; then
            local name="${script##*/}"  # Fast basename
            name="${name#zed-}"         # Remove zed- prefix
            name="${name%-workspace}"   # Remove -workspace suffix
            workspaces="$workspaces $name"
        fi
    done

    # Update cache
    _Z_WORKSPACES_CACHE="$workspaces"
    _Z_WORKSPACES_CACHE_TIME=$current_time

    echo "$workspaces"
}

# Optimized completion function
_z_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case $COMP_CWORD in
        1)
            # First argument - use cached workspace names
            local workspaces=$(_z_get_workspaces)
            local commands="ls list create"
            COMPREPLY=( $(compgen -W "$workspaces $commands" -- "$cur") )
            ;;
        *)
            # Additional arguments for create - use cached project list
            if [[ "${COMP_WORDS[1]}" == "create" ]]; then
                local projects=$(_z_get_projects)
                COMPREPLY=( $(compgen -W "$projects" -- "$cur") )
            fi
            ;;
    esac
}
# Register completion
complete -F _z_completion z
