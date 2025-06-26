#!/bin/bash

# Script to safely cleanup stale git branches
# This script identifies and optionally removes branches that are likely safe to delete
# Enhanced to check GitHub for rebase-merged PRs
#
# Usage:
#   ./cleanup-stale-branches.sh                    # Interactive mode
#   ./cleanup-stale-branches.sh --analyze-only     # Non-interactive analysis only
#   ./cleanup-stale-branches.sh --auto-safe        # Auto-delete only safest branches (git-merged)
#   ./cleanup-stale-branches.sh --auto-recommended # Auto-delete git-merged + GitHub PR-merged

set -e

# Parse command line arguments
INTERACTIVE_MODE=true
AUTO_DELETE_MODE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --analyze-only)
            INTERACTIVE_MODE=false
            shift
            ;;
        --auto-safe)
            INTERACTIVE_MODE=false
            AUTO_DELETE_MODE="safe"
            shift
            ;;
        --auto-recommended)
            INTERACTIVE_MODE=false
            AUTO_DELETE_MODE="recommended"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--analyze-only|--auto-safe|--auto-recommended]"
            exit 1
            ;;
    esac
done

REPO_DIR="/Users/graham.rounds/projects/deploymentScripts"
cd "$REPO_DIR"

# Function to check if GitHub CLI is available and authenticated
check_github_cli() {
    if ! command -v gh &> /dev/null; then
        echo "⚠️  GitHub CLI (gh) not found. Install with: brew install gh"
        echo "   GitHub PR checking will be disabled."
        return 1
    fi

    if ! gh auth status &> /dev/null; then
        echo "⚠️  GitHub CLI not authenticated. Run: gh auth login"
        echo "   GitHub PR checking will be disabled."
        return 1
    fi

    return 0
}

# Function to check if a branch was merged via GitHub PR
check_github_pr_merged() {
    local branch_name="$1"

    # Query GitHub for PRs with this branch as head
    # Look for closed PRs that were merged (not just closed)
    # This will catch rebase-and-merge, squash-and-merge, and regular merge
    local pr_info=$(gh pr list --state merged --head "$branch_name" --json number,title,mergedAt,baseRefName,mergeable --limit 1 2>/dev/null)

    if [ -n "$pr_info" ] && [ "$pr_info" != "[]" ]; then
        echo "$pr_info" | jq -r '.[] | select(.mergedAt != null) | .number' 2>/dev/null || echo ""
    else
        # Also check for closed PRs that might have been rebase-merged
        # (sometimes rebase-merged PRs don't show up in --state merged)
        local closed_pr_info=$(gh pr list --state closed --head "$branch_name" --json number,title,closedAt,baseRefName,merged --limit 1 2>/dev/null)
        if [ -n "$closed_pr_info" ] && [ "$closed_pr_info" != "[]" ]; then
            echo "$closed_pr_info" | jq -r '.[] | select(.merged == true) | .number' 2>/dev/null || echo ""
        else
            echo ""
        fi
    fi
}

# Function to get GitHub repo info
get_github_repo() {
    git remote get-url origin 2>/dev/null | \
        sed -E 's/.*github\.com[:/]([^/]+\/[^/]+)(\.git)?$/\1/' | \
        sed 's/\.git$//' 2>/dev/null || echo ""
}

echo "🔍 Git Branch Cleanup Analysis"
echo "================================"
echo

# Check GitHub CLI availability
github_available=false
if check_github_cli; then
    github_available=true
    repo_name=$(get_github_repo)
    echo "✅ GitHub CLI available - will check for rebase-merged PRs"
    echo "📦 Repository: $repo_name"
else
    echo "❌ GitHub CLI not available - will only check git-merged branches"
fi
echo

# Get current branch
current_branch=$(git branch --show-current)
echo "Current branch: $current_branch"
echo

