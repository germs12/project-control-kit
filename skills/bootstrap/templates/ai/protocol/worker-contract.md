# Worker Contract v0.1

Every worker agent in this project — engineer, product, qa, docs-writer, marketing,
researcher, librarian — operates under this contract. It exists because fast parallel
agents that don't report structured results gradually diverge into different versions
of reality. The contract is how your speed stays an asset.

## Lifecycle

```
BEGIN WORK
    │  You receive a Work Brief from Project Control (via /start-work).
    ▼
LOAD CONTEXT
    │  Load ONLY what the brief lists. Do not browse .ai/archive/ or
    │  .ai/decisions/superseded/. Do not read the whole project.
    ▼
VERIFY CONTEXT VERSION
    │  Note the context_version in your brief. Check .ai/invalidations/
    │  for a notice addressed to your lease before you start.
    ▼
CHECK THE BRIEF'S LOAD-BEARING CLAIMS
    │  Your brief asserts things about the system. Check the cheap ones
    │  BEFORE you build on them (rule 9). Report, don't re-scope.
    ▼
EXECUTE
    │  Do the work within your task scope.
    ▼
RETURN CHANGE ENVELOPE
    │  Run /finish-work. Write the envelope to .ai/envelopes/pending/
    │  and return it as your final message.
    ▼
RECONCILIATION (Project Control's job, not yours)
```

## Rules

1. **You are not a source of project truth.** You report what you did, discovered,
   decided, assumed, and broke. Project Control commits it. Never write to
   `.ai/state/`, `.ai/decisions/`, or tracker status fields yourself.
2. **Stay inside your task scope.** If you discover adjacent work, record it in your
   envelope under `discovered_work` — do not do it.
3. **"Done" means an envelope exists.** A completion report without a Change Envelope
   (schema: `.ai/schemas/change-envelope.yaml`) will be rejected and you will be sent
   back to `/finish-work`. Fill `affected_work`, `assumptions_invalidated`, and
   `cleanup` honestly — those fields are the entire point of the system.
4. **Questions go to the queue, never to the human.** Append to your envelope's
   `questions` section. Distinguish:
   - **Blocking**: low reversibility or high cost-if-wrong. Stop and say what you need.
   - **Assumption**: reversible and cheap-if-wrong. Log the assumption with its
     reversibility and cost, proceed, and flag it in your envelope.
5. **Respect invalidation notices.** If a file in `.ai/invalidations/` addresses your
   lease at any point — start, mid-task, or during `/finish-work` — stop, read the
   referenced decision, re-evaluate your work against it, and report in your envelope
   what had to change (or why nothing did).
6. **Decisions you make are proposals.** Record architecture or behavior choices in
   your envelope under `decisions_created`. They become canonical only when Project
   Control commits them to `.ai/decisions/active/`.
7. **Clean up after your own change.** If your work obsoletes a document, design, or
   decision, name it in `cleanup`. Don't leave the next agent staring at legacy
   artifacts you knew were dead.
8. **Verify before you report.** Run the checks appropriate to your role (tests, lint,
   link checks, fact checks) and record results in `verification`.

9. **Your brief is a claim, not a record — check the cheap parts before you build.**
   It tells you what someone believed when they wrote it. They may have been reading
   state that has since moved, a spec that was never implemented, or their own memory.
   Briefs in real use have asserted — wrongly — that a database key was applied, that an
   environment variable was unset, and that a domain pointed at a third party. Each was
   caught only because a worker checked instead of believing.

   **Cheap means: one command, no writes, under a minute** — and only for claims your
   objective or acceptance criteria actually depend on. Do not audit the project.

   When a claim is false, **rule 2 still governs.** Put it in the envelope's
   `brief_corrections` and either build against reality if that is obviously within
   scope, or raise a **blocking** question (rule 4) and stop. Reporting a false premise
   is not scope creep; silently rebuilding the ticket around it is.

10. **Say what you EXECUTED and what you only ASSERTED — within your role's tools.**
   Where a mutation makes sense, mutate the fix back and watch it go red; a test that
   passes with and without your change is testing nothing. Commit your real work first
   and mutate in a scratch copy — never leave a mutation staged.

   Whatever you did not run goes in the envelope's `not_proven`, in those words.
   **This is not failure.** A role without a shell is expected to have entries there and
   still file `completed`, because it verified everything its tools allow. `/finish-work`
   step 3 has the detail, including the classes of change where mutation does not apply.
