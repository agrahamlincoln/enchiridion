# Eternal bash history.
# ---------------------
# Undocumented feature which sets the size to "unlimited".
# http://stackoverflow.com/questions/9457233/unlimited-bash-history
export HISTFILESIZE=
export HISTSIZE=
export HISTTIMEFORMAT="[%F %T] "
# Change the file location because certain bash sessions truncate .bash_history
# file upon close.
# http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
export HISTFILE=~/.bash_eternal_history

# Force prompt to write history after every command.
# also reload the history after every command to sync if/when multiple shells
# are in use. http://superuser.com/questions/20900/bash-history-loss
# Save $? before history commands clobber it, then restore so downstream
# PROMPT_COMMAND functions (e.g. prompt_command) see the real exit code.
__restore_exit() { return "$__last_exit_code"; }
PROMPT_COMMAND='__last_exit_code=$?; history -a; history -n; __restore_exit; '"$PROMPT_COMMAND"
shopt -s histappend
stophistory () {
  PROMPT_COMMAND="bash_prompt_command"
  echo 'History recording stopped. Make sure to `kill -9 $$` at the end of the session.'
}

