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
current_git_branch () { git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'; }
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
set_ps1() {
    local CEND="\[\033[0m\]"    # unsets color to term's fg color

    # Color Codes
    local GREEN="\[\033[0;32m\]"    # green
    local YELLOW="\[\033[0;33m\]"    # yellow
    local BLUE="\[\033[0;34m\]"    # blue
    local GRAY="\[\033[38;05;250m\]" # gray
    local PURPLE="\[\033[38;05;099m\]" # purple

    # PS1 Formatting
    local TIME="$GRAY\t$CEND "
    local USER="$GREEN\u$GRAY"
    local HOST="$BLUE\h$CEND"
    local LOCATION="$PURPLE[\${NEW_PWD}]$CEND "
    local BRANCH="$YELLOW\$(current_git_branch)$CEND"
    local PKGUPGR="$GRAY\$(available_package_upgrades)$CEND"
    local PROMPT="$GRAY\n\$$CEND "

    # Set PS1
    PS1=$TIME$PKGUPGR$USER@$HOST$LOCATION$BRANCH$PROMPT
    PS2='\[\033[01;36m\]>'
}
# Run fancy_pwd on every command to re-evaluate current dir
PROMPT_COMMAND=fancy_pwd
# Set PS1 and unset the function so it can't be used again
set_ps1
unset set_ps1
