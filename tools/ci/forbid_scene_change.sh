#!/usr/bin/env bash
# C-X01 / ADR-0003: Shell is never replaced. Fails (exit 1) on `change_scene_to_file`,
# `change_scene_to_packed` or `reload_current_scene` in any .gd under src/.
# Observation lines: "ERROR path:line forbid-scene-change: text". Exit code is the only verdict.
# Usage: forbid_scene_change.sh [root]   (default: repo root)
set -u
root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
hits=0
[ -d "$root/src" ] || { echo "forbid_scene_change: clean"; exit 0; }
while IFS= read -r f; do
  rel="${f#"$root"/}"
  while IFS= read -r line; do
    echo "ERROR $rel:${line%%:*} forbid-scene-change: ${line#*:}"
    hits=$((hits + 1))
  done < <(grep -nE 'change_scene_to_file|change_scene_to_packed|reload_current_scene' "$f" || true)
done < <(find "$root/src" -name '*.gd' -type f)
[ "$hits" -eq 0 ] || { echo "forbid_scene_change: $hits finding(s)" >&2; exit 1; }
echo "forbid_scene_change: clean"
