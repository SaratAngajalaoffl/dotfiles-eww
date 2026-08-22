#!/usr/bin/env bash
# Control actions for the eww bluetooth-control widget.
#
# Usage:
#   bluetooth_ctl.sh power-on
#   bluetooth_ctl.sh power-off
#   bluetooth_ctl.sh scan-on
#   bluetooth_ctl.sh scan-off
#   bluetooth_ctl.sh connect <mac>
#   bluetooth_ctl.sh disconnect <mac>
#   bluetooth_ctl.sh forget <mac>

set -euo pipefail

# BlueZ stops discovery the instant the client that started it disconnects
# from D-Bus, so a plain one-shot `busctl call StartDiscovery` gets silently
# cancelled within ~1s of the process exiting. Scanning needs a D-Bus
# connection that stays open, so scan on/off is routed through a persistent
# backgrounded bluetoothctl process fed over a FIFO instead.
bt_fifo="${XDG_RUNTIME_DIR:-/tmp}/eww-bluetoothctl.fifo"
bt_pidfile="${XDG_RUNTIME_DIR:-/tmp}/eww-bluetoothctl.pid"

ensure_session() {
  if [[ -f "$bt_pidfile" ]] && kill -0 "$(cat "$bt_pidfile" 2>/dev/null)" 2>/dev/null; then
    return
  fi
  rm -f "$bt_fifo"
  mkfifo "$bt_fifo"
  # Opening the FIFO read-write keeps its read end from ever seeing EOF,
  # so bluetoothctl's stdin stays open across separate writer processes.
  exec 3<>"$bt_fifo"
  bluetoothctl <&3 >/dev/null 2>&1 &
  echo $! >"$bt_pidfile"
  exec 3>&-
  sleep 0.3
}

send_session() {
  ensure_session
  echo "$1" >"$bt_fifo"
}

notify_fail() {
  notify-send -a "Bluetooth" -u normal "Bluetooth" "$1" 2>/dev/null || true
}

device_name() {
  bluetoothctl info "$1" 2>/dev/null | sed -n 's/^[[:space:]]*Name: //p' | head -1
}

cmd="${1:?usage: bluetooth_ctl.sh <command> [args...]}"
shift

case "$cmd" in
power-on) busctl set-property org.bluez /org/bluez/hci0 org.bluez.Adapter1 Powered b true ;;
power-off) busctl set-property org.bluez /org/bluez/hci0 org.bluez.Adapter1 Powered b false ;;
scan-on) send_session "scan on" ;;
scan-off) send_session "scan off" ;;
connect)
  mac="${1:?mac required}"
  name=$(device_name "$mac")
  [[ -z "$name" ]] && name="$mac"

  if bluetoothctl connect "$mac"; then
    exit 0
  fi

  # A device BlueZ still lists as Paired can have a stale/missing link key
  # (e.g. it was re-paired with a different host since), which fails connect
  # with br-connection-key-missing rather than anything `pair`/`trust` can
  # fix directly. Forget it and try a clean pair — this only succeeds if the
  # device is currently powered on and in pairing/discoverable mode, so give
  # it a brief scan window to be rediscovered first.
  bluetoothctl remove "$mac" >/dev/null 2>&1 || true
  send_session "scan on"
  sleep 4
  send_session "scan off"
  sleep 0.5

  if bluetoothctl pair "$mac" && bluetoothctl trust "$mac" >/dev/null 2>&1 && bluetoothctl connect "$mac"; then
    exit 0
  fi

  notify_fail "Couldn't connect to ${name}. Put it in pairing mode and try again."
  exit 1
  ;;
disconnect)
  mac="${1:?mac required}"
  name=$(device_name "$mac")
  [[ -z "$name" ]] && name="$mac"
  bluetoothctl disconnect "$mac" || { notify_fail "Couldn't disconnect ${name}."; exit 1; }
  ;;
forget)
  mac="${1:?mac required}"
  name=$(device_name "$mac")
  [[ -z "$name" ]] && name="$mac"
  bluetoothctl remove "$mac" || { notify_fail "Couldn't forget ${name}."; exit 1; }
  ;;
*)
  echo "unknown command: $cmd" >&2
  exit 1
  ;;
esac