# 1. Show branches already merged into master (safest to delete)
echo "📋 Branches already merged into master (SAFE TO DELETE):"
echo "--------------------------------------------------------"
merged_branches=$(git branch --merged master | grep -v "^\*\|master\|staging" | sed 's/^[[:space:]]*//')
if [ -n "$merged_branches" ]; then
    echo "$merged_branches"
    merged_count=$(echo "$merged_branches" | wc -l | tr -d ' ')
    echo "Count: $merged_count branches"
else
    echo "No merged branches found"
    merged_count=0
fi
echo

# 1.5. Check GitHub for rebase-merged PRs (if GitHub CLI available)
github_merged_branches=""
github_merged_count=0
if [ "$github_available" = true ]; then
    echo "🔄 Checking GitHub for rebase-merged PRs..."
    echo "-------------------------------------------"

    # Get all local branches except master/staging
    all_branches=$(git branch --format='%(refname:short)' | grep -v "^\(master\|staging\)$" | grep -v "^$")

    # Check each branch for merged PRs
    temp_github_merged=""
    checked_count=0
    total_branches_to_check=$(echo "$all_branches" | wc -l | tr -d ' ')

    while IFS= read -r branch; do
        if [ -n "$branch" ] && [ "$branch" != "" ]; then
            ((checked_count++))
            echo -n "  Checking $branch ($checked_count/$total_branches_to_check)... "

            pr_number=$(check_github_pr_merged "$branch")
            if [ -n "$pr_number" ] && [ "$pr_number" != "" ]; then
                echo "✅ PR #$pr_number (merged)"
                temp_github_merged="$temp_github_merged$branch"$'\n'
                ((github_merged_count++))
            else
                echo "❌ No merged PR found"
            fi
        fi
    done <<< "$all_branches"

    if [ $github_merged_count -gt 0 ]; then
        github_merged_branches=$(echo "$temp_github_merged" | grep -v '^$' || true)
        echo ""
        echo "📋 Branches with merged PRs (SAFE TO DELETE):"
        echo "$github_merged_branches"
        echo "Count: $github_merged_count branches"
    else
        echo ""
        echo "No branches with merged PRs found"
    fi
    echo
fi

# 2. Show very old branches (2023 and earlier)
echo "📅 Very old branches (2023 and earlier - LIKELY SAFE TO DELETE):"
echo "----------------------------------------------------------------"
old_branches_2023=$(git for-each-ref --format='%(committerdate:short)|%(refname:short)' refs/heads/ | grep "^202[0-3]" | grep -v "master\|staging")
if [ -n "$old_branches_2023" ]; then
    echo "$old_branches_2023" | while IFS='|' read -r date branch; do
        echo "$date  $branch"
    done
    old_2023_count=$(echo "$old_branches_2023" | wc -l | tr -d ' ')
    echo "Count: $old_2023_count branches"
else
    echo "No branches from 2023 or earlier found"
    old_2023_count=0
fi
echo

# 3. Show branches from early 2024 (also quite old)
echo "📅 Early 2024 branches (Jan-May, over 1 year old - PROBABLY SAFE TO DELETE):"
echo "----------------------------------------------------------------------------"
old_branches_early_2024=$(git for-each-ref --format='%(committerdate:short)|%(refname:short)' refs/heads/ | grep "^2024-0[1-5]" | grep -v "master\|staging")
if [ -n "$old_branches_early_2024" ]; then
    echo "$old_branches_early_2024" | while IFS='|' read -r date branch; do
        echo "$date  $branch"
    done
    early_2024_count=$(echo "$old_branches_early_2024" | wc -l | tr -d ' ')
    echo "Count: $early_2024_count branches"
else
    echo "No early 2024 branches found"
    early_2024_count=0
fi
echo

# Calculate unique stale branches (avoiding double-counting)
# Create a temporary file to collect all unique stale branch names
temp_stale_file=$(mktemp)

# Add git-merged branches
if [ -n "$merged_branches" ]; then
    echo "$merged_branches" >> "$temp_stale_file"
fi

