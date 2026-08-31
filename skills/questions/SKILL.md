---
name: questions
description: >
  Maintain the single Human Decision Inbox: deduplicate and merge agent questions,
  render them as concise decisions with options and recommendations, and process
  the human's answers into decision records that propagate. Use whenever questions
  accumulate in state, when a blocking question appears, when the user asks "what
  do you need from me / what's waiting on me", and after the user answers anything
  from the inbox. Agents never ask the human directly — everything flows through here.
---

# /questions

Run as Project Control. This skill optimizes human attention, not agent autonomy:
four agents with four phrasings of one underlying decision must reach the human as
one question, answered once, propagated four times.

## Render mode (default)

1. **Load** `.ai/state/questions.yaml` plus `questions` sections of any envelopes
   still in `.ai/envelopes/pending/`.

2. **Merge.** Group open questions that hinge on the same underlying decision, even
   when phrased differently ("can orgs have aliases?" and "are email domains
   unique?" are both domain-ownership). Keep one canonical question; mark the rest
   `merged_into:<id>`; union their `affected_work` and `blocking` lists.

3. **Triage kind.** For each canonical question, judge reversibility × cost-if-wrong:
   - cheap and reversible → `assumption`: draft the assumption (A-id, text,
     reversibility, cost), attach it, and let work proceed — the inbox entry becomes
     FYI-with-override rather than a blocker;
   - security, privacy, financial, destructive, contractual, or hard-to-reverse →
     `blocking`, regardless of how confident the recommendation feels.

4. **Recommend.** Give each question 2-4 real options and mark a recommendation
   when one can responsibly be given, with a one-line reason. If no responsible
   recommendation exists, say so — that itself is information.

5. **Render `.ai/INBOX.md`**, blocking first:

```
QUESTION Q-81 — Organization domain ownership          [BLOCKING]

Four active work items need a decision about how domains map to organizations.

  A. One domain per organization
  B. Multiple domains; globally unique ownership   [recommended — matches AUTH-014
     org model; keeps verification simple]
  C. Multiple domains; overlapping ownership

Affected: ENG-41 ENG-52 ENG-61 DOC-19     Blocked: ENG-52 ENG-61
Cost of delay: org onboarding design frozen.

Answer with: Q-81: B   (or B + notes)
```

   Assumption-kind entries render with `Proceeding under A-<id>: <text> — override
   any time.` Then tell the user, in one line, how many decisions await and how
   many items are blocked.

## Answer mode

When the human answers (inline in INBOX.md or in chat):

1. Record the answer in `questions.yaml` (`answer`, `status: answered`).
2. Create the resulting decision record in `.ai/decisions/active/` per the decision
   schema (`decided_by: human`), superseding as needed; link it via
   `resulting_decision`.
3. Confirm or retire affected assumptions; an overridden assumption is treated as an
   invalidated assumption.
4. Run `/impact` on the new decision — in-flight work that assumed differently gets
   invalidation notices; queued work gets updated via `/reconcile`.
5. Re-render the inbox and report what just unblocked.

One human interaction, N agents updated. That is the contract.
