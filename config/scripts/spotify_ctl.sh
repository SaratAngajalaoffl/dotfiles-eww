#!/usr/bin/env bash
# Control actions for the eww spotify-control widget, via `soloist ctl`.
#
# Usage:
#   spotify_ctl.sh toggle           # play/pause
#   spotify_ctl.sh next             # next track
#   spotify_ctl.sh prev             # previous track
#   spotify_ctl.sh play-uri <uri>   # play a track/playlist/album URI
#   spotify_ctl.sh seek <ms>        # seek to a position, driven by the progress slider

set -euo pipefail

# eww runs under the uwsm-managed systemd --user session, whose PATH omits
# ~/bin (where soloist lives) — same issue spotify-soloist.service works
# around for the daemon itself.
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# The progress scale sends fractional ms (e.g. "128891.000000"); soloist wants an int.
round_ms() { awk -v v="$1" 'BEGIN { printf "%d", v + 0.5 }'; }

cmd="${1:?usage: spotify_ctl.sh <command> [args...]}"
shift

case "$cmd" in
toggle)
  status=$(soloist ctl now --json 2>/dev/null | jq -r '.status // "idle"')
  if [[ "$status" == "playing" ]]; then
    soloist ctl pause
  else
    soloist ctl play
  fi
  ;;
next) soloist ctl next ;;
prev) soloist ctl prev ;;
play-uri) soloist ctl play "${1:?uri required}" ;;
seek) soloist ctl seek "$(round_ms "${1:?ms required}")" ;;
*)
  echo "unknown command: $cmd" >&2
  exit 1
  ;;
esac
