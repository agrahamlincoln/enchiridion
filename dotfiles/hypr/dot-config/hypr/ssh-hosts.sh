#!/bin/bash
# SSH host picker for wayle custom dropdown.
#
# Reads hosts from the home-lab Ansible inventory and outputs them
# as JSON lines for the wayle picker protocol.
#
# Usage:
#   ssh-hosts.sh list          # JSON lines for picker dropdown
#   ssh-hosts.sh connect       # Open kitty SSH session ($WAYLE_SELECTED = host)

set -euo pipefail

INVENTORY="$HOME/projects/home-lab/ansible/inventory.yaml"
SSH_USER="agraham"

cmd=${1:-list}

case "$cmd" in
    list)
        if [[ ! -f "$INVENTORY" ]]; then
            echo '{"label": "Inventory not found", "value": ""}'
            exit 0
        fi

        python3 -c "
import yaml, json, sys

with open('$INVENTORY') as f:
    inv = yaml.safe_load(f)

for group_name, group in inv.get('all', {}).get('children', {}).items():
    for host_name, host_vars in group.get('hosts', {}).items():
        ip = host_vars.get('ansible_host', 'unknown') if host_vars else 'unknown'
        print(json.dumps({
            'value': host_name,
            'label': host_name,
            'subtitle': f'{ip}  ({group_name})',
            'active': False,
        }))
"
        ;;

    connect)
        host="${WAYLE_SELECTED:?No host selected}"
        [[ -z "$host" ]] && exit 0
        kitty --title "SSH: $host" -- ssh "${SSH_USER}@${host}" &
        disown
        ;;

    *)
        echo "Usage: ssh-hosts.sh {list|connect}" >&2
        exit 1
        ;;
esac
