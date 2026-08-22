#!/usr/bin/env bash
# Control actions for the eww cliamp-control widget.
#
# Usage:
#   cliamp_ctl.sh toggle   # play/pause
#   cliamp_ctl.sh next     # next track
#   cliamp_ctl.sh prev     # previous track

set -euo pipefail

cmd="${1:?usage: cliamp_ctl.sh <command>}"

case "$cmd" in
toggle) cliamp toggle ;;
next) cliamp next ;;
prev) cliamp prev ;;
*)
  echo "unknown command: $cmd" >&2
  exit 1
  ;;
esac
