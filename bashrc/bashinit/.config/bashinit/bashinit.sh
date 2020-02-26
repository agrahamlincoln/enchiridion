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
alias kclr="ssh-keygen -R"

# Systemd Helpers
alias scs="systemctl status"
alias scf="systemctl --failed"

# Arch Linux Package Management
alias pacman-orphans="sudo pacman -Rns $(pacman -Qtdq)"
alias pacman-update="sudo pacman -Syu"
alias asd="auracle sync | cut -d' ' -f1 | xargs auracle download"
