#!/usr/bin/env bash
# defpoll source: your pinned playlists (name + uri) for quick-launch.
# Edit spotify_playlists.json to change which playlists show up.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

cat spotify_playlists.json
