# Zed Workspaces

This directory contains scripts for managing Zed workspaces with multiple projects.

## Configuration

You can customize the location of your projects directory by setting the `ZED_PROJECTS_DIR` environment variable:

```bash
# In your .bashrc, .zshrc, or other shell configuration file:
export ZED_PROJECTS_DIR="/path/to/your/projects"
```

If not set, it defaults to `$HOME/projects`.

## Primary Interface: `z` Command

The main way to interact with Zed workspaces is through the `z` command:

```bash
z <workspace-name>        # Launch a workspace
z ls                      # List all workspaces
z create <name> <specs>   # Create new workspace
```

### Examples

```bash
# Launch workspaces
z actions                 # Open all action-* repositories
z release                 # Open release automation workspace

# List available workspaces
z ls

# Create new workspaces
z create frontend "my-app" ".*-frontend" "shared-ui"
z create backend "api-.*" "database-.*" "shared-lib"

# Get help
z                         # Shows usage
```

## Architecture

The system uses pure bash with regex pattern matching:
- `zed-workspace-common.sh` - Shared functions using bash =~ operator
- Individual workspace scripts - Define regex patterns for project matching
- `create-zed-workspace` - Generates new workspace scripts
- `z` function - Primary user interface

## Pattern Matching

All workspace specifications are treated as regex patterns with auto-anchoring:

```bash
WORKSPACE_SPECS=(
    "web-app-template"      # Exact match (becomes ^web-app-template$)
    "action-.*"             # All action-* projects
    "action-(argo|helm)-.*" # Complex regex patterns
    ".*-frontend"           # All *-frontend projects
)
```

## Available Commands

### Primary Interface
- `z <name>` - Launch workspace by name
- `z ls` - List all available workspaces
- `z create <name> <patterns...>` - Create new workspace

## Z Command Conflicts

If you use the `z` directory navigation tool, you can avoid conflicts by:
1. Using `zw` alias: `alias zw=z` (for zed workspaces)
2. Or using the full command names: `zed-actions-workspace`, etc.

## Design Principles & Considerations

When building this Zed workspace management system, we focused on:

- **Simplicity:** Everything is implemented in pure Bash, using native features like the `=~` regex operator—no external dependencies required.
- **Unified Matching:** All workspace specifications are treated as regular expressions, with automatic anchoring (`^...$`). Simple strings work as exact matches, while complex patterns are fully supported.
- **Performance:** Caching and efficient Bash built-ins ensure fast operation, even with large numbers of projects.
- **Configurability:** The projects directory is customizable via the `ZED_PROJECTS_DIR` environment variable, but defaults to `~/projects` for convenience.
- **Discoverability:** The system includes Bash autocompletion for workspace names, commands, and project directories, making it easy to use and explore available options.
- **Extensibility:** Adding, removing, or updating workspaces is as simple as editing a Bash array or running a single command.
