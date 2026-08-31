---
name: health
description: >
  Audit project coherence: verify that state, leases, decisions, dependencies,
  envelopes, trackers, and docs still describe the same reality, and report
  synchronization defects by severity. Use on demand ("is my project coherent?",
  "run health"), at the start of a session after time away, after heavy parallel
  work, and periodically during long runs. This is the system's self-test — a swarm
  of fast workers diverging into different versions of reality is exactly what it
  catches.
---

# /health

Run as Project Control. Read-only: report defects and offer fixes; execute fixes
only via `/reconcile` (or the librarian for archival sweeps) after reporting.

## Checks

Work & leases
- every `in_progress` item has exactly one active lease; every active lease points
  at a real `in_progress` item
- no lease is stale (started long ago, no envelope, agent not running)
- no two active leases share a `touches` concept without an acknowledged note

Dependencies
- every `depends_on` / `blocks` / edge ID resolves to a real item
- no dependency cycles
- nothing is blocked by an item that is already `done` or `dropped`

Decisions
- no two active decisions contradict each other
- nothing in `decisions/active/` is referenced by a newer decision's `supersedes`
- no active work item, state file, or doc references a superseded decision ID
- every decision in `decisions/superseded/` has `status: superseded`

Envelopes & invalidations
- `.ai/envelopes/pending/` is empty (anything sitting there is unreconciled work)
- every unacknowledged invalidation's lease is still active — and no in-flight item
  was changed by a reconcile without an invalidation being issued
- processed envelopes' `cleanup` entries were actually executed

External sync (per `.ai/protocol/operations.md`, when adapters are available)
- tracker status matches the index for every open item
- linked PRs/issues exist; merged PRs aren't attached to `backlog`/`queued` items
- docs don't reference endpoints/flags/terms removed by processed envelopes

State hygiene
- `context_version` in `current.md` ≥ every lease's recorded version
- `current.md` sections match reality (in-flight list = active leases)
- `questions.yaml` has no orphaned blocking question (blocking + open + absent from
  INBOX.md)
- PROJECT.md is bootstrapped and its "what currently matters" agrees with
  `priorities.yaml`

## Report format

```
PROJECT COHERENCE: <n>%        (checks passed / checks applicable)

<k> synchronization defects

HIGH    <defect> — <evidence> — <proposed fix>
MEDIUM  ...
LOW     ...

Fix now via /reconcile? [list of safe auto-fixes]  |  Needs human: [list]
```

Severity guide: HIGH = an agent is or will be acting on wrong reality (stale
in-flight context, contradicting active decisions, unreconciled envelopes);
MEDIUM = drift that misleads the next reader (tracker mismatch, dead references,
docs behind behavior); LOW = hygiene (stale notes, unexecuted low-risk cleanup).

Example defect, for calibration:
`HIGH — ENG-211 is being implemented against ARCH-17; ARCH-17 was superseded by
ARCH-23 43 minutes ago; lease L-044 has no acknowledged invalidation — issue
INV now and steer the worker.`
