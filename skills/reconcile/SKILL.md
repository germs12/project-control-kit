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

3. **Commit decisions — and assign their ids yourself.** A proposed id is a worker's
   guess, not an address. **Before writing any decision file, collect the proposed ids
   across ALL pending envelopes and look for duplicates.** Parallel workers each read the
   highest id in use and pick the next, so simultaneous dispatch reliably produces two
   different decisions under one id; this has happened four times in a single session
   (`DATA-005`, `OPS-005`, `SITE-007`, `BRAND-004`/`BRAND-005`). Renumber by proposal
   order, and grep the envelopes, PR bodies and commit messages for the id you moved —
   workers cite these in prose. Two records under one id is how the next agent reads the
   wrong one.
   Then, for each entry in `decisions_created` you accept on the project's behalf
   (low-risk, consistent with priorities): write it to
   `.ai/decisions/active/<ID>.yaml` per the decision schema, with `affects` holding
   WORK-ITEM ids and nothing else. Anything with security, privacy, financial,
   destructive, or hard-to-reverse consequences goes to the question queue instead, as a
   proposal awaiting the human. For each superseded decision: move its file to
   `.ai/decisions/superseded/`, set `status: superseded`, and grep active state, docs and
   work items for references — each becomes an update (now) or a work item (if
   substantive). Two live decisions on one topic is the same defect as two under one id:
   supersede, don't stack.

4. **Read the envelope's `not_proven` and `brief_corrections` before you believe it.**
   - `not_proven` lists what the worker did NOT execute. It is neither pass nor fail, so
     it does not by itself block `done` — but **you** decide whether each entry can close.
     Where the consequence is security, money, or another tenant's data, confirm it
     against the running system before writing `done`, per the rule further down this
     file. Anything you cannot close becomes a work item, not a shrug.
   - `brief_corrections` lists claims the BRIEF made that turned out false. Treat each as
     an `assumptions_invalidated` entry for impact purposes: the wrong belief is probably
     also in a spec, a decision record, or the next brief. **Fix it at the source in this
     same reconcile** — a correction that stays in one envelope reaches nobody, which is
     how a false belief survives for weeks.

5. **Propagate impact.** Run the `/impact` procedure over `changes.behavior`,
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

6. **Documentation.** For each `documentation_impacts` entry: fix trivially small
   ones now; otherwise create/refresh a DOC work item naming exactly what must change.

7. **Cleanup & discovery.** Execute `cleanup`: move obsoleted artifacts to
   `.ai/archive/` (mirroring their path) — archive, don't delete. Create work items
   from `discovered_work` with suggested priorities.

8. **Questions.** Append the envelope's `questions` to `.ai/state/questions.yaml`
   (assign Q ids). If any is blocking, or three or more are open, run `/questions`
   to refresh the inbox.

9. **Close the transaction.**
   - Set the work item's status from the envelope (`done` for completed, etc.).
   - Release the lease (`state: released`) and archive acknowledged invalidations.
   - Move the envelope to `.ai/envelopes/processed/`.
   - Increment `context_version` in `.ai/state/current.md`, update its `updated`
     stamp, and refresh its Focus / In flight / Recently landed / Watchouts sections.
   - Sync the tracker (status, comment linking the envelope) per operations.md.

## A finished worker is not a merged worker — check for unpushed branches

An agent can complete, write a correct envelope, report in full, and have pushed
**nothing**. Its work then exists only in a local worktree, invisible to every check you
run: `main` looks as though the ticket was never done, and a later agent reading the code
will correctly report the feature missing.

This happened. A ticket delivering a whole customer-facing console finished, reported, and
sat unpushed for hours — found only because a docs agent went to describe the change and
could not find it, then said so instead of writing it up from the report.

So at every reconcile, before you believe an envelope:

```
git fetch origin --prune
git branch -r --no-merged main          # remote branches with unmerged work
git worktree list                       # local worktrees an agent may have left behind
```

and for a worker that reports `status: completed`, confirm a PR exists. Worktree isolation
makes this MORE likely, not less: an isolated agent gets a fresh worktree and no upstream,
so pushing is a step it must take deliberately.

Corollary worth stating because it inverts an instinct: **an artifact absent from `main` is
not evidence the work was not done.** Check the branches before you conclude anything from
the tree.

## Open the PR when you dispatch, not when the worker returns

Project Control orphans its own commits by re-pointing a branch out from under them. The shape is
always the same: create `chore/dispatch-X`, register the work item and lease, `git push`, dispatch
the worker, then `git checkout -B <next-branch> origin/main` for the next thing — and the
registration never reaches `main`. The worker runs, finishes, and opens a PR for a ticket that
project state has no record of, holding a lease nobody can see.

