# CLAUDE.md - General Execution Rules & Patterns

This file contains general execution rules, patterns, and operational guidelines discovered through working with the enchiridion project. These rules are applicable across different tasks and contexts.

## Code Structure & Architecture

### Global Installation Patterns
- **Wrapper Scripts**: For applications, create bash wrapper scripts in `bin/` that handle virtual environment activation and working directory management
- **Installation Targets**: Use justfile targets for `install-global` and `uninstall-global` that copy wrapper scripts to `/usr/local/bin`
- **Path Resolution**: Wrapper scripts should change to the correct working directory for proper configuration file resolution

## Development Workflow

### Justfile Organization
- **Separate Concerns**: Main justfile for system setup, sub-justfiles for specific applications
- **Global Wrappers**: Provide justfile targets that delegate to application-specific justfiles in subdirectories
- **Development vs Production**: Distinguish between development commands (setup, lint, test) and production commands (install-global)

### Todo Management
- **Use TodoWrite/TodoRead**: For complex multi-step tasks, actively use todo management to track progress
- **Mark Completion**: Mark todos as completed immediately upon finishing, don't batch completions
- **Break Down Tasks**: Complex tasks should be broken into specific, actionable items

## File Management & Organization

### Configuration Files
- **Hierarchical Search**: Look for config files in multiple locations (current dir, ~/.config, home dir)
- **Merge Defaults**: Always merge user configuration with sensible defaults
- **Environment Resolution**: Expand user paths (~) and environment variables in configuration

### Metadata & Documentation
- **Documentation Hierarchy**: README.md for users, CLAUDE.md for development rules
- **Memory Files**: Use structured memory files for complex session context preservation

## Tool Usage Optimization

### Batching & Efficiency
- **Batch Tool Calls**: When multiple independent operations are needed, use single messages with multiple tool calls
- **Parallel Operations**: Use bash tools for operations that can run in parallel (git status, git diff, etc.)
- **Avoid Redundancy**: Don't re-read files or repeat operations unless necessary

### Error Recovery
- **Incremental Testing**: Test major changes incrementally rather than implementing everything at once
- **Rollback Capability**: Maintain ability to rollback changes when refactoring working systems
- **State Preservation**: Preserve working state during major restructuring

## Code Quality Standards

### General Patterns
- **Idempotency**: Operations should be safe to run multiple times
- **Configuration Validation**: Validate configuration values and provide helpful error messages
- **Progressive Enhancement**: Build basic functionality first, then add advanced features

## Integration Patterns

### File System Operations
- **Path Validation**: Always validate paths exist before operations
- **Atomic Operations**: Use temporary files and atomic moves for important file operations
- **Backup Strategies**: Implement backup/restore for important data and configurations

---

*This file should be updated as new patterns and rules are discovered through development work.*