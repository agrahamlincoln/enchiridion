# Configure Bash Prompt

# Color bash prompt that displays the last 40 characters of the current
# working directory.
# From https://wiki.archlinux.org/index.php/Color_Bash_Prompt

##################################################
# Fancy PWD display function
##################################################
# The home directory (HOME) is replaced with a ~
# The last pwdmaxlen characters of the PWD are displayed
# Leading partial directory names are striped off
# /home/me/stuff          -> ~/stuff               if USER=me
# /usr/share/big_dir_name -> ../share/big_dir_name if pwdmaxlen=20
##################################################
fancy_pwd() {
    # How many characters of the $PWD should be kept
    local pwdmaxlen=40
    # Indicate that there has been dir truncation
    local trunc_symbol=".."
    local dir=${PWD##*/}
    pwdmaxlen=$(( ( pwdmaxlen < ${#dir} ) ? ${#dir} : pwdmaxlen ))
    NEW_PWD=${PWD/#$HOME/\~}
    local pwdoffset=$(( ${#NEW_PWD} - pwdmaxlen ))
    if [ ${pwdoffset} -gt "0" ]
    then
        NEW_PWD=${NEW_PWD:$pwdoffset:$pwdmaxlen}
        NEW_PWD=${trunc_symbol}/${NEW_PWD#*/}
    fi
}
git_info() {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return
    local indicators=""
    # Unstaged changes
    git diff --quiet 2>/dev/null || indicators+="*"
    # Staged changes
    git diff --cached --quiet 2>/dev/null || indicators+="+"
    echo "${branch}${indicators}"
}
available_package_upgrades () {
    # Check if the file exists and is readable
    if [[ -r "/var/lib/available-upgrades/.package-available-upgrades" ]]; then
        # Count the number of lines in the file. Each line indicates an available upgrade.
        NUM_UPGRADES=$(wc -l </var/lib/available-upgrades/.package-available-upgrades)

        # If the count is zero, report an empty string; otherwise, report the count.
        if [[ $NUM_UPGRADES -eq 0 ]]; then
            echo ""
        else
            echo "[${NUM_UPGRADES}pkgs] "
        fi
    fi
}
prompt_command() {
    local exit_code=$?
    fancy_pwd
    # Color the prompt symbol red on non-zero exit, gray otherwise
    if [ $exit_code -ne 0 ]; then
        PROMPT_SYMBOL_COLOR=$'\033[0;31m'
    else
        PROMPT_SYMBOL_COLOR=$'\033[0;37m'
    fi
}
set_ps1() {
    local CEND="\[\033[0m\]"    # unsets color to term's fg color

    # ANSI color codes (mapped to kitty's themed palette)
    local GREEN="\[\033[0;32m\]"    # color2: green
    local YELLOW="\[\033[0;33m\]"   # color3: yellow
    local BLUE="\[\033[0;34m\]"     # color4: blue
    local GRAY="\[\033[0;37m\]"     # color7: white/gray
    local CYAN="\[\033[0;36m\]"     # color6: cyan

    # PS1 Formatting
    local TIME="$GRAY\t$CEND "
    local USER="$GREEN\u$GRAY"
    local HOST="$BLUE\h$CEND"
    local LOCATION="$CYAN[\${NEW_PWD}]$CEND "
    local BRANCH="$YELLOW\$(git_info)$CEND"
    local PKGUPGR="$GRAY\$(available_package_upgrades)$CEND"
    local PROMPT="\n\[\${PROMPT_SYMBOL_COLOR}\]\$$CEND "

    # Set PS1
    PS1=$TIME$PKGUPGR$USER@$HOST$LOCATION$BRANCH$PROMPT
    PS2='\[\033[01;36m\]>'
}
# Run prompt_command on every prompt to update pwd and exit code state
PROMPT_COMMAND=prompt_command
# Set PS1 and unset the function so it can't be used again
set_ps1
unset set_ps1
