#!/usr/bin/env bash
# Control actions for the eww audio-control widget.
#
# Usage:
#   audio_ctl.sh sink-volume <percent>
#   audio_ctl.sh sink-mute
#   audio_ctl.sh source-volume <percent>
#   audio_ctl.sh source-mute
#   audio_ctl.sh app-volume <sink-input-index> <percent>
#   audio_ctl.sh app-mute <sink-input-index>
#   audio_ctl.sh set-sink <sink-name>            # switch the default output and move all apps to it
#   audio_ctl.sh app-sink <sink-input-index> <sink-name>  # move one app to a different output
#   audio_ctl.sh set-source <source-name>        # switch the default input and move all apps to it

set -euo pipefail

# Snap a raw slider value to the nearest 5% so manual drags always land on
# a clean number, even though pipewire's flat-volume model can otherwise
# leave apps/sinks sitting at odd values like 99% or 101%.
round() { awk -v v="$1" 'BEGIN { printf "%d", int(v / 5 + 0.5) * 5 }'; }

# Volume/mute are instant and drag-coupled (a slider fires this repeatedly
# mid-drag), so they're left out of the busy/wait-cursor state - only
# device switching (set-sink/app-sink), which can take a moment moving
# multiple streams, sets it. Always cleared on exit regardless of outcome.
trap 'eww update busy=false >/dev/null 2>&1 || true' EXIT

cmd="${1:?usage: audio_ctl.sh <command> [args...]}"
shift

case "$cmd" in
sink-volume) pactl set-sink-volume @DEFAULT_SINK@ "$(round "$1")%" ;;
sink-mute) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
source-volume) pactl set-source-volume @DEFAULT_SOURCE@ "$(round "$1")%" ;;
source-mute) pactl set-source-mute @DEFAULT_SOURCE@ toggle ;;
app-volume) pactl set-sink-input-volume "$1" "$(round "$2")%" ;;
app-mute) pactl set-sink-input-mute "$1" toggle ;;
set-sink)
  eww update busy=true
  pactl set-default-sink "$1"
  pactl -f json list sink-inputs | jq -r '.[].index' | while read -r idx; do
    pactl move-sink-input "$idx" "$1"
  done
  ;;
set-source)
  eww update busy=true
  pactl set-default-source "$1"
  pactl -f json list source-outputs | jq -r '.[].index' | while read -r idx; do
    pactl move-source-output "$idx" "$1"
  done
  ;;
app-sink)
  eww update busy=true
  pactl move-sink-input "$1" "$2"
  ;;
*)
  echo "unknown command: $cmd" >&2
  exit 1
  ;;
esac
