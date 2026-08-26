#!/usr/bin/env bash
# Control actions for the eww user-menu widget.
#
# Usage:
#   updates_ctl.sh update   # run a full system update in a terminal

set -euo pipefail

count() {
  local pacman_n aur_n
  pacman_n=$(checkupdates 2>/dev/null | wc -l)
  aur_n=0
  command -v yay &>/dev/null && aur_n=$(yay -Qua 2>/dev/null | wc -l)
  echo "$((pacman_n + aur_n))"
}

cmd="${1:?usage: updates_ctl.sh <command>}"

case "$cmd" in
update)
  kitty -e bash -c '
    sudo pacman -Syu
    command -v yay &>/dev/null && yay -Sua
    read -n1 -r -p "Done - press any key to close..."
  '
  eww update pkg_updates="$(count)"
  ;;
*)
  echo "unknown command: $cmd" >&2
  exit 1
  ;;
esac
