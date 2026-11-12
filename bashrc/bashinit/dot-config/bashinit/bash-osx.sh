#!/usr/bin/env bash

# osx-specific bashinit scripts

[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -r /opt/homebrew/etc/profile.d/bash_completion.sh ] && . /opt/homebrew/etc/profile.d/bash_completion.sh
[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
export PATH="$HOME/.local/bin:$PATH"

[ -x /opt/homebrew/bin/aws_completer ] && complete -C /opt/homebrew/bin/aws_completer aws
command -v direnv >/dev/null && eval "$(direnv hook bash)"
command -v fnm >/dev/null && eval "$(fnm env --use-on-cd --shell bash)"

# keychain_export VAR SERVICE: export a login-keychain generic password as VAR
keychain_export() {
    local value
    value=$(security find-generic-password -s "$2" -w 2>/dev/null) && export "$1=$value"
}

# keychain_set SERVICE: prompt for a secret and store or update it in the login keychain
keychain_set() {
    security add-generic-password -U -a "$USER" -s "$1" -w
}
