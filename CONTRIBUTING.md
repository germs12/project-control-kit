# Contributing

The kit gets better with more real projects thrown at it. Bug reports about
where orchestration *broke* — stale context that slipped through, an envelope
that under-reported, a question that should have been merged — are as valuable
as PRs.

## Dev loop

1. Clone, then install your working copy into a scratch repo:
   `./install.sh /tmp/scratch-project` (any small real repo makes a better test
   than an empty one).
2. `cd /tmp/scratch-project && claude`, run `/bootstrap`, then exercise the
   thing you changed: dispatch with `/start-work`, return an envelope with
   `/finish-work`, `/reconcile`, and finish with `/health` — coherence at 100%
   on a fresh bootstrap is the smoke test.
3. For `/intake` changes, run it against `examples/sample-transcript.md` and
   compare with `examples/expected-output.md`. The fixture is booby-trapped
   with a suggestion that was never agreed to and a joke proposal; if your
   change commits either as a decision, it's a regression.
4. `claude plugin validate .` before opening the PR (CI runs the same checks).

## Load-bearing walls (change these only with a very good argument)

- **Single writer.** Only Project Control writes `.ai/state/`, `.ai/decisions/`,
  and tracker status. Workers write exactly one thing: their envelope.
- **No completion without a Change Envelope.** The envelope, not the diff, is
  what the system consumes.
- **Decisions are immutable records; discussion is disposable.** Supersede,
  never edit; archive, never delete.
- **Reconciliation acts by status class.** Backlog edited before pickup,
  in-flight invalidated immediately, done reviewed for reopen.
- **One human inbox**, merged by underlying decision, with options and a
  recommendation; cheap reversible ambiguity proceeds as a logged assumption.
- **Context slices.** Work Briefs end with `Everything else: DO NOT LOAD.`
- **Intake attribution discipline.** "X suggested" ≠ "we decided"; ambiguity
  becomes a question; humans confirm before anything commits; transcription is
  local-first and audio never gets committed.

## Style

Skills stay under 500 lines, imperative voice, and explain *why* alongside
*what* — future-Claude follows rules better when the rules carry their reasons.
Skills and agents speak tool-agnostic operations
(`skills/bootstrap/templates/ai/protocol/operations.md`); vendor syntax lives
only in the adapter table. Schemas are commented templates with a worked
example — keep both halves updated together.

## Wanted

`/triage`, `/plan`, `/sweep`, `/release` skills · architecture and release
agents · a PreToolUse hook hard-enforcing single-writer · Linear/Slack adapter
columns exercised against the real MCP servers · more intake fixtures
(multi-speaker, rambling, adversarial) · field reports from real projects.

## Submitting

Fork → branch → PR with: what broke or improved, how you exercised it (step 2
or 3 above), a CHANGELOG line, and a version bump in
`.claude-plugin/plugin.json` for user-visible changes.