# Add GitHub PR-merged branches
if [ -n "$github_merged_branches" ]; then
    echo "$github_merged_branches" >> "$temp_stale_file"
fi

# Add 2023 branches (extract branch names from date|branch format)
if [ -n "$old_branches_2023" ]; then
    echo "$old_branches_2023" | cut -d'|' -f2 >> "$temp_stale_file"
fi

# Add early 2024 branches (extract branch names from date|branch format)
if [ -n "$old_branches_early_2024" ]; then
    echo "$old_branches_early_2024" | cut -d'|' -f2 >> "$temp_stale_file"
fi

# Count unique stale branches
if [ -s "$temp_stale_file" ]; then
    unique_stale_count=$(sort "$temp_stale_file" | uniq | wc -l | tr -d ' ')
else
    unique_stale_count=0
fi

# Clean up temp file
rm -f "$temp_stale_file"

total_branches=$(git branch --list | wc -l | tr -d ' ')

echo "📊 SUMMARY:"
echo "----------"
echo "Total branches: $total_branches"
echo "Git-merged branches: $merged_count"
if [ "$github_available" = true ]; then
    echo "GitHub PR-merged branches: $github_merged_count"
fi
echo "Old branches (2023): $old_2023_count"
echo "Early 2024 branches: $early_2024_count"
echo "Unique stale branches: $unique_stale_count"
echo "Percentage stale: $(( (unique_stale_count * 100) / total_branches ))%"
echo

# Offer to delete options
if [ "$INTERACTIVE_MODE" = true ]; then
    echo "🗑️  CLEANUP OPTIONS:"
    echo "-------------------"
    echo "1. Delete only git-merged branches (safest)"
    if [ "$github_available" = true ] && [ $github_merged_count -gt 0 ]; then
        echo "2. Delete git-merged + GitHub PR-merged branches (recommended)"
        echo "3. Delete merged + GitHub + 2023 branches (aggressive)"
        echo "4. Delete merged + GitHub + 2023 + early 2024 branches (very aggressive)"
        echo "5. Show detailed analysis only (no deletion)"
        echo "6. Exit without changes"
    else
        echo "2. Delete merged + 2023 branches (recommended)"
        echo "3. Delete merged + 2023 + early 2024 branches (aggressive)"
        echo "4. Show detailed analysis only (no deletion)"
        echo "5. Exit without changes"
    fi
    echo

    if [ "$github_available" = true ] && [ $github_merged_count -gt 0 ]; then
        read -p "Choose an option (1-6): " choice
    else
        read -p "Choose an option (1-5): " choice
    fi
else
    # Non-interactive mode
    case "$AUTO_DELETE_MODE" in
        "safe")
            choice=1
            echo "🤖 Auto-mode: Deleting only git-merged branches (safest)"
            ;;
        "recommended")
            if [ "$github_available" = true ] && [ $github_merged_count -gt 0 ]; then
                choice=2
                echo "🤖 Auto-mode: Deleting git-merged + GitHub PR-merged branches"
            else
                choice=1
                echo "🤖 Auto-mode: GitHub not available, deleting only git-merged branches"
            fi
            ;;
        *)
            echo "📊 Analysis complete. Use --auto-safe or --auto-recommended to delete branches."
            exit 0
            ;;
    esac
fi

