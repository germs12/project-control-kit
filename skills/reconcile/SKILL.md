---
name: reconcile
description: >
  Project Control's commit phase: consume pending Change Envelopes into canonical
  project state and propagate every effect. Use IMMEDIATELY whenever a worker
  returns, whenever .ai/envelopes/pending/ is non-empty, after answering inbox
  questions, and before dispatching work that might depend on recent changes.
  Completing a ticket does not complete its effects — this skill does.
---

# /reconcile

Run only as Project Control in the main session. This is the single-writer moment:
all `.ai/state/`, `.ai/decisions/`, and tracker-status writes happen here (and in
`/bootstrap`). Process envelopes oldest-first, one at a time, fully.

## Per envelope

1. **Validate.** Check the envelope against `.ai/schemas/change-envelope.yaml` and
   against its lease. Missing sections or no lease → reject: return it to the worker
   (or re-run the task) via `/finish-work`. Do not "fix it up" silently.

2. **Conflict-check.** Diff the envelope's claims against decisions and envelopes
   committed since the lease's `context_version`. A conflict (e.g., the work
   contradicts a decision accepted mid-flight) downgrades the item to `reopened` with
   a note, and generates a question if the resolution isn't obvious.

3. **Commit decisions.** For each entry in `decisions_created` you accept on the
   project's behalf (low-risk, consistent with priorities): write it to
   `.ai/decisions/active/<ID>.yaml` per the decision schema. Anything with security,
   privacy, financial, destructive, or hard-to-reverse consequences goes to the
   question queue instead, as a proposal awaiting the human. For each superseded
   decision: move its file to `.ai/decisions/superseded/`, set `status: superseded`,
   and grep active state/docs/work items for references to it — each reference
   becomes an update (now) or a work item (if substantive).

4. **Propagate impact.** Run the `/impact` procedure over `changes.behavior`,
   `changes.interfaces`, `assumptions_invalidated`, and newly committed decisions,
   seeded with the envelope's `affected_work`. Then act by status class:
   - **backlog / queued** → edit the item's description, `decisions`, and acceptance
     NOW, before anyone picks it up (index + tracker via operations.md).
   - **in_progress** → write a Context Invalidation notice per
     `.ai/schemas/context-invalidation.yaml` to `.ai/invalidations/`, addressed to
     that item's lease. If the worker is currently running, also surface the notice
     to it directly.
   - **done** → judge whether the change invalidates its result; if yes, set
     `reopened` with a note naming the trigger.

5. **Documentation.** For each `documentation_impacts` entry: fix trivially small
   ones now; otherwise create/refresh a DOC work item naming exactly what must change.

6. **Cleanup & discovery.** Execute `cleanup`: move obsoleted artifacts to
   `.ai/archive/` (mirroring their path) — archive, don't delete. Create work items
   from `discovered_work` with suggested priorities.

7. **Questions.** Append the envelope's `questions` to `.ai/state/questions.yaml`
   (assign Q ids). If any is blocking, or three or more are open, run `/questions`
   to refresh the inbox.

8. **Close the transaction.**
   - Set the work item's status from the envelope (`done` for completed, etc.).
   - Release the lease (`state: released`) and archive acknowledged invalidations.
   - Move the envelope to `.ai/envelopes/processed/`.
   - Increment `context_version` in `.ai/state/current.md`, update its `updated`
     stamp, and refresh its Focus / In flight / Recently landed / Watchouts sections.
   - Sync the tracker (status, comment linking the envelope) per operations.md.

## After all envelopes

Recalculate blockers against `.ai/state/dependencies.yaml` and priorities; then
report: envelopes processed, decisions committed/superseded, items updated by status
class, invalidations issued, questions queued, cleanup done, and what is now
dispatchable. If anything is dispatchable and non-conflicting, offer to
`/start-work` it.
