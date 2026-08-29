#!/usr/bin/env bash
# defpoll source for the eww spotify-control widget. Reads the daemon's
# live playback_state via `soloist ctl` rather than MPRIS — Soloist doesn't
# need MPRIS since we already control it directly through its own CLI.

set -uo pipefail

# eww runs under the uwsm-managed systemd --user session, whose PATH omits
# ~/bin (where soloist lives) — same issue spotify-soloist.service works
# around for the daemon itself.
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

json=$(soloist ctl now --json 2>/dev/null)
if [[ -z "$json" ]] || ! jq -e . <<<"$json" &>/dev/null; then
  echo '{"running":false,"state":"stopped","title":"","artist":"","position_ms":0,"duration_ms":1}'
  exit 0
fi

jq -c '
  {
    running: true,
    state: (if .status == "playing" then "playing" elif .status == "paused" then "paused" else "stopped" end),
    title: (.item.decorations.identity.name // ""),
    artist: ([.item.decorations.creators[]?.entity.decorations.identity.name] | join(", ")),
    position_ms: (.position.position_ms // 0),
    duration_ms: (.item.decorations.playback.duration_ms // 1)
  }
' <<<"$json"