case $choice in
    1)
        echo "Deleting git-merged branches..."
        if [ -n "$merged_branches" ]; then
            echo "$merged_branches" | xargs -n1 git branch -d
            echo "✅ Deleted $merged_count git-merged branches"
        else
            echo "No git-merged branches to delete"
        fi
        ;;
    2)
        if [ "$github_available" = true ] && [ $github_merged_count -gt 0 ]; then
            echo "Deleting git-merged + GitHub PR-merged branches..."
            # Delete git-merged branches
            if [ -n "$merged_branches" ]; then
                echo "$merged_branches" | xargs -n1 git branch -d
            fi
            # Delete GitHub PR-merged branches
            if [ -n "$github_merged_branches" ]; then
                echo "$github_merged_branches" | xargs -n1 git branch -D
            fi
            echo "✅ Deleted $((merged_count + github_merged_count)) branches"
        else
            echo "Deleting merged branches and 2023 branches..."
            # Delete merged branches
            if [ -n "$merged_branches" ]; then
                echo "$merged_branches" | xargs -n1 git branch -d
            fi
            # Delete 2023 branches
            if [ -n "$old_branches_2023" ]; then
                echo "$old_branches_2023" | cut -d'|' -f2 | xargs -n1 git branch -D
            fi
            echo "✅ Deleted $((merged_count + old_2023_count)) branches"
        fi
        ;;
    3)
        if [ "$github_available" = true ] && [ $github_merged_count -gt 0 ]; then
            echo "Deleting merged, GitHub, and 2023 branches..."
            # Delete git-merged branches
            if [ -n "$merged_branches" ]; then
                echo "$merged_branches" | xargs -n1 git branch -d
            fi
            # Delete GitHub PR-merged branches
            if [ -n "$github_merged_branches" ]; then
                echo "$github_merged_branches" | xargs -n1 git branch -D
            fi
            # Delete 2023 branches
            if [ -n "$old_branches_2023" ]; then
                echo "$old_branches_2023" | cut -d'|' -f2 | xargs -n1 git branch -D
            fi
            echo "✅ Deleted $((merged_count + github_merged_count + old_2023_count)) branches"
        else
            echo "Deleting merged, 2023, and early 2024 branches..."
            # Delete merged branches
            if [ -n "$merged_branches" ]; then
                echo "$merged_branches" | xargs -n1 git branch -d
            fi
            # Delete 2023 branches
            if [ -n "$old_branches_2023" ]; then
                echo "$old_branches_2023" | cut -d'|' -f2 | xargs -n1 git branch -D
            fi
            # Delete early 2024 branches
            if [ -n "$old_branches_early_2024" ]; then
                echo "$old_branches_early_2024" | cut -d'|' -f2 | xargs -n1 git branch -D
            fi
            echo "✅ Deleted $total_stale branches"
        fi
        ;;
    4)
        if [ "$github_available" = true ] && [ $github_merged_count -gt 0 ]; then
            echo "Deleting merged, GitHub, 2023, and early 2024 branches..."
            # Delete git-merged branches
            if [ -n "$merged_branches" ]; then
                echo "$merged_branches" | xargs -n1 git branch -d
            fi
            # Delete GitHub PR-merged branches
            if [ -n "$github_merged_branches" ]; then
                echo "$github_merged_branches" | xargs -n1 git branch -D
            fi
            # Delete 2023 branches
            if [ -n "$old_branches_2023" ]; then
                echo "$old_branches_2023" | cut -d'|' -f2 | xargs -n1 git branch -D
            fi
            # Delete early 2024 branches
            if [ -n "$old_branches_early_2024" ]; then
                echo "$old_branches_early_2024" | cut -d'|' -f2 | xargs -n1 git branch -D
            fi
            echo "✅ Deleted $total_stale branches"
        else
            echo "Detailed analysis completed. No branches deleted."
        fi
        ;;
    5)
        if [ "$github_available" = true ] && [ $github_merged_count -gt 0 ]; then
            echo "Detailed analysis completed. No branches deleted."
        else
            echo "Exiting without changes."
            exit 0
        fi
        ;;
    6)
        if [ "$github_available" = true ] && [ $github_merged_count -gt 0 ]; then
            echo "Exiting without changes."
            exit 0
        else
            echo "Invalid option. Exiting."
            exit 1
        fi
        ;;
    *)
        echo "Invalid option. Exiting."
        exit 1
        ;;
esac

echo
echo "🏁 Final branch count:"
final_count=$(git branch --list | wc -l | tr -d ' ')
echo "Branches remaining: $final_count"
echo "Branches cleaned up: $((total_branches - final_count))"
