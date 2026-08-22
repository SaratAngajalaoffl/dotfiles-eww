#!/usr/bin/bash

# Opens the given eww window on the monitor under the cursor (i.e. the
# monitor whose waybar the user actually clicked on), after closing any
# other eww window that's currently open, so only one widget is ever
# visible at a time. Clicking the icon for an already-open widget closes
# it (toggle-off) instead of reopening it.

window="$1"
[ -z "$window" ] && exit 1

already_open=false
eww active-windows | grep -q "^${window}:" && already_open=true

eww close-all

$already_open && exit 0

read -r cx cy <<< "$(hyprctl cursorpos | tr -d ',')"

screen=$(hyprctl monitors -j | jq -r --argjson cx "$cx" --argjson cy "$cy" '
  (map(select(.x <= $cx and $cx < (.x + .width) and .y <= $cy and $cy < (.y + .height))) | .[0].id)
  // 0
')

eww open --screen "$screen" "$window"