This happened THREE TIMES in one session. Twice it was caught by `/health` reporting
`decision X affects unknown work item Y`; once by a worker reporting that the decisions its brief
cited did not exist on disk. Each recovery meant `git log --all --grep`, finding the orphan, and
re-applying it by hand onto the current base.

The fix is one step and it costs nothing: **open the pull request immediately after the dispatch
push** — `gh pr create`, `glab mr create`, whatever this repo uses —
before invoking the worker. A state-only PR merges in minutes and the registration is on `main`
before the worker's first commit. If a dispatch is genuinely too small for its own PR, fold it into
the reconcile branch you are already going to open — but never leave it on a branch you are about
to abandon.

Corollary: `git branch -r --no-merged main` at every reconcile catches these, but only if you look
at the `chore/*` branches too, not just the feature ones.

## Audit a branch with three dots, never two

`git diff origin/main..HEAD` compares TIPS. In a session where the integration branch moves
under everyone, that renders "main has commits I don't" as "this branch reverts them" — so
a contamination audit accuses workers of deleting whatever landed after their base.

It nearly produced a false p0: an audit appeared to show a worker reverting a resolver fix
and deleting 89 lines of guards, which is the exact defect class that cycle was fixing. The
worker was clean; main had simply moved one commit.

Use `origin/main...HEAD` (three dots) or `git diff $(git merge-base HEAD origin/main)..HEAD`.
`git merge-base` and `git log HEAD..origin/main` each settle it in one command.

## Never `git add -A` as Project Control

Stage the paths you changed, by name. `git add -A` sweeps whatever else is in the tree,
and as Project Control your tree is the one place other agents' files land — because
workers write into it by mistake, and because you check files out of their branches to
inspect or apply them. It has gone wrong three times in one session:

- an agent's half-finished feature was committed into an unrelated PR and broke its build;
- a migration checked out solely to apply it to production rode along into a Project
  Control commit, and the schema-drift proof failed because the matching type changes were
  still on the author's branch;
- a rescued branch had to be reconstructed afterwards to give the author their work back.

Two habits that cost nothing:
- `git status --short` before every commit, and read it. An unexpected path is a stop.
- `git show --stat HEAD` after, against what you meant to change. A file you cannot
  explain is somebody else's.

And check which branch you are on first. A worker that ran in your worktree may have left
it on **their** branch, so `git status`, `git ls-tree HEAD` and a bare `git log` are all
answering about their work, not yours. Inspect a branch you are not on with
`git ls-tree <branch>` / `git show <branch>:<path>` rather than checking it out, and if you
must edit it while an agent is live, do it in a scratch `git worktree` and remove it after.

## Never let a write silently resolve a collision

Registering a work item, a decision or a lease is an INSERT, not an upsert. If the id is
already taken, **stop and renumber** — never overwrite, and never "de-duplicate" by
keeping one block and dropping the other. A reconcile did exactly that: a new hygiene
ticket was registered over an existing `HYG-1`, a tidy-up pass kept the newer block, and a
real work item tracking nine unimported tracker issues vanished from the index with nothing
pointing at the hole. It was found only because a librarian diffed the index against the
previous commit.

Two habits that would have caught it, and both are cheap:
- Before writing, read the ids already present and assert yours is absent. A script that
  appends must fail loudly on a duplicate, not reconcile it.
- After writing, diff the item count and the id set against the previous commit. An id
  that DISAPPEARED is always a defect; an id that appeared is the intended change.

Keep `next_id` counters honest at the same time. Leases minted across sessions drift, and
a stale `next_id` mints a duplicate on the very next dispatch.

## Write the decisions BEFORE you move the envelope

Step 3 says write each accepted decision to `.ai/decisions/active/`. Step 8 says move the
envelope to `.ai/envelopes/processed/`. **Doing 8 without 3 is silent and total.** The envelope
looks done, the work item says done, the PR is merged — and the reasoning is gone. Nobody
notices until an id someone cited turns out to point at nothing, which can be weeks.

It happened **45 times across 18 envelopes** in a single project. Two of those ids had already
shipped in code and one was inside the `raise` message of a migration running in production.

Recovery is possible but expensive, and it has a trap: the originals are still sitting in the
processed envelope's `decisions_created`, so **look there before reconstructing anything**. A
record reconstructed from the places that cite it is usually WRONG — a citation names a
decision's CONSEQUENCE, not the decision. In one recovery, three of four ids would have been
reconstructed as the wrong rule, and you cannot tell which kind you have until you find the
original.

So: **write the files, verify they exist, and only then move the envelope.** In one command:

```
ls .ai/decisions/active/ | grep -E '<the ids you just accepted>'
```

