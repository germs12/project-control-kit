# PROJECT

<!-- TEMPLATE: run /bootstrap in Claude Code to fill this from the repo.
     Hard rule: an agent must be able to consume this file in 30-60 seconds.
     Anything longer belongs in a decision record, a doc, or the archive. -->

**Status:** ⚠ not yet bootstrapped — run `/bootstrap`

## What are we building?
<one paragraph>

## Who is it for?
<one or two lines>

## What currently matters?
<3-5 bullets; mirror of state/priorities.yaml>

## Architectural constraints
<hard constraints only — stack, hosting, compliance, non-negotiables>

## Where is canonical information?
- Decisions: `.ai/decisions/active/`
- Work index: `.ai/state/work-items.yaml`
  (tracker: <none — this index IS the tracker | Linear | Jira | GitHub Issues | ...>,
   detected from: <the evidence, e.g. "branches are eng-*, commits cite ENG-###">)
- Current focus + context version: `.ai/state/current.md`
- Authority table: `.ai/protocol/operations.md`

## Before modifying anything
You operate under `.ai/protocol/worker-contract.md`: lease via /start-work,
load only your context slice, finish via /finish-work with a Change Envelope.
