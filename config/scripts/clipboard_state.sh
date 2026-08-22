#!/usr/bin/env bash
# deflisten source for the eww clipboard-history widget.
#
# Emits a JSON array of {id, preview} on start, then again whenever
# cliphist's db file changes (new copy, delete, wipe).

set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist"
mkdir -p "$cache_dir"

emit() {
  cliphist list 2>/dev/null |
    jq -R -c 'capture("^(?<id>[0-9]+)\t(?<preview>.*)$") // empty' |
    jq -s -c .
}

emit

inotifywait -m -q -e modify -e close_write -e create -e moved_to "$cache_dir" 2>/dev/null |
  while read -r _; do
    # Debounce: storing/deleting can touch the db a few times in quick
    # succession; coalesce a burst into a single re-emit, same idea as
    # bluetooth_state.sh.
    while read -r -t 0.3 _; do :; done
    emit
  done
