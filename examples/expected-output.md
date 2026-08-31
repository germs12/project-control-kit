# Expected distillation — sample-transcript.md

What a correct `/intake` run presents for confirmation (quotes may vary; the
classification must not).

## Decisions (settled)
| # | Decision | Who | Evidence |
|---|---|---|---|
| D1 | Use Postgres for storage, replacing the SQLite prototype | Jordan + Sam | [02:05–02:10] "Let's just do Postgres" / "Agreed. Postgres it is." |

## Action items
| # | Item | Owner | Due | Evidence |
|---|---|---|---|---|
| A1 | Write schema migration script (SQLite → Postgres) | Sam | Friday | [02:10] |

## Constraints / direction
| # | Constraint | Evidence |
|---|---|---|
| C1 | Beta launch is a hard date: October 1 — all work above lands before it | [05:20] "Hard date, I already announced it." |

## Open questions
| # | Question | Why it's a question, not a decision |
|---|---|---|
| Q1 | Pricing: free + one paid, two tiers, or three? | Explicitly parked: "Let's think on it." [06:45] |

## Correctly NOT committed
- **Dark mode** — Sam *suggested* it; Jordan deflected ("let's not open that
  can today"). Suggestion ≠ decision. At most a backlog question, never a
  decision or action item.
- **CLI rename** — flagged as kidding ("Kidding. Sort of."). Too ambiguous to
  commit; acceptable as a low-priority open question, unacceptable as anything
  stronger.

If a change to the skill causes dark mode or the rename to appear under
Decisions or Action items, that change is a regression.
