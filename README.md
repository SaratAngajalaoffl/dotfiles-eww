# dotfiles-eww

Config and widgets for [eww](https://elkowar.github.io/eww/) (Elkowar's Wacky Widgets), including a Spotify search widget backed by the Spotify Web API.

Part of the [dotfiles-arch](https://github.com/SaratAngajalaoffl/dotfiles-arch) multi-repo dotfiles system.

## Layout

- `config` → `~/.config/eww` (see `.links`)

## Secrets

Declares a Spotify search Client ID/Secret in `.secrets` — `install.sh` prompts for and stores these via `secret-tool` (gnome-keyring); they're never committed here. See `config/scripts/spotify_api.sh`.

## Setup

Otherwise applied entirely by the parent repo's `install.sh`.
