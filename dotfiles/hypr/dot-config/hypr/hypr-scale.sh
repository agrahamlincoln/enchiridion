#!/bin/bash
# Compute and apply valid Hyprland monitor scales.
#
# Valid scales must satisfy two constraints:
#   1. width/scale and height/scale are both integers (clean pixel alignment)
#   2. Scale is representable by the Wayland fractional-scale-v1 protocol (n/120)
# Combined: valid_scale = gcd(W,H) / k, where k divides 120*gcd(W,H).
#
# Scales are cached per-resolution in ~/.cache/hypr-scales/ since valid scales
# only depend on the panel's resolution (which doesn't change).
#
# Usage:
#   hypr-scale.sh list              # List all valid scales for the focused monitor
#   hypr-scale.sh get               # Print current scale as JSON (for waybar)
#   hypr-scale.sh set <scale>       # Apply a specific scale
#   hypr-scale.sh up                # Switch to the next higher scale (smaller UI)
#   hypr-scale.sh down              # Switch to the next lower scale (larger UI)
#   hypr-scale.sh auto [target_dpi] # Apply the closest valid scale to target DPI (default: 140)

set -euo pipefail

CACHE_DIR="$HOME/.cache/hypr-scales"
SCALE_FILE="$HOME/.config/hypr/monitor-scale"

gcd() {
    local a=$1 b=$2
    while [[ $b -ne 0 ]]; do
        local t=$b
        b=$((a % b))
        a=$t
    done
    echo "$a"
}

# Get focused monitor info
get_monitor() {
    hyprctl monitors -j | jq -c '[.[] | select(.focused == true)][0]'
}

# Get or compute cached valid scales for a resolution.
# Cache file contains one "scale ew eh" per line, sorted ascending by scale.
get_valid_scales() {
    local width=$1 height=$2
    mkdir -p "$CACHE_DIR"
    local cache_file="$CACHE_DIR/${width}x${height}"

    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
        return
    fi

    local g
    g=$(gcd "$width" "$height")
    local product=$((120 * g))
    local min_k=$(( g / 3 ))
    [[ $min_k -lt 1 ]] && min_k=1

    local k
    for k in $(seq "$min_k" "$g"); do
        if (( product % k == 0 )); then
            awk "BEGIN {
                s = $g / $k
                if (s >= 1.0 && s <= 3.0) {
                    printf \"%.4f %d %d\n\", s, $width / s, $height / s
                }
            }"
        fi
    done | sort -n | tee "$cache_file"
}

cmd=${1:-get}

