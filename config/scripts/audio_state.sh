#!/usr/bin/env bash
# deflisten source for the eww audio-control widget.
#
# Emits one compact JSON line describing the current audio state
# (default sink/source plus per-application volumes) on start, then
# again every time pactl reports a relevant change.

set -euo pipefail

emit() {
  local default_sink default_source
  default_sink=$(pactl get-default-sink)
  default_source=$(pactl get-default-source)

  jq -nc \
    --argjson sinks "$(pactl -f json list sinks)" \
    --argjson sources "$(pactl -f json list sources)" \
    --argjson sink_inputs "$(pactl -f json list sink-inputs)" \
    --argjson source_outputs "$(pactl -f json list source-outputs)" \
    --arg default_sink "$default_sink" \
    --arg default_source "$default_source" \
    '
    def pct: (.volume | to_entries[0].value.value_percent | rtrimstr("%") | tonumber);
    def app_name: (.properties["application.name"] // .properties["node.name"] // "Unknown");
    {
      sink: (([$sinks[] | select(.name == $default_sink)] | first) as $s | if $s == null then null else {index: $s.index, name: ($s.description // $s.name), volume: ($s | pct), mute: $s.mute} end),
      source: (([$sources[] | select(.name == $default_source)] | first) as $s | if $s == null then null else {index: $s.index, name: ($s.description // $s.name), volume: ($s | pct), mute: $s.mute} end),
      sinks: [$sinks[] | {index, name, description: (.description // .name)}],
      apps: [$sink_inputs[] | {index, sink, name: app_name, volume: pct, mute}],
      mic_apps: [$source_outputs[] | select(.source != null) | {index, name: app_name, volume: pct, mute}]
    }
    '
}

emit

pactl subscribe 2>/dev/null | while read -r line; do
  case "$line" in
  *"on sink"* | *"on source"* | *"on sink-input"* | *"on source-output"*) ;;
  *) continue ;;
  esac

  # Debounce: a slider drag fires a burst of these events (one per
  # micro volume step), and re-emitting on every single one forces
  # eww to re-render the app list mid-drag, which kills the GTK
  # grab and makes the slider feel stuck. Swallow further events
  # until things go quiet for a bit, then emit once.
  while read -r -t 0.12 _; do :; done
  emit
done
