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

## Verification

- Source-level reproduction confirmed the foreign first-hook and stale-evidence
  failure before the fix. The updated production stores exclude the foreign thread from current evidence,
  clear evidence invalidated before or after coalescing, and accept the later receipt.
- 137 native tests passed across `AgentDispatchStoreTests`,
  `ManagedAgentHookObservationTests`, `AgentWaitCommandHandlerTests`,
  `AgentObservationTests`, `WorktreeTerminalManagerTests`, and `AgentS3bHookPayloadTests`.
  Coverage includes deferred confirmation, legitimate session rotation, buffered event
  revalidation, detector refresh through the manager, receipt and pane-close precedence,
  timeout preservation, and screen capture after a valid wait decision.
- `make check` passed, including 241 script tests; `make build-app` passed with
  zero errors and warnings.
- A live Codex worker end-to-end rerun was not part of this verification.

## Refs

- #944