case "$cmd" in
    list)
        mon=$(get_monitor)
        width=$(echo "$mon" | jq '.width')
        height=$(echo "$mon" | jq '.height')
        phys_mm=$(echo "$mon" | jq '.physicalWidth')
        current=$(echo "$mon" | jq '.scale')
        native_dpi=$(awk "BEGIN { printf \"%.1f\", $width / ($phys_mm / 25.4) }")

        printf "%-8s %-12s %-8s %s\n" "Scale" "Effective" "Eff DPI" ""
        while read -r scale ew eh; do
            eff_dpi=$(awk "BEGIN { printf \"%.0f\", $native_dpi / $scale }")
            marker=""
            if awk "BEGIN { exit !(($scale - $current) < 0.01 && ($current - $scale) < 0.01) }"; then
                marker="<-- current"
            fi
            printf "%-8s %-12s %-8s %s\n" "$scale" "${ew}x${eh}" "$eff_dpi" "$marker"
        done < <(get_valid_scales "$width" "$height")
        ;;

    get)
        mon=$(get_monitor)
        width=$(echo "$mon" | jq '.width')
        height=$(echo "$mon" | jq '.height')
        phys_mm=$(echo "$mon" | jq '.physicalWidth')
        current=$(echo "$mon" | jq '.scale')
        native_dpi=$(awk "BEGIN { printf \"%.0f\", $width / ($phys_mm / 25.4) }")
        eff_dpi=$(awk "BEGIN { printf \"%.0f\", $native_dpi / $current }")
        ew=$(awk "BEGIN { printf \"%.0f\", $width / $current }")
        eh=$(awk "BEGIN { printf \"%.0f\", $height / $current }")

        tooltip="Scale: ${current}x | ${eff_dpi} DPI | ${ew}x${eh}\\nScroll to adjust"
        echo "{\"text\": \"${eff_dpi}\", \"tooltip\": \"${tooltip}\", \"class\": \"scale\"}"
        ;;

    set)
        scale=${2:?Usage: hypr-scale.sh set <scale>}
        mon=$(get_monitor)
        name=$(echo "$mon" | jq -r '.name')
        hyprctl keyword monitor "$name,preferred,auto,$scale" >/dev/null 2>&1
        echo "$scale" > "$SCALE_FILE"
        ;;

    up|down)
        mon=$(get_monitor)
        width=$(echo "$mon" | jq '.width')
        height=$(echo "$mon" | jq '.height')
        current=$(echo "$mon" | jq '.scale')
        name=$(echo "$mon" | jq -r '.name')

        scales=()
        while read -r scale _ _; do
            scales+=("$scale")
        done < <(get_valid_scales "$width" "$height")

        # Find current index
        current_idx=-1
        for i in "${!scales[@]}"; do
            if awk "BEGIN { exit !((${scales[$i]} - $current) < 0.01 && ($current - ${scales[$i]}) < 0.01) }"; then
                current_idx=$i
                break
            fi
        done

        if [[ "$cmd" == "up" ]]; then
            next_idx=$((current_idx + 1))
            [[ $next_idx -ge ${#scales[@]} ]] && exit 0
        else
            next_idx=$((current_idx - 1))
            [[ $next_idx -lt 0 ]] && exit 0
        fi

        hyprctl keyword monitor "$name,preferred,auto,${scales[$next_idx]}" >/dev/null 2>&1
        echo "${scales[$next_idx]}" > "$SCALE_FILE"
        ;;

    auto)
        target_dpi=${2:-140}
        mon=$(get_monitor)
        name=$(echo "$mon" | jq -r '.name')
        width=$(echo "$mon" | jq '.width')
        height=$(echo "$mon" | jq '.height')
        phys_mm=$(echo "$mon" | jq '.physicalWidth')
        current=$(echo "$mon" | jq '.scale')

        # Use saved scale if available
        if [[ -f "$SCALE_FILE" ]]; then
            saved_scale=$(tr -d '[:space:]' < "$SCALE_FILE")
            if [[ -n "$saved_scale" ]]; then
                echo "Monitor $name: restoring saved scale ${saved_scale}"
                hyprctl keyword monitor "$name,preferred,auto,$saved_scale" >/dev/null 2>&1
                exit 0
            fi
        fi

        if [[ "$phys_mm" -le 0 ]] 2>/dev/null; then
            echo "No physical size info for $name, skipping"
            exit 0
        fi

        native_dpi=$(awk "BEGIN { printf \"%.1f\", $width / ($phys_mm / 25.4) }")

        best_scale=""
        best_diff=99999
        while read -r scale _ _; do
            diff=$(awk "BEGIN {
                eff = $native_dpi / $scale
                d = eff - $target_dpi
                if (d < 0) d = -d
                printf \"%.4f\", d
            }")
            if awk "BEGIN { exit !($diff < $best_diff) }"; then
                best_diff=$diff
                best_scale=$scale
            fi
        done < <(get_valid_scales "$width" "$height")

        if [[ -n "$best_scale" ]]; then
            eff_dpi=$(awk "BEGIN { printf \"%.0f\", $native_dpi / $best_scale }")
            echo "Monitor $name: ${native_dpi} native DPI, scale ${current} -> ${best_scale}, ${eff_dpi} effective DPI"
            hyprctl keyword monitor "$name,preferred,auto,$best_scale" >/dev/null 2>&1
            echo "$best_scale" > "$SCALE_FILE"
        fi
        ;;

    menu)
        mon=$(get_monitor)
        name=$(echo "$mon" | jq -r '.name')
        width=$(echo "$mon" | jq '.width')
        height=$(echo "$mon" | jq '.height')
        phys_mm=$(echo "$mon" | jq '.physicalWidth')
        current=$(echo "$mon" | jq '.scale')
        native_dpi=$(awk "BEGIN { printf \"%.1f\", $width / ($phys_mm / 25.4) }")

        # Build wofi menu entries, marking the current scale
        menu_items=""
        while read -r scale ew eh; do
            eff_dpi=$(awk "BEGIN { printf \"%.0f\", $native_dpi / $scale }")
            marker="  "
            if awk "BEGIN { exit !(($scale - $current) < 0.01 && ($current - $scale) < 0.01) }"; then
                marker="● "
            fi
            menu_items+="${marker}${scale}x  ${eff_dpi} DPI  ${ew}×${eh}"$'\n'
        done < <(get_valid_scales "$width" "$height")

        entry_count=$(echo -n "$menu_items" | wc -l)

        # Show wofi dropdown: top-right, no search bar, closes on focus loss
        choice=$(echo -n "$menu_items" | wofi --dmenu \
            --hide-search \
            --cache-file /dev/null \
            --location 3 \
            --width 260 \
            --define=lines="$entry_count" \
            --style "$HOME/.config/wofi/scale-menu.css" \
            2>/dev/null) || exit 0
        # Extract scale value (skip the marker prefix)
        selected_scale=$(echo "$choice" | awk '{for(i=1;i<=NF;i++){if($i~"x$"){print $i; exit}}}' | tr -d 'x')
        if [[ -n "$selected_scale" ]]; then
            hyprctl keyword monitor "$name,preferred,auto,$selected_scale" >/dev/null 2>&1
            echo "$selected_scale" > "$SCALE_FILE"
        fi
        ;;

    *)
        echo "Usage: hypr-scale.sh {list|get|set|up|down|auto|menu}" >&2
        exit 1
        ;;
esac
