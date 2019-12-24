#!/usr/bin/env bash

# Two modes
# Default (Safe Mode): will check that a process with the name is running, if it is not, start it
# Unsafe Mode: will terminate process if it is running, and start it
#
# Usage
# $0
function usage() {
    usage="Usage: $0 [--unsafe] -- <command>

Modes:
Default - start the specified program. It will not start if a process with the
          same name already is already running.
 Unsafe - terminate the process if it is running, then start it."
    echo "$usage"
    exit 1
}

function is_running() {
    PROCESS_ID=$(pgrep -u $UID -x "$1")
    echo "PID: '$PROCESS_ID'"
    if [ ! -z "$PROCESS_ID" ]; then
        return 1
    else
        return 0
    fi
}

MODE=safe
# handle options
while [ -n "$1" ]; do
    case "$1" in
    --unsafe)
        MODE=unsafe
        shift ;;
    --)
        shift
        break ;;
    *)
        break ;;
    esac
done

echo "running '$@' in $MODE mode."

echo "searching for $1"
if [ get_pid ]; then
    case "$MODE" in
    safe)
        echo "$1 is already running."
        exit 0 ;;
    unsafe)
        echo "killing $1"
        killall -q "$1"
        # wait until processes are exited
        while pgrep -u $UID -x "$1" >/dev/null; do sleep 1; done
        echo "running: $@ &"
        $@ &
        exit 0 ;;
    *)
        echo "Error: Mode is unset."
        exit 2 ;;
    esac
else
    echo "running: $@ &"
    $@ &
    exit 0
fi
