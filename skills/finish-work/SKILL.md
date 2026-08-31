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

3. **Verify.** Run the checks appropriate to the work (tests, lint, typecheck, link
   checks, fact checks). Record commands and results. If verification fails and you
   can't fix it in scope, the envelope status is `partial` or `blocked` — never
   `completed`.

4. **Write the envelope.** Fill `.ai/schemas/change-envelope.yaml` completely.
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

5. **Commit the envelope.** Write it to
   `.ai/envelopes/pending/<work-item>--<UTC timestamp, e.g. 2026-08-28T14-10Z>.yaml`.
   This is the only `.ai/` write a worker ever makes.

6. **Return it.** Your final message is the envelope path + the envelope content +
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
