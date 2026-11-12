#!/usr/bin/env bash
# Idempotent macOS preferences that match the Enchiridion desktop.
# Only writes values that differ; restarts Dock/Finder when their settings change.
# Run with DRY_RUN=1 to list pending changes without applying them.

set -euo pipefail

[[ "$(uname)" == "Darwin" ]] || { echo "macOS only." >&2; exit 1; }

DRY_RUN="${DRY_RUN:-0}"
RESTART_DOCK=0
RESTART_FINDER=0

# set_default <domain> <key> <bool|int|string> <value>
set_default() {
    local domain=$1 key=$2 type=$3 value=$4 want=$4 current
    if [[ $type == bool ]]; then
        [[ $value == true ]] && want=1 || want=0
    fi
    current=$(defaults read "$domain" "$key" 2>/dev/null || true)
    if [[ $type == bool ]]; then
        [[ $current == true ]] && current=1
        [[ $current == false ]] && current=0
    fi
    [[ "$current" == "$want" ]] && return 0

    echo "  $domain $key: ${current:-<unset>} -> $want"
    [[ "$DRY_RUN" == 1 ]] && return 0
    defaults write "$domain" "$key" "-$type" "$value"
    case "$domain" in
        com.apple.dock) RESTART_DOCK=1 ;;
        com.apple.finder) RESTART_FINDER=1 ;;
    esac
}

echo "-> Applying macOS defaults..."

# Appearance
set_default NSGlobalDomain AppleInterfaceStyle string Dark
set_default NSGlobalDomain _HIHideMenuBar bool true            # sketchybar replaces the menu bar

# Typing
set_default NSGlobalDomain NSAutomaticSpellingCorrectionEnabled bool false

# Windows
set_default NSGlobalDomain AppleMiniaturizeOnDoubleClick bool false
set_default com.apple.WindowManager EnableStandardClickToShowDesktop bool false

# Dock (yabai needs mru-spaces off and Mission Control windows ungrouped)
set_default com.apple.dock autohide bool true
set_default com.apple.dock orientation string left
set_default com.apple.dock tilesize int 53
set_default com.apple.dock magnification bool false
set_default com.apple.dock mru-spaces bool false
set_default com.apple.dock expose-group-apps bool false

# Finder
set_default com.apple.finder AppleShowAllFiles bool true
set_default com.apple.finder FXPreferredViewStyle string Nlsv   # list view

# Spotlight's Cmd+Space shortcut is disabled so Alfred can own it.
SPOTLIGHT_ENABLED=$(/usr/libexec/PlistBuddy -c 'Print :AppleSymbolicHotKeys:64:enabled' \
    "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist" 2>/dev/null || echo true)
if [[ "$SPOTLIGHT_ENABLED" != false ]]; then
    echo "  Spotlight Cmd+Space shortcut: enabled -> disabled"
    if [[ "$DRY_RUN" != 1 ]]; then
        defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
            '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
        /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    fi
fi

if [[ "$DRY_RUN" != 1 ]]; then
    [[ $RESTART_DOCK == 1 ]] && killall Dock
    [[ $RESTART_FINDER == 1 ]] && killall Finder
fi

if [[ "$DRY_RUN" == 1 ]]; then
    echo "- Dry run: nothing changed."
else
    echo "- macOS defaults applied. Log out and back in for menu bar and appearance changes."
fi
echo "  Not scriptable: set 'Displays have separate Spaces' on (the default) for yabai."
