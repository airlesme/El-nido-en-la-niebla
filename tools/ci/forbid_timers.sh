#!/usr/bin/env bash
# ADR-0002 D6 / ADR-0018 D6 step 9: no SceneTreeTimer / Timer for game time.
# Fails (exit 1) on `create_timer(` or `Timer.new(` in any .gd outside tests/ and prototypes/.
# Observation lines: "ERROR path:line rule: text". Exit code is the only verdict.
# Usage: forbid_timers.sh [root]   (default: repo root)
set -u
root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
hits=0
while IFS= read -r f; do
  rel="${f#"$root"/}"
  case "$rel" in tests/*|prototypes/*|addons/*|tools/godot/*|.godot/*|build/*|.claude/*) continue ;; esac
  while IFS= read -r line; do
    echo "ERROR $rel:${line%%:*} forbid-timers: ${line#*:}"
    hits=$((hits + 1))
  done < <(grep -nE 'create_timer\(|Timer\.new\(' "$f" || true)
done < <(find "$root" -name '*.gd' -type f -not -path '*/.git/*')
[ "$hits" -eq 0 ] || { echo "forbid_timers: $hits finding(s)" >&2; exit 1; }
echo "forbid_timers: clean"
