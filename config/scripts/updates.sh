#!/usr/bin/env bash
# deflisten source for the eww user-menu widget: pending pacman + AUR update count.

set -uo pipefail

count() {
  local pacman_n aur_n
  pacman_n=$(checkupdates 2>/dev/null | wc -l)
  aur_n=0
  command -v yay &>/dev/null && aur_n=$(yay -Qua 2>/dev/null | wc -l)
  echo "$((pacman_n + aur_n))"
}

while true; do
  count
  sleep 1800
done
