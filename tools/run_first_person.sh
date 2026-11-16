#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
godot_binary="${GODOT_BIN:-$HOME/Applications/Godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64}"
if [[ ! -x "$godot_binary" ]]; then
    godot_binary="$(command -v godot || command -v godot4)"
fi
exec "$godot_binary" --path "$project_root" res://experiments/first_person/captain_lab.tscn "$@"
