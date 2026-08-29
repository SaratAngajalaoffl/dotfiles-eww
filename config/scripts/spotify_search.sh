#!/usr/bin/env bash
# Search Spotify for tracks. Outputs a compact JSON array of
# {uri, name, artist} for the eww search results list.
#
# Usage: spotify_search.sh "<query>"

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./spotify_api.sh

query="${1:-}"
if [[ -z "$query" ]]; then
  echo "[]"
  exit 0
fi

encoded=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$query")

spotify::api_get "/search?q=${encoded}&type=track&limit=8" |
  jq -c '[.tracks.items[] | {uri, name, artist: (.artists | map(.name) | join(", "))}]'
