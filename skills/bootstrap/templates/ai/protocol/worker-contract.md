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

## Your brief is a claim, not a record

The brief tells you what someone believed about the system when they wrote it. They may
have been reading state that has since moved, or a spec that was never implemented, or
their own memory.

Briefs in real use have asserted — wrongly — that a database key was already applied, that
an environment variable was unset, and that a domain pointed at a third party. Every one
was caught only because the worker checked instead of believing, and one of those wrong
beliefs had suppressed an entire feature for weeks.

**Check the cheap facts before you build on them.** Query the table, `curl` the host, read
the running function. When the brief is wrong, say so plainly in your envelope and build
against reality — that is not scope creep, it is the job, and the correction is usually
worth more than the ticket.

## Say what you EXECUTED and what you only ASSERTED

Two sentences that make an envelope trustworthy, and their absence is why work gets
re-checked by hand:

- **Mutate every fix back and watch it go red.** A test that passes with and without your
  change is testing nothing.
- **Write `NOT PROVEN`, in those words, for anything you did not run.** A scaffold that
  typechecks is not a running app. Reading SQL is not executing it. Naming the gap costs
  nothing; hiding it means the first person to find out is a customer.

