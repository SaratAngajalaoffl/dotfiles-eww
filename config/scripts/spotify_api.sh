#!/usr/bin/env bash
# Shared helper for Spotify Web API search. Uses the app-only Client
# Credentials flow (Client ID + Secret, no user login/browser step) since
# search is public data — all actual playback goes through `soloist ctl`
# instead, which needs no Web API token at all.
#
# Sourced by spotify_search.sh — not run directly. The Client ID/Secret come
# from the gnome-keyring secret store (see systemd/.setup for the one-time
# `secret-tool store` commands), never from a file in this repo. Only the
# derived, short-lived access token is cached to disk.

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/spotify-widget"
TOKEN_CACHE="$CONFIG_DIR/search_token.json"

spotify::client_id() { secret-tool lookup service spotify-search key client-id; }
spotify::client_secret() { secret-tool lookup service spotify-search key client-secret; }

# Echoes a valid app-only access token, fetching (and caching) one if needed.
spotify::access_token() {
  local client_id client_secret
  client_id=$(spotify::client_id)
  client_secret=$(spotify::client_secret)
  if [[ -z "$client_id" || -z "$client_secret" ]]; then
    echo "Spotify search not set up — see systemd/.setup for the secret-tool store commands" >&2
    return 1
  fi

  mkdir -p "$CONFIG_DIR"
  if [[ -f "$TOKEN_CACHE" ]]; then
    local now expires_at cached
    now=$(date +%s)
    expires_at=$(jq -r '.expires_at // 0' "$TOKEN_CACHE" 2>/dev/null)
    if [[ "$expires_at" =~ ^[0-9]+$ ]] && (( now < expires_at - 30 )); then
      cached=$(jq -r '.access_token' "$TOKEN_CACHE")
      [[ -n "$cached" && "$cached" != "null" ]] && { echo "$cached"; return 0; }
    fi
  fi

  local resp access_token expires_in
  resp=$(curl -fsS -X POST https://accounts.spotify.com/api/token \
    -u "${client_id}:${client_secret}" \
    -d grant_type=client_credentials) || {
    echo "spotify: token request failed" >&2
    return 1
  }

  access_token=$(jq -r '.access_token // empty' <<<"$resp")
  expires_in=$(jq -r '.expires_in // 3600' <<<"$resp")
  [[ -z "$access_token" ]] && { echo "spotify: no access_token in response: $resp" >&2; return 1; }

  jq -n --arg t "$access_token" --argjson exp "$(( $(date +%s) + expires_in ))" \
    '{access_token: $t, expires_at: $exp}' >"$TOKEN_CACHE"
  chmod 600 "$TOKEN_CACHE"

  echo "$access_token"
}

spotify::api_get() {
  local path="$1" token
  token=$(spotify::access_token) || return 1
  curl -fsS "https://api.spotify.com/v1${path}" -H "Authorization: Bearer $token"
}
