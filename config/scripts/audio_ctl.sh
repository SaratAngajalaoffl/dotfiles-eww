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
#   audio_ctl.sh mic-volume <source-output-index> <percent>
#   audio_ctl.sh mic-mute <source-output-index>

set -euo pipefail

# Snap a raw slider value to the nearest 5% so manual drags always land on
# a clean number, even though pipewire's flat-volume model can otherwise
# leave apps/sinks sitting at odd values like 99% or 101%.
round() { awk -v v="$1" 'BEGIN { printf "%d", int(v / 5 + 0.5) * 5 }'; }

cmd="${1:?usage: audio_ctl.sh <command> [args...]}"
shift

case "$cmd" in
sink-volume) pactl set-sink-volume @DEFAULT_SINK@ "$(round "$1")%" ;;
sink-mute) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
source-volume) pactl set-source-volume @DEFAULT_SOURCE@ "$(round "$1")%" ;;
source-mute) pactl set-source-mute @DEFAULT_SOURCE@ toggle ;;
app-volume) pactl set-sink-input-volume "$1" "$(round "$2")%" ;;
app-mute) pactl set-sink-input-mute "$1" toggle ;;
mic-volume) pactl set-source-output-volume "$1" "$(round "$2")%" ;;
mic-mute) pactl set-source-output-mute "$1" toggle ;;
*)
  echo "unknown command: $cmd" >&2
  exit 1
  ;;
esac
