#!/usr/bin/env bash
# ADR-0018 D8: version pins must agree. Exit 1 on any mismatch; lines are observations.
# Checks: tools/godot/version.txt VERSION vs tests.yml godot-version; BUILD vs VERSION.md;
# GDUNIT4 vs addons/gdUnit4/plugin.cfg; project.godot config/features minor.
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bad=0
err() { echo "ERROR check-pins: $*"; bad=1; }
getv() { grep -E "^$1=" "$root/tools/godot/version.txt" | head -1 | cut -d= -f2- | tr -d '\r'; }

ver="$(getv VERSION)"; build="$(getv BUILD)"; gd="$(getv GDUNIT4)"
[ -n "$ver" ] && [ -n "$build" ] && [ -n "$gd" ] || err "version.txt lacks VERSION/BUILD/GDUNIT4"
short="${ver%-stable}"                       # 4.7.2-stable -> 4.7.2
minor="${short%.*}"                          # 4.7.2 -> 4.7

for wf in "$root"/.github/workflows/*.yml; do
  [ -f "$wf" ] || continue
  for v in $(grep -E "godot-version:" "$wf" | sed -E "s/.*godot-version:[[:space:]]*['\"]?([^'\" ]+).*/\1/"); do
    [ "$v" = "$short" ] || err "$(basename "$wf") godot-version '$v' != '$short'"
  done
done
grep -q "$build" "$root/docs/engine-reference/godot/VERSION.md" || err "VERSION.md lacks build string $build"
pv="$(grep -E '^version=' "$root/addons/gdUnit4/plugin.cfg" | head -1 | sed -E 's/version="?([^"]*)"?/\1/' | tr -d '\r')"
[ "$pv" = "$gd" ] || err "gdUnit4 plugin.cfg version '$pv' != '$gd'"
grep -E 'config/features' "$root/project.godot" | grep -q "\"$minor\"" || err "project.godot config/features lacks \"$minor\""
[ "$bad" -eq 0 ] && echo "check_pins: ok ($short, gdUnit4 $gd)"
exit "$bad"
