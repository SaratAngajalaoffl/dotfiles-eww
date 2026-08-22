#!/usr/bin/env bash
# deflisten source for the eww bluetooth-control widget.
#
# Emits one compact JSON line describing adapter + device state on start,
# then again every time BlueZ reports a relevant change over D-Bus.

set -euo pipefail

emit() {
  local raw base macs battery_json pairs joined mac path_mac pct

  raw=$(busctl call org.bluez / org.freedesktop.DBus.ObjectManager GetManagedObjects --json=short 2>/dev/null) \
    || raw='{"data":[{}]}'

  base=$(jq -c '
    .data[0] as $objs
    | (
        [$objs | to_entries[] | select(.value["org.bluez.Adapter1"] != null) | .value["org.bluez.Adapter1"]]
        | first // {}
      ) as $adapter
    | {
        powered: ($adapter.Powered.data // false),
        scanning: ($adapter.Discovering.data // false),
        devices: [
          $objs | to_entries[] | select(.value["org.bluez.Device1"] != null) |
          .value["org.bluez.Device1"] as $d |
          {
            mac: $d.Address.data,
            name: ($d.Alias.data // $d.Name.data // $d.Address.data),
            paired: ($d.Paired.data // false),
            trusted: ($d.Trusted.data // false),
            connected: ($d.Connected.data // false)
          }
        ] | sort_by([(.connected | not), (.paired | not), .name])
      }
  ' <<<"$raw")

  # Battery percentage (org.bluez.Battery1) is only exposed while a device
  # is connected, so look it up per connected device and merge it in.
  macs=$(jq -r '.devices[] | select(.connected) | .mac' <<<"$base")
  pairs=()
  if [[ -n "$macs" ]]; then
    while read -r mac; do
      [[ -z "$mac" ]] && continue
      path_mac="${mac//:/_}"
      pct=$(busctl get-property org.bluez "/org/bluez/hci0/dev_${path_mac}" org.bluez.Battery1 Percentage 2>/dev/null | awk '{print $2}')
      [[ "$pct" =~ ^[0-9]+$ ]] && pairs+=("\"$mac\":$pct")
    done <<<"$macs"
  fi
  joined=$(IFS=,; echo "${pairs[*]:-}")
  battery_json="{${joined}}"

  jq -c --argjson battery "$battery_json" '
    .devices |= map(
      . + {battery: ($battery[.mac] // null)}
      | .status = (
          if .connected then "Connected" + (if .battery then " · \(.battery)%" else "" end)
          elif .paired then "Paired"
          else "Available" end
        )
    )
  ' <<<"$base"
}

emit

dbus-monitor --system \
  "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path_namespace='/org/bluez'" \
  "type='signal',interface='org.freedesktop.DBus.ObjectManager',member='InterfacesAdded'" \
  "type='signal',interface='org.freedesktop.DBus.ObjectManager',member='InterfacesRemoved'" 2>/dev/null |
  while read -r line; do
    case "$line" in
    *"member=PropertiesChanged"* | *"member=InterfacesAdded"* | *"member=InterfacesRemoved"*) ;;
    *) continue ;;
    esac

    # Debounce: scanning can add/update several devices in quick succession;
    # coalesce a burst into a single re-emit, same idea as audio_state.sh.
    while read -r -t 0.3 _; do :; done
    emit
  done
