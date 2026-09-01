---
name: impact
description: >
  Determine the downstream consequences of a change or decision across work items,
  in-flight leases, decisions, and docs — and issue Context Invalidations for
  affected in-flight work. Use inside /reconcile for every envelope, whenever a
  decision is accepted or superseded, when the user asks "what does this affect /
  what breaks if we change X", and before approving any scope or architecture change.
---

# /impact <decision-id | envelope-file | described change>

Run as Project Control. Impact analysis is cheap; a worker building for a week on a
dead assumption is not. Bias toward flagging `possible` liberally — a reviewed
false positive costs a minute.

## Procedure

1. **Extract the change set.** From the input, list: behavior changes, interface
   changes, invalidated assumptions, and superseded decisions. Derive the concept
   tags they touch (same vocabulary as work-item `touches`).

   **A lesson from a review is a change set too.** When a review or a fix teaches something
   that generalizes, the agents already running were briefed before it existed, and nothing
   carries it to them — a decision propagates, a lesson does not. Two engineers days apart
   each shipped a migration with no transaction wrapper; the first was caught in adversarial
   review, fixed, and the reason written into that migration's own header, and the second
   shipped the identical defect in the same cycle because nobody re-briefed it. Recording a
   lesson for the NEXT dispatch is not delivering it to the current one, so treat it as a
   change set here and let step 4 issue the notices.

2. **Search every surface** for matches on those concepts, interfaces, and IDs:
   - `.ai/state/work-items.yaml` — `touches`, `decisions`, `depends_on`, text;
   - `.ai/state/leases.yaml` — active leases (in-flight victims);
   - `.ai/decisions/active/` — decisions whose `consequences` or `affects` mention
     the changed concepts (a change can contradict a standing decision — that is a
     finding, not something to paper over);
   - docs and code interfaces (grep for renamed/removed endpoints, flags, terms);
   - `.ai/state/questions.yaml` — open questions the change answers or moots.
   Seed with the envelope's own `affected_work` when the input is an envelope.

3. **Classify each hit** as `confirmed` or `possible`, and by status class:
   not started / queued · in progress · done. Note per hit *why* it's affected in
   one line.

4. **Act on in-flight hits immediately.** For every affected item with an active
   lease, write `.ai/invalidations/<INV-id>--<lease-id>.yaml` per
   `.ai/schemas/context-invalidation.yaml`: what changed, pointers to authoritative
   state, the specific assumptions now invalid, and concrete re-checks. This is
   cache invalidation for agents — it happens now, not after the report.

5. **Report** in this shape (it feeds `/reconcile` step 4 directly):

```
IMPACT — <trigger>
Concepts: <tags>

IN FLIGHT (invalidations issued)
  <item> — lease <L-id> — why — INV-<id>

QUEUED / BACKLOG (update before pickup)
  <item> — why — required edit

DONE (review for reopen)
  <item> — why — reopen? yes/no + reason

DECISIONS
  <id> — contradicted | partially superseded | unaffected-but-adjacent

DOCS / ARTIFACTS
  <path> — what must change

QUESTIONS
  answered/mooted: <ids>    newly raised: <drafts>
```

6. If run standalone (not inside `/reconcile`), end by offering to execute the
   queued-item updates and doc work-item creation via `/reconcile`.
