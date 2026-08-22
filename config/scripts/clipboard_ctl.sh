#!/usr/bin/env bash
# Control actions for the eww clipboard-history widget.
#
# Usage:
#   clipboard_ctl.sh copy <id>
#   clipboard_ctl.sh delete <id>
#   clipboard_ctl.sh wipe

set -euo pipefail

cmd="${1:?usage: clipboard_ctl.sh <command> [id]}"
shift

find_line() {
  # cliphist decode/delete both expect the original "<id>\t<preview>" line
  # back on stdin - they parse the leading id out of it themselves.
  cliphist list | grep -P "^${1}\t"
}

case "$cmd" in
copy)
  id="${1:?id required}"
  line=$(find_line "$id") || exit 0
  printf '%s' "$line" | cliphist decode | wl-copy
  ;;
delete)
  id="${1:?id required}"
  line=$(find_line "$id") || exit 0
  printf '%s' "$line" | cliphist delete
  ;;
wipe)
  cliphist wipe
  ;;
*)
  echo "unknown command: $cmd" >&2
  exit 1
  ;;
esac
