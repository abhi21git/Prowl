# 064.025 — Codex thread attribution and dispatch evidence invalidation

## Context

Issue #944 reports a managed Codex `turn-ended` from a temporary TUI thread ending
an interactive worker's dispatch wait. The worker's matching completion receipt
arrived later. The observation store had marked the temporary thread's signal
stale, but the dispatch store retained its coalescing candidate and incomplete
state. Reading error diagnostics can itself refresh the observation epoch, so a
stale signal in an error does not establish whether invalidation preceded expiry.

## Change

- Keep independently detected session identity separate from hook-authored identity.
  A Codex hook must match that identity before becoming current evidence. Valid
  launch hooks awaiting session confirmation stay bounded and pending; confirmation
  replays only eligible signals. Codex's temporary threads share launch ancestry and
  notifier configuration, so those checks alone cannot establish the selected thread.
- Propagate invalidation of the old evidence epoch to the dispatch store. Remove its
  signal-derived candidates and retained attention/incomplete evidence, preserving
  pane-close candidates and terminal receipts. Never rebind a pending assignment to
  a replacement session or process.
- Refresh evidence before a signal-derived candidate commits or an initial
  observation is replayed. Revalidate buffered events at the wait consumer and capture
  the response decision and diagnostics together on the main actor. Cancel the wait
  deadline before optional screen stabilization, retaining the original overall timeout.
- Preserve receipt-only success, legitimate detector-confirmed Codex session changes,
  announcing runtimes' SessionStart behavior, and the 300 ms coalescing window.

## Alternatives

Increasing the coalescing delay only changes the race window. Filtering the error's
last diagnostic signal does not identify the event that triggered the outcome.
Clearing only the timer misses retained and already-buffered incomplete events.
Automatically moving a dispatch to the new epoch would let replacement work inherit
an earlier assignment. Keep attribution, invalidation and consumption checks explicit.

## Bounded pending evidence

The takeover review found that retaining the first eight pending hooks could
permanently exclude a later worker hook while detection lagged. Codex now retains
the eight most recent pending hooks, evicting the oldest on overflow. The bound
is unchanged, and eviction never promotes an unconfirmed hook. Other runtimes
retain their existing startup event ordering. This is a bounded fallback, not
lossless delivery: an evicted hook cannot become evidence later, but an explicit
completion receipt remains independent of this buffer.

Deferred-hook diagnostics record the pane, hook session and independently detected
session at ingress. They do not log the launch token or repeat on detector replay.

## Verification

- Source-level reproduction confirmed the foreign first-hook and stale-evidence
  failure before the fix. The updated production stores exclude the foreign thread from current evidence,
  clear evidence invalidated before or after coalescing, and accept the later receipt.
- 138 native tests passed across `AgentDispatchStoreTests`,
  `ManagedAgentHookObservationTests`, `AgentWaitCommandHandlerTests`,
  `AgentObservationTests`, `WorktreeTerminalManagerTests`, and `AgentS3bHookPayloadTests`.
  Coverage includes deferred confirmation, legitimate session rotation, buffered event
  revalidation, detector refresh through the manager, receipt and pane-close precedence,
  timeout preservation, and screen capture after a valid wait decision. A new
  parameterized saturation test first failed because no worker hook activated;
  it now verifies both retention of the newest and eviction of the oldest hook,
  before and after process detection.
- `make check` passed, including 241 script tests; `make build-app` passed with
  zero errors and warnings. The first cold test build also reported existing
  dependency and unrelated test warnings; the final focused test run had none.
- Live baseline: Prowl 2026.10.17 with Codex 0.163.0 returned
  `DISPATCH_INCOMPLETE` after 9.164 seconds while a worker was still running.
  The hook session differed from the worker session; the same dispatch later
  received a successful receipt.
- Live fixed Debug app: three fresh Codex Profile launches all completed on their
  first dispatch wait (45.993, 37.914 and 37.908 seconds). Each ran a 25-second
  command and verified a temporary file before submitting its receipt. The third
  run directly captured a foreign hook deferred before session detection, followed
  by a different independently detected worker session, a successful receipt, and
  that worker's verified live hook. The first two runs prove normal completion;
  buffered stdout prevented full foreign-hook attribution for those runs.
- Live verification used the worktree CLI and a dedicated socket. Test panes and
  the Debug process were closed; the installed Prowl instance was left running.

## Refs

- #944
- #945 (original contribution by philo-veritas)
