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
   Run the checks appropriate to the work (tests, lint, typecheck, link checks, fact
   checks). Record commands and results. If verification fails and you can't fix it in
   scope, the envelope status is `partial` or `blocked` — never `completed`.

   Three disciplines make the difference between an envelope that is trusted and one
   that is re-checked by hand:

   - **A green suite is not evidence your change works.** Mutate the fix back and watch
     the test go red. A test that passes both with and without your change is testing
     nothing, and this is the single most common way work "verified" by a worker turns
     out not to be. Every behaviour you claim gets a negative control: remove the guard
     and watch the leak; drop the constraint and watch both rows land; point the resolver
     at the wrong implementation and watch it caught.
   - **Say `NOT PROVEN`, in those words, for anything you did not execute.** Not "should
     work", not silence. A scaffold that typechecks is not a running app; a bundle that
     compiles is not a launched one; reading SQL is not running it. Naming the gap costs
     you nothing and lets Project Control decide whether to close it — hiding it means
     the first person to find out is a customer.
   - **A ratchet nobody has watched fire is indistinguishable from one that cannot.**
     If you add a guard, break something on purpose and show it catching that.

4. **Verify the BRIEF, not just the work.** Your brief is a claim about the system, not
   a record of it. It was written by someone reading state that may have moved, or a
   spec that was never implemented, or their own memory.

   In one project, briefs asserted — wrongly — that a database key was already applied,
   that an environment variable was unset, and that a domain pointed at a third party.
   Each was caught only because the worker checked instead of believing, and one of those
   wrong beliefs had suppressed an entire feature for weeks. In each case the correction
   was worth more than the ticket.

   So: **cheap facts get checked.** Query the table, `curl` the host, read the running
   function — before you build on the claim, not after. When you find the brief wrong,
   say so plainly in the envelope and build against reality; that is not scope creep, it
   is the job.

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

- Never mark the work item done, release your own lease, or edit
  `.ai/state/` / `.ai/decisions/` — that is `/reconcile`'s job.
- `status: completed` requires passing verification AND zero unprocessed
  invalidations addressed to you.
- If you truly changed nothing (research, review), the envelope still exists —
  with empty change sections and its findings in `summary`/`questions`.
