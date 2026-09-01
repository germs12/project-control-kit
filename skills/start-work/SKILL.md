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

3. **Check for concept conflicts, then split by FILE.** Compare this item's `touches`
   against active leases in `.ai/state/leases.yaml`. Overlap = warn, and either
   serialize, narrow the scope so touches don't overlap, or proceed with an explicit
   note in both leases.
   Concept-disjoint is not enough in practice. Two leases with different `touches` still
   collide if they edit the same file, so choose parallel work to be **file-disjoint**
   and say in each brief which files that worker owns and which belong to whom. Every
   collision in a heavily-parallel session traced to one shared file — name the known
   hot spot in your repo explicitly and tell workers to keep their diff to it minimal
   and to state exactly what they touched.

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

6. **Reserve the shared namespaces.** Anything a worker creates by picking "the next
   free" identifier collides when several workers are in flight, because they all read
   the same state and all pick the same value. Before dispatching, assign each worker
   its own range and put it IN THE BRIEF:
   - **Decision ids** — give a disjoint block per worker (`DATA-008..DATA-012`). Four
     collided in one session without this (`DATA-005`, `OPS-005`, `SITE-007`,
     `BRAND-004`/`BRAND-005`), each pair a different decision under one id.
   - **Migration prefixes** — assign the exact filename prefix. Three collided on one
     timestamp in a single round; renaming afterwards is worse than it sounds, because
     a test can open a migration BY NAME and the rename leaves the suite red.
   - **Scratchpad paths** — the scratchpad is derived from the REPO, not the agent, so
     two workers writing `pr.md` overwrite each other. One agent published another's PR
     body this way. Require a subdirectory unique to the worker.

   **Reserve against every id ever CLAIMED, not against what is committed.** The highest
   id in `.ai/decisions/active/` is the wrong high-water mark, and so is the highest in
   `pending/`. An id is taken the moment anything cites it. Check all four:
   `.ai/decisions/active/`, `.ai/envelopes/pending/`, **`.ai/envelopes/processed/`**, and
   `grep -rn "<PREFIX>-0" lib app components docs` — because shipped code cites decision
   ids in comments, and a processed envelope's proposal may never have been committed.

   A brief once reserved `FARE-007` that a *processed* envelope had already claimed and
   that shipped code already cited. The worker caught it and renumbered; if it had not,
   two decisions would share one id and the next reader would find the wrong one. This
   project currently has several ids in that state — cited by code, docs or a SQL proof
   with no record on disk — and every one is a trap for the next reservation. Read the pending envelopes' `decisions_created`
   before you reserve anything. Two collisions happened in one cycle this way — two
   merged envelopes held `SITE-020..026` while fresh reservations were handed out in the
   same block — and the merged side always wins, because its ids are quoted in merged PR
   bodies and renumbering strands the citation. When you must move someone, move the
   worker that has shipped nothing, and tell it to grep its own branch, commit messages
   and PR body, not just its envelope.

   **Lease ids collide across sessions.** A worker killed by a rate limit and resumed
   later carries the lease id it was given in the previous session's numbering, while the
   current session has already reissued it. Before assigning `L-n`, check the pending and
   processed envelopes for leases in flight, not just `leases.yaml`.

   **Verify every decision id you cite in a brief by reading its title.** Citing the
   neighbouring record — "SITE-004, a tenant's domain must never show another tenant's
   brand," when the rule lives in SITE-005 — sends a worker to argue with the wrong
   document. Workers have caught this and worked to the rule instead of the citation,
   which is the good outcome and not one to rely on.

7. **Dispatch — and ISOLATE, or the file ownership you just computed means nothing.**
   Invoke the workstream's agent (`.ai/state/workstreams.yaml`) with the Work Brief.
   Prefer parallel dispatch of non-conflicting items in the same turn. When the human is
   doing the work themselves, print the brief instead.

   **Every worker that writes files gets its own worktree.** With the Agent tool that is
   `isolation: "worktree"`. Without it a subagent starts in the DISPATCHER's working
   directory — so parallel workers share one checkout, one index and one HEAD, and steps
   3 and 6 protect nothing.

   Not theoretical. Three leases once landed in one tree and produced: commits labelled
   for one ticket containing two other tickets' files; a branch named for one agent whose
   HEAD was another agent's work; and — the one that mattered — a claim an agent had
   deliberately DELETED for legal reasons reinstated in a peer's commit, because it was
   swept up mid-mutation-test while the file was momentarily reverted. One worker reported
   `git status` returning different file lists forty seconds apart. Two escaped into
   scratch worktrees and rebuilt; the third's branch had to be abandoned.

   Writing "work in your own worktree" in the brief does NOT achieve this. Workers inherit
   the cwd before they read a word of it. **Isolation is the dispatcher's job, not the
   worker's discipline** — and the dispatcher's own tree is the worst place for the
   collision to land, because that is where project state lives and where you check other
   branches' files out to inspect them.

## Check the agent type's TOOLS before you write the brief

An agent cannot do what its type has no tool for, and the brief will not tell it that — it will
spend its whole run producing correct work it cannot deliver.

`docs-writer`, `product`, `marketing` and `researcher` have **no Bash**. They cannot `git clone`,
`git commit`, `git push`, `gh pr create`, or run `npm test` / a validator / a lint. They can Read,
Grep, Glob, Write, Edit and WebFetch, and that is all.

This was dispatched wrong **twice in one session**, the second time after the lesson was already
available: one brief said "open a PR against main"; another said, in as many words, "You have a
shell — use it." Both agents did excellent work, staged it in a worktree, and reported that they
could not deliver it. Project Control then had to land it by hand — which is fine once and is
waste twice.

So, before writing a brief:
- If the deliverable is **a PR, a commit, or a passing test run**, the agent needs `engineer`,
  `qa`, `librarian`, or `general-purpose`.
- If you use a no-shell type deliberately, **say so in the brief** and tell it where to stage its
  output and that Project Control will commit — do not ask it to verify anything by execution.
- Never write "run X" in a brief without checking that the type can.

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

Files you own / files owned by others:
Reserved ids:                  # decision-id range, migration prefix, scratchpad subdir
Rebase, don't merge — main moves under you; commit early, a worktree is not guaranteed
exclusive and uncommitted work has been wiped by an outside reset.

Contract: .ai/protocol/worker-contract.md. Finish with /finish-work.
Everything else: DO NOT LOAD.
```
