---
name: finish-work
description: >
  End a unit of work the Project Control way: verify against invalidations, then
  produce a Change Envelope — the structured transaction commit every worker owes
  the system. Use this whenever a task is completed, blocked, abandoned, or handed
  back for ANY reason, and whenever an agent is about to say "done", "finished",
  or "implemented". A completion without an envelope is invalid in this project.
---

# /finish-work

Run by the worker (subagent or main session) at the end of a leased task. The
envelope, not the diff, is what the rest of the system consumes — an envelope that
under-reports impact is worse than late work, because it lets other agents build on
assumptions you just broke.

## Procedure

1. **Check invalidations first.** Read `.ai/invalidations/` for notices addressed to
   your lease or work item. For each: read the referenced authoritative state,
   re-evaluate your work against it, adjust if needed, and record the INV id plus
   what changed (or why nothing did) in your envelope.

2. **Check for drift.** Compare your lease's `context_version` to the current value
   in `.ai/state/current.md`. If it moved, list the decisions added to
   `.ai/decisions/active/` since you started and confirm none contradict your work;
   note in the envelope which you reviewed.

3. **Verify — and separate what you EXECUTED from what you ASSERTED.**
   Run the checks appropriate to **your role and your tools**. Record commands and
   results. If verification fails and you can't fix it in scope, the envelope status is
   `partial` or `blocked` — never `completed`.

   **A green suite is not evidence your change works.** Where it applies, mutate the fix
   back and watch the test go red — a test that passes with and without your change is
   testing nothing, and this is the most common way work "verified" by a worker turns out
   not to be.

   **Where it applies**, because stated as "always" it is wrong more often than right:
   - **Behavioural fixes and new guards** — yes, and this is the case it was learned on.
     Remove the clamp and watch the leak; drop the constraint and watch both rows land.
   - **Refactors** — no. Behaviour is unchanged by definition, so mutating back leaves
     everything green. The control is the opposite claim: the suite passes **unchanged**,
     and you say which suite.
   - **Deletions and cleanup** — no. "Mutate it back" means restoring the thing you were
     asked to remove.
   - **Config bumps, dependency upgrades, docs, research** — usually nothing to mutate.
     Say what you did instead; do not manufacture a control.
   - **Timing, flakiness and performance** — a mutation can pass by luck. Do not report a
     lucky run as a control.

   **Mutate safely, and this is not optional.** Commit or stash your real work FIRST,
   mutate in a scratch copy, and never leave a mutation staged. In this system a
   mutation-test revert was once swept into a peer's commit, reinstating a claim another
   agent had deliberately deleted for legal reasons. Reverting a security fix, even for
   ten seconds, puts the vulnerability in a tree someone else may be reading.

   **Write `not_proven` entries, in the envelope's own field, for anything you did not
   run.** Not "should work", not silence. A scaffold that typechecks is not a running app;
   reading SQL is not executing it. **`not_proven` is not failure** — a role with no shell
   is expected to have entries there and still file `completed`, because it verified
   everything its tools allow. Naming the gap lets Project Control decide whether to close
   it; hiding it means the first person to find out is a customer.

4. **Report what the brief got wrong — don't re-litigate the ticket.**
   You checked the brief's load-bearing claims before building (worker contract, step 3).
   Anything that turned out false goes in `brief_corrections`, quoted, with what is
   actually true and how you know.

   **This is a REPORT, not a mandate to rebuild.** Rule 2 of the contract still holds:
   stay inside your task scope. If the correction is small enough that building against
   reality is obviously right, do it and say so. If it changes what the ticket is for,
   **raise a `blocking` question instead and stop** — that is what the mechanism is for,
   and it is cheaper than delivering something nobody asked for.

5. **Write the envelope.** Fill `.ai/schemas/change-envelope.yaml` completely.
   Discipline points, because these fields are the whole system:
   - `changes.behavior` and `changes.interfaces`: state externally visible changes
     plainly, as claims a QA agent could test.
   - `assumptions_invalidated`: what was true before your work that is not true now.
     This drives context invalidation for everyone else — think hard here.
   - `affected_work`: grep the work index for items sharing your `touches` concepts
     and sort them into `confirmed` vs `possible`. Empty means you checked and found
     none, not that you didn't look.
   - `decisions_created`: any choice you made that constrains future work, as a
     proposal in decision-schema shape.
   - `questions`: everything you'd otherwise ask the human, each marked `blocking`
     or `assumption` (with the assumption you proceeded under).
   - `cleanup`: artifacts your change just obsoleted, named specifically.
   - `discovered_work`: adjacent work you noticed and correctly did not do.

6. **Commit the envelope.** Write it to
   `.ai/envelopes/pending/<work-item>--<UTC timestamp, e.g. 2026-08-28T14-10Z>.yaml`.
   This is the only `.ai/` write a worker ever makes.

7. **Return it.** Your final message is the envelope path + the envelope content +
   one line flagging anything urgent (blocking question, failed verification,
   invalidated assumption with in-flight victims). Do not summarize away the
   structure — Project Control reconciles from it.

## Hard rules

- `not_proven` entries do NOT make an envelope `partial`. A role with no shell files
  `completed` with what it could not run named honestly. `partial` means a check that was
  available to you failed or was skipped.

- Never mark the work item done, release your own lease, or edit
  `.ai/state/` / `.ai/decisions/` — that is `/reconcile`'s job.
- `status: completed` requires that every check available to YOUR ROLE passed, and
  zero unprocessed
  invalidations addressed to you.
- If you truly changed nothing (research, review), the envelope still exists —
  with empty change sections and its findings in `summary`/`questions`.
