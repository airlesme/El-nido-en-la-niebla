#!/usr/bin/env bash
# Self-test for forbid_timers.sh: negative control (must fail) and clean/exempt cases (must pass).
# Run in CI right before the real check so the gate is proven able to fail.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src" "$tmp/tests" "$tmp/prototypes"
ok=0
expect() { # name expected_rc
  bash "$here/forbid_timers.sh" "$tmp" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq "$2" ]; then echo "PASS $1"; else echo "FAIL $1 (rc=$rc, want $2)"; ok=1; fi
}
echo 'func f(): pass' > "$tmp/src/a.gd";                                  expect clean 0
echo 'var t = get_tree().create_timer(1.0)' > "$tmp/tests/t.gd";         expect exempt-tests 0
echo 'var t = Timer.new()' > "$tmp/prototypes/p.gd";                      expect exempt-prototypes 0
echo 'await get_tree().create_timer(1.0).timeout' > "$tmp/src/b.gd";      expect create_timer 1
echo 'var t = Timer.new()' > "$tmp/src/b.gd";                            expect timer_new 1
exit $ok
