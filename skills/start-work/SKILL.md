---
name: start-work
description: >
  Begin a unit of work the Project Control way: assemble the smallest sufficient
  context slice, acquire a lease, and dispatch (or brief) a worker. Use this for
  EVERY task start — whenever the user or Project Control says "work on X",
  "pick up ENG-142", "start the next ticket", or dispatches any worker agent.
  Never start work with a bare instruction and never let a worker self-serve
  context from the whole project.
---

# /start-work <work-item-id | short description>

Run as Project Control in the main session. Output of this skill is a **Work Brief**
plus a registered lease; the brief is what you hand to the worker subagent.

## Procedure

1. **Resolve the work item.** Find it in `.ai/state/work-items.yaml` (or the tracker
   via `.ai/protocol/operations.md`). If the request is a description with no item,
   create one first: assign the next ID for its workstream
   (`.ai/state/workstreams.yaml`), fill the work-item schema
   (`.ai/schemas/work-item.yaml`) including `touches`, and add it to the index.

2. **Check readiness.** Refuse to dispatch (and say why) if:
   - a `depends_on` item isn't done — offer to start the prerequisite instead;
   - a question in `blocking` state attaches to this item — point at `.ai/INBOX.md`;
   - an active lease already covers this item.

3. **Check for concept conflicts.** Compare this item's `touches` against active
   leases in `.ai/state/leases.yaml`. Overlap = warn, and either serialize (queue
   this item), narrow the scope so touches don't overlap, or proceed with an explicit
   note in both leases that concurrent work shares a concept.

4. **Assemble the context slice.** Gather, and nothing more:
   - the work item (objective, acceptance, notes);
   - each active decision listed in its `decisions` field, plus any active decision
     whose `affects` or topic matches this item's `touches` (grep
     `.ai/decisions/active/`);
   - direct dependencies and their one-line status;
   - interfaces/files this item is expected to touch, if known;
   - concurrent leases sharing concepts (from step 3);
   - open non-blocking questions attached to the item, with their logged assumptions;
   - unacknowledged invalidations for this item, if any.
   Do **not** include archive material, superseded decisions, discussion history, or
   unrelated project state. The brief must end with the line:
   `Everything else: DO NOT LOAD.`

5. **Acquire the lease.** Append to `.ai/state/leases.yaml` per
   `.ai/schemas/lease.yaml`: next `L-` id, agent, `context_version` copied from
   `.ai/state/current.md` frontmatter, `touches` copied from the item, one-line
   brief. Set the work item's status to `in_progress` (index and tracker, per
   operations.md).

6. **Dispatch.** Invoke the workstream's agent (`.ai/state/workstreams.yaml`) with
   the Work Brief. Prefer parallel dispatch of non-conflicting items in the same
   turn. When the human is doing the work themselves, print the brief instead.

## Work Brief format

```
WORK BRIEF — <work-item-id>: <title>
Lease: <L-id>   Agent: <agent>   Context version: <n>

Objective:
Acceptance:
Relevant decisions:            # id: one-line decision statement each
Direct dependencies:           # id — status
Interfaces / files in scope:
Concurrent work sharing concepts:
Open questions & logged assumptions:
Invalidations to acknowledge first:

Contract: .ai/protocol/worker-contract.md. Finish with /finish-work.
Everything else: DO NOT LOAD.
```
