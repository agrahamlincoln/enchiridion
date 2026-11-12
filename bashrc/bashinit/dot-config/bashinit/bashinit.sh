#!/bin/bash

## Scripts
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# set_ps1 formats the prompt
source $DIR/bash-prompt.sh
source $DIR/bash-history.sh
source $DIR/ssh-agent.sh
# Aliases.
alias ..="cd .."
alias cpp="rsync --info=progress2 $1 $2"
alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
# ls -l and show numeric unix permissions (i.e. 600)
alias lsn="ls -l | awk '{k=0;for(i=0;i<=8;i++)k+=((substr(\$1,i+2,1)~/[rwx]/) *2^(8-i));if(k)printf(\"%0o \",k);print}'"

# Git.
alias gca="git commit -a"
alias gb="git branch"
alias gd="git diff"
alias gdc="git diff --cached"
alias gch="git checkout"
alias gpom="git pull origin master"
alias gp="git pull"
alias gs="git status"
alias g='gh repo view --web --branch $(git branch --show-current)'

# SSH
alias kclr="ssh-keygen -R"

# Systemd Helpers
alias scs="systemctl status"
alias scf="systemctl --failed"

# Kubernetes
alias kcc="kubectl config"
alias kc="kubectl"
alias ktx="kubectx"
alias kns="kubens"

# Print a warning from an argument or stdin (here-doc); first line gets a prefix.
warnMessage() {
    local YELLOW='\033[1;33m' NC='\033[0m' input
    if [ "$#" -gt 0 ]; then
        input="$1"
    else
        input=$(cat)
    fi

    local -a lines
    IFS=$'\n' read -d '' -ra lines <<< "$input"

    echo -e "${YELLOW}WARNING:${NC} ${lines[0]}"
    local line
    for line in "${lines[@]:1}"; do
        echo "$line"
    done
}

# OS Specific bashinit scripts
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    source $DIR/bash-linux.sh
elif [[ "$OSTYPE" == "darwin"* ]]; then
    source $DIR/bash-osx.sh
    launchctl setenv OSTYPE ${OSTYPE}
fi

# Machine-local, gitignored settings (work paths, toolchains)
[[ -r $DIR/bash-private.sh ]] && source "$DIR/bash-private.sh"