`/health` now checks both halves of this — every processed envelope's proposals resolve to a
file, and every decision id cited in the source tree resolves to a record. Run it after every
reconcile, not just when something feels wrong.

## An id you cited is an id you owe

Project Control creates its own id debt. If you name a decision in a commit message, a PR
title or a brief — `fix(book): … (BOOK-011)` — the record must exist by the end of the
same reconcile. A merged PR citing an id with no file behind it is worse than no citation:
the next worker greps for it, finds nothing, and either invents a meaning or picks the
number for something else. It has happened; a worker noticed the gap and routed around it
rather than colliding, which is luck, not a system.

Same rule for merge order. When two in-flight branches touch one generated or shared file
(`types/database.ts` is the recurring case), merge them in a deliberate order and TELL the
later one its file moved. Do not let the second discover it as a conflict.

## If merging deploys, the schema change goes first — and it is YOURS to apply

Project Control owns this, not the worker. `operations.md`'s single-writer rule already
says external writes happen only in `/reconcile` and `/bootstrap`, and applying a schema
change to a live system is the most consequential external write there is. A worker
authors the migration inside its lease; **you apply it.** Two engineers with disjoint
reserved filename prefixes still share one database — prefix reservation coordinates
names, not application.

**Find out whether merging deploys, cheaply and once.** Read the CI configuration for a
job triggered by a push to the default branch; if the platform exposes a deployment list,
compare the last few deploy times against the merges above them. Record the answer in
`PROJECT.md` so nobody re-derives it. Two published documents disagreeing about this is
common — prefer what the pipeline actually does.

If merging deploys, then **apply the schema change before you merge the code that reads
it.** Otherwise you ship a product that queries a column which does not exist, in the
window before anyone looks.

Three habits, none of them stack-specific:

- **Count before you destroy.** A migration that deletes rows with no resolvable parent
  gets run against a count first. One such delete turned out to affect zero rows — which
  is what made it safe, and was not knowable without asking.
- **Confirm by reading the system's own catalog**, not by trusting the tool's success
  response. Ask the database (or the service) what it now contains.
- **Audit drift in both directions, periodically.** A table-level comparison cannot see a
  migration that only adds a function, a constraint or a policy. In one project three
  migrations had never been applied, two of them invisible to a table diff, and one would
  have refused every login the moment a dependent ticket merged.

## Adversarially review a PR before you merge it — the author cannot do this

Self-review has a ceiling and it is low. Measured on one project: the coordinator reviewing
its own two PRs found **3** defects; two dispatched adversarial reviewers found **19**,
including one that would have made the system misdetect **every repo it already ran on**. The
author had read the same files an hour earlier and could not see it.

**Dispatch a reviewer whose brief says REFUTE, not check.** The wording does the work — "review
this PR" produces confirmation; "try to prove this is wrong, and report what it costs a user"
produces defects. Require:

- **defects ranked by what they cost a user**, each with a concrete failure scenario — what a
  reader does and what goes wrong — not a preference;
- **a defect distinguished from a nit**, defects first. A review that buries one real defect
  under nine style notes has failed;
- **the exact line quoted**;
- **"I found nothing" allowed, but only with what was tried** — and said up front to be the
  less likely outcome, which stops the reviewer optimising for agreement.

**Name the attack you most fear.** On one PR the sharpest finding came from an instruction to
press a specific worry — *"this traded concreteness for genericity; argue it made the skill
worse"* — which the reviewer then partly confirmed and partly refuted, and that was more
useful than either verdict alone.

**When to spend it.** Not every PR. Spend it when the change touches money, auth, tenancy or a
public claim; when it changes a contract other work is built on; or when it is big enough that
you skimmed it. A state-only reconcile does not need one.

**Then fix rather than defend.** If the review lands, the PR was not ready — say so in the PR
and rework it. Merging a reviewed-but-unfixed PR is worse than never reviewing, because the
defects are now documented *and* shipped.

## Before you record a defect as closed

A fix reported as shipped is a claim, not a record. Where an envelope says a defect is
closed and the consequence is security, money, or another tenant's data, confirm it
against the running system before writing `done` — query production for the property the
fix asserts, or run the executable proof. A migration once shipped, was reported as
closing a privilege-escalation hole, and closed nothing, because the trigger it
strengthened had been dead for months. Project state was then updated to say it was fixed.
That correction is expensive precisely because state is what everyone else reads.

## After all envelopes

Recalculate blockers against `.ai/state/dependencies.yaml` and priorities; then
report: envelopes processed, decisions committed/superseded, items updated by status
class, invalidations issued, questions queued, cleanup done, and what is now
dispatchable. If anything is dispatchable and non-conflicting, offer to
`/start-work` it.
