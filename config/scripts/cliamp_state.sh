#!/usr/bin/env bash
# defpoll source for the eww cliamp-control widget.

set -euo pipefail

status=$(cliamp status --json 2>/dev/null) || status=""
jq -e . <<<"$status" &>/dev/null || status='{"ok":false}'

jq -c -n \
  --argjson status "$status" \
  '{
    running: ($status.ok // false),
    state: ($status.state // "stopped"),
    title: ($status.track.title // "")
  }'
