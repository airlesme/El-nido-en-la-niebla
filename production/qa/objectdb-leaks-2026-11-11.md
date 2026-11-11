# ObjectDB leaks at exit - 2026-11-11

## Before / after (full gdUnit4 suite, 216/216)
- Before: `49 ObjectDB instances were leaked at exit`, `7 resources still in use at exit`.
- After: neither message printed (0 / 0). Suite still 216/216, 0 orphans. `tools/ci/forbid_timers.sh` clean.

## Cause (single root cause, test-only)
`--verbose` showed leaked `RefCounted` (refcount 1) plus the scripts they hold: `NoticeChannel`, `LogSink`,
`RecordingLog`, `ErrorPolicy` and the two suites `notice_channel_core_test.gd` / `notice_channel_cap_test.gd`.
Tests did `var ch: NoticeChannel = _ch` and subscribed lambdas that captured `ch`. Lambdas capture by strong
reference, and the channel stores them in `_subs` / `_tap` / `_after_drain`, so each test made the cycle
`channel -> _subs -> lambda -> channel`. RefCounted cannot free cycles. The 7 "resources in use" are the scripts
kept alive by those instances. The earlier 17/6 and 49/7 steps match the growth of those two suites (EB-002, EB-003).
No cycle exists in `src/`: NoticeChannel holds callables but never references itself; production subscribers
that capture the channel strongly would form the same cycle, so they must capture `self` (a Node) or unsubscribe.

## Change
- `tests/unit/state/notice_channel_core_test.gd`, `notice_channel_cap_test.gd`: removed the local `ch` alias;
  lambdas use `_ch`, which captures `self` (the suite, an Object, no refcount) instead of the channel.
- `src/`: no change. Public API (ADR-0001/0005/0009) untouched.

## Not attributable to engine_facts / gdUnit4
Nothing remained after the fix, so no residual leak to document.
