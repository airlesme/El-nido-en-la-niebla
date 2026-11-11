#!/usr/bin/env bash
# Self-test of tools/ci/audit_artifact.sh on synthetic fixtures (ADR-0018 test plan).
# Fixtures are built in a temp dir; nothing is read from the repo or the network.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
audit="$here/audit_artifact.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fails=0
expect() { # <name> <expected-exit> <dir>
  bash "$audit" "$3" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq "$2" ]; then echo "PASS $1 (exit $rc)"; else echo "FAIL $1: expected $2 got $rc"; fails=$((fails+1)); fi
}
mk() { mkdir -p "$tmp/$1"; printf '%s' "$2" > "$tmp/$1/a.pck"; }

mk demo-clean       "res://src/core/boot/boot.gd"
mk demo-leak        "xx res://src/dev/dev_marker.gd xx"
mk demo-marker      "NIDO_DEV_ONLY_MARKER"
mk demo-gdunit      "addons/gdUnit4/plugin.cfg"
mk playtest-good    "res://src/dev/dev_marker.gd NIDO_DEV_ONLY_MARKER"
mk playtest-blind   "res://src/core/boot/boot.gd"
mk playtest-pathonly "res://src/dev/dev_marker.gd.remap"
mkdir -p "$tmp/demo-empty" "$tmp/playtest-empty"

expect "demo clean passes"            0 "$tmp/demo-clean"
expect "demo with src/dev fails"      1 "$tmp/demo-leak"
expect "demo with marker fails"       1 "$tmp/demo-marker"
expect "demo with gdUnit4 fails"      1 "$tmp/demo-gdunit"
expect "playtest with control passes" 0 "$tmp/playtest-good"
expect "playtest path-only passes"    0 "$tmp/playtest-pathonly"
expect "playtest blind exits 2"       2 "$tmp/playtest-blind"
expect "empty demo dir exits 2"       2 "$tmp/demo-empty"
expect "empty playtest dir exits 2"   2 "$tmp/playtest-empty"
expect "missing dir exits 2"          2 "$tmp/nope"
expect "single pck file works"        1 "$tmp/demo-leak/a.pck"

[ "$fails" -eq 0 ] && echo "test_audit_artifact: ALL PASS" || { echo "test_audit_artifact: $fails FAILED"; exit 1; }
