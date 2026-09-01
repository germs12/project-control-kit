---
name: status
description: >
  Produce the human project briefing: what landed, what's in flight, what's
  blocked, what needs the human, what's next. Use whenever the user asks "where
  are we", "status", "what's going on with the project", "catch me up", or returns
  to a session after time away. Reads state only — never reconstructs history from
  conversations, and never writes.
---

# /status

Run as Project Control. This is a briefing for a busy human, not a data dump:
everything in it comes from active state (`current.md`, leases, work index,
questions, priorities, recently processed envelopes) — which is itself the test
that the system is working. If you find yourself needing archived material to
explain the present, say so; that's a `/health` finding.

## Procedure

1. Read `.ai/state/current.md`, `leases.yaml`, `work-items.yaml`,
   `priorities.yaml`, `questions.yaml`, and the most recent files in
   `.ai/envelopes/processed/`.
2. If `.ai/envelopes/pending/` is non-empty, lead with that: the briefing is
   stale until `/reconcile` runs — offer to run it first.
3. Render the briefing. Keep it under ~30 lines; link IDs, don't restate bodies. Say
   `merged` or `deployed` and never let one imply the other — whether a merge reaches
   production is a fact about the pipeline, established once per repo (see `/reconcile`).

## Briefing format

```
STATUS — <project> — <date>   (context v<CV>)

LANDED since last briefing
  <item> — one line of what changed (from envelope summaries) — merged | deployed

IN FLIGHT
  <item> — <agent> — started <when> — <one-line brief>   [⚠ unacked INV-<id> if any]

BLOCKED
  <item> — on <dependency | Q-id> — since <when>

NEEDS YOU  (<n> decisions — .ai/INBOX.md)
  Q-<id> — <title> — blocking <items> — recommended: <option>

UP NEXT (dispatchable now)
  <item> — <priority> — why it's next per priorities.yaml

WATCHOUTS
  <anything from current.md, stale leases, or coherence smells>
```

4. Close with at most one suggested action ("answer Q-81 and I can dispatch three
   items in parallel" / "run /reconcile — two envelopes pending"). If nothing needs
   the human and nothing is dispatchable, say the rarest sentence in project
   management: everything is moving and nothing needs you.
