#!/usr/bin/env bash
# ADR-0018 D4 layer 2: raw-byte audit of an export artifact.
# Usage: tools/ci/audit_artifact.sh <preset-dir | file.pck>
#   The preset name is the directory name (or the parent directory's name for a file):
#   demo-*     any FORBIDDEN pattern found      -> exit 1
#   playtest-* "src/dev/" or the marker missing -> exit 2 (the audit is blind)
#   dir missing / no files scanned              -> exit 2
# Prints one observation line per finding; the exit code is the only verdict.
set -u
nhits=0
target="${1:-}"
[ -n "$target" ] || { echo "usage: $0 <preset-dir|file.pck>" >&2; exit 2; }

FORBIDDEN=("src/dev/" "NIDO_DEV_ONLY_MARKER" "addons/gdUnit4/" "tools/data_check/" \
           "tools/ci/" "tools/godot/" "tests/unit/" "tests/integration/" "prototypes/")

if [ -d "$target" ]; then
  name="$(basename "$(cd "$target" && pwd)")"
  mapfile -t files < <(find "$target" -type f ! -name SHA256SUMS.txt | sort)
elif [ -f "$target" ]; then
  name="$(basename "$(cd "$(dirname "$target")" && pwd)")"
  files=("$target")
else
  echo "FATAL $target audit: not found" >&2; exit 2
fi
[ "${#files[@]}" -gt 0 ] || { echo "FATAL $target audit: no files scanned" >&2; exit 2; }

declare -A hit
for f in "${files[@]}"; do
  for p in "${FORBIDDEN[@]}"; do
    if LC_ALL=C grep -a -q -F -- "$p" "$f"; then
      hit["$p"]=1; nhits=$((nhits+1))
      echo "HIT $f audit: found '$p'"
    fi
  done
done

case "$name" in
  demo-*)
    if [ "$nhits" -gt 0 ]; then echo "FAIL $name audit: forbidden content in demo artifact"; exit 1; fi
    echo "OK $name audit: ${#files[@]} file(s) scanned, no forbidden pattern"
    ;;
  playtest-*)
    # Deviation from ADR-0018 D4 (V-18-6, observed 2026-11-11): with script_export_mode=2
    # (compressed tokens) the marker text inside .gd files is NOT visible as raw bytes; only
    # the PCK directory path "src/dev/" is. So the positive control is the path; the marker
    # is reported as INFO when visible and is never required.
    if [ -z "${hit[src/dev/]:-}" ]; then
      echo "FAIL $name audit: positive control missing (src/dev/ must be found); audit is blind"; exit 2
    fi
    [ -n "${hit[NIDO_DEV_ONLY_MARKER]:-}" ] || echo "INFO $name audit: marker text not visible in bytes (expected with script_export_mode=2)"
    echo "OK $name audit: positive control found, ${#files[@]} file(s) scanned"
    ;;
  *)
    echo "FATAL $name audit: directory name must start with demo- or playtest-" >&2; exit 2
    ;;
esac
exit 0
