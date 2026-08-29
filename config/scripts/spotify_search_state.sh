#!/usr/bin/env bash
# deflisten source for spotify search results: emits the current results
# file, then re-emits whenever spotify_search_ctl.sh writes a new one.

set -euo pipefail

results_file="${XDG_RUNTIME_DIR:-/tmp}/eww-spotify-search.json"
results_dir="$(dirname "$results_file")"

emit() {
  [[ -f "$results_file" ]] && cat "$results_file" || echo "[]"
}

emit

inotifywait -q -m -e close_write,moved_to --format '%f' "$results_dir" 2>/dev/null |
  while read -r f; do
    [[ "$f" == "$(basename "$results_file")" ]] && emit
  done
