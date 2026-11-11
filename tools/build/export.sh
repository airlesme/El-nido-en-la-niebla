#!/usr/bin/env bash
# One-command export of one preset (ADR-0018 D1). Linux / CI.
# Usage: tools/build/export.sh <playtest-windows|playtest-linux|demo-windows|demo-linux>
# Env:   GODOT=<path to the pinned editor binary> (default: `godot` on PATH)
#        SKIP_AUDIT=1 skips the D4 audit (never for a delivered demo)
# Downloads nothing; fails loudly on any gap.
set -euo pipefail
fail() { echo "export.sh: FAIL: $*" >&2; exit 1; }

preset="${1:-}"
case "$preset" in
  playtest-windows|playtest-linux|demo-windows|demo-linux) ;;
  *) fail "usage: $0 <playtest-windows|playtest-linux|demo-windows|demo-linux>" ;;
esac

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
godot="${GODOT:-godot}"
command -v "$godot" >/dev/null 2>&1 || fail "Godot not found ($godot); set GODOT=<path>"
getv() { grep -E "^$1=" "$root/tools/godot/version.txt" | head -1 | cut -d= -f2- | tr -d '\r'; }

# 1. Pin check
build="$(getv BUILD)"
actual="$("$godot" --version | head -1 | tr -d '\r')"
[ "$actual" = "$build" ] || fail "Godot version '$actual' != pinned '$build' (tools/godot/version.txt)"

# 2. Templates pinned and installed
tpl_archive="$(getv TEMPLATES_ARCHIVE)"; tpl_sha="$(getv TEMPLATES_SHA512)"; tpl_dir="$(getv TEMPLATES_DIR)"
case "$tpl_archive$tpl_sha" in
  *"NOT VERIFIED"*) fail "templates are not pinned in tools/godot/version.txt (NOT VERIFIED); record archive + SHA-512 first (V-18-3)" ;;
esac
found=""
for d in "${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$tpl_dir" \
         "$HOME/.local/share/godot/export_templates/$tpl_dir"; do
  if [ -f "$d/version.txt" ]; then found="$d"; break; fi
done
[ -n "$found" ] || fail "export templates $tpl_dir not installed (looked in the Godot data dir)"

# 3. Preset exists
grep -q "^name=\"$preset\"" "$root/export_presets.cfg" || fail "preset '$preset' not in export_presets.cfg"

# 4. Import with the bounded exit-139 retry (E6)
set +e
"$godot" --headless --path "$root" --import; rc=$?
if [ "$rc" -eq 139 ]; then
  echo "::warning::import exited 139; retrying once (E6)"
  "$godot" --headless --path "$root" --import; rc=$?
fi
set -e
[ "$rc" -eq 0 ] || fail "--import exited $rc"

# 5. Export (debug/release pairing hard-coded)
case "$preset" in demo-*) mode=--export-release ;; *) mode=--export-debug ;; esac
case "$preset" in *-windows) bin=el-nido.exe ;; *) bin=el-nido.x86_64 ;; esac
out="$root/build/$preset"
rm -rf "$out"; mkdir -p "$out"
"$godot" --headless --path "$root" "$mode" "$preset" "$out/$bin" || fail "$mode $preset failed"
[ -f "$out/$bin" ] || fail "export reported success but $out/$bin does not exist"

# 6. D4 layer-2 audit
if [ "${SKIP_AUDIT:-0}" = "1" ]; then
  echo "export.sh: WARNING: audit SKIPPED; artifact NOT verified free of dev tools." >&2
else
  [ -f "$root/tools/ci/audit_artifact.sh" ] || fail "tools/ci/audit_artifact.sh missing (ADR-0018 D4 layer 2); SKIP_AUDIT=1 to bypass"
  ( cd "$root" && bash tools/ci/test_audit_artifact.sh >/dev/null ) || fail "test_audit_artifact.sh failed: audit not trustworthy"
  ( cd "$root" && bash tools/ci/audit_artifact.sh "build/$preset" ) || fail "audit_artifact.sh failed"
fi

# 7. Checksums
( cd "$out" && find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -printf '%P\n' | sort | xargs sha256sum > SHA256SUMS.txt )
echo "export.sh: OK $preset -> $out"
