#!/usr/bin/env bash
# Runs a Spotify search and writes the results where spotify_search_state.sh
# (an eww deflisten) picks them up. Bound to the search box's :onaccept.
#
# Usage: spotify_search_ctl.sh "<query>"

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

results_file="${XDG_RUNTIME_DIR:-/tmp}/eww-spotify-search.json"
# eww substitutes the search box's {} placeholder into this command
# unquoted, so a multi-word query arrives as multiple positional args —
# rejoin them here.
query="$*"

# eww's :onaccept timeout kills the process it directly spawned, not that
# process's children — and since this script is invoked as `/bin/sh -c
# "spotify_search_ctl.sh ..."` (a single trailing command), bash exec-
# replaces itself with this script, so a timeout kill lands here mid-flight,
# before the mv below ever runs. Do the actual work in a detached background
# subshell so eww killing this top-level invocation can't cut off the API
# round-trip.
(
  if [[ -z "$query" ]]; then
    echo "[]" >"$results_file.tmp"
  else
    ./spotify_search.sh "$query" >"$results_file.tmp" || echo "[]" >"$results_file.tmp"
  fi
  mv "$results_file.tmp" "$results_file"
) &
disown
