---
name: intake
description: >
  Turn raw human input — meeting audio recordings (transcribed first), meeting
  transcripts, voice notes, pasted brainstorms, email threads, chat dumps — into
  project state: decisions, action items, and open questions, with the raw
  material archived as provenance. Use whenever the user wants to "ingest",
  "import", "process", "capture", or "distill" a conversation, meeting,
  recording, or notes into their project — e.g. "here's the recording of our
  roadmap call", "ingest this transcript", "turn my voice memo into tasks".
---

# /intake <path-to-audio-or-transcript | pasted text>

A conversation is deliberation, not truth. The point of intake is that a
forty-minute debate becomes three records and one question, and the transcript
becomes retrievable cold storage nobody has to re-read.

Three kinds of sentence come out of a meeting: what people agreed, what they
argued about, and what they asserted about the world. Only the first can become
a decision. The third is the one that hurts.

## 1. Get text

- Transcript file, notes, or pasted text → use directly.
- Audio (.m4a / .mp3 / .wav) → look for a sidecar transcript first (Voice Memos
  on recent iOS/macOS produces one you can export). Otherwise transcribe
  locally, e.g. `whisper <file> --model medium.en --output_format txt`
  (`pip install openai-whisper` + ffmpeg, or whisper.cpp on Apple Silicon).
  Ask before installing anything. Never commit the audio binary to git.

Check the archive (§5) before you transcribe. The same call arrives twice —
forwarded, re-exported, renamed — and a second ingest of the same material
mints a second set of records for one meeting. If it's already there, say so
and stop. A genuine *follow-up* that covers the same ground is not a duplicate:
ingest it, but where it revisits something already settled that is a supersede
proposal (§4), not a second record on the same topic.

## 2. Distill — extract with provenance

Read the whole transcript, then pull out, each with a short supporting quote or
timestamp:

- **Settled decisions** — things the participants actually agreed on.
- **Unsettled debates and open questions** — including suggestions that got no
  clear yes.
- **Claims about the state of the world** — "that's already deployed", "that
  variable is unset", "that domain points somewhere else". Capture them as
  claims, with the claimant named.
- **Action items, feature ideas, bugs** — with an owner when one was named.
- **Constraint or direction changes** — deadlines, scope cuts, priority shifts.
- **Contradictions** with the project's existing decisions or docs — flag
  explicitly ("this conversation may supersede X"). Never silently override;
  see *Superseding* in §4.

Attribute carefully: "Sam suggested X" is not "we decided X." When the
transcript is ambiguous about whether something was decided, it is a question,
not a decision.

A claim about the world is a **question, or a task to verify** — never a
decision record — until something authoritative confirms it. People are
confidently wrong about their own systems constantly. Verify during intake
while it is cheap: one query, one `curl`, one `grep`. Three of these landed in
a single day's work: a spec asserted a database key was "already applied in
production" and the table still had the old one; a spec asserted an environment
variable was unset when it had been set hours earlier; a note asserted a
customer domain resolved to a third-party host when it actually served the
product — and that last belief had suppressed an entire feature for weeks, on
the reasoning that there was nothing to resolve. Where a claim can't be settled
during intake, the record must say it is unverified and say what would settle
it. A false fact laundered into a decision record is read as truth by everyone
downstream.

## 3. Confirm with the human

Present the distillation as one table — decisions / action items / questions /
claims / changes / conflicts — each row carrying its quote and a row number the
human can answer against ("D1 and A2 yes, C1 reword"). The human strikes,
edits, and promotes rows (question → decision) before anything commits. The
person who was in the room is authoritative over the transcript.

Partial confirmation is the normal outcome, not a failure. Some rows get
struck, some get edited, and several are simply never mentioned. **A row nobody
addressed is not confirmed.** It goes back to the queue as an open question.
Never read "they didn't object" as "they agreed."

## 4. Commit

Detect the environment and commit accordingly:

**Project Control mode** — if `.ai/protocol/project-control.md` exists (the
[Project Control Kit](https://github.com/germs12)), run its machinery: write
accepted decision records to `.ai/decisions/active/` per its schemas, add work
items to the index with assigned IDs, queue questions for `/questions`, run
`/impact` so in-flight work sharing concepts gets invalidation notices, and
increment `context_version` via `/reconcile`.

**Standalone mode** — otherwise, write one distilled record the project can
keep: `intake/<YYYY-MM-DD>-<slug>.md` with Decisions / Action items / Open
questions / Claims to verify / Notable context sections, each entry attributed
and quoted. Then offer — don't assume — to also file action items wherever this
team already tracks work.

**Find the tracker; don't pick one.** We are helping here, not creating new
workflows and processes. **The procedure lives in one place —
`.ai/protocol/operations.md` § *Finding the tracker*** — so `/bootstrap`, `/reconcile`
and this skill cannot drift into three answers for one repo. Read it there; the short
version is that you check whether it has already been answered, then whether Project
Control's own index IS the tracker, then the evidence, and you **stop at the first step
that answers**.

Two things that bite here specifically: **being on GitHub is not evidence of GitHub
Issues**, and **`#123` in a commit subject is the pull-request number**, so it says
nothing about the tracker.

If the project has no `.ai/` at all — standalone mode — the same ordering applies from
step 2 down, and the distillation file records what you found so a second run reuses it.

Report the evidence, not the conclusion: "recent branches are `eng-*` and commits cite
`ENG-###`, so this looks like Linear — confirm?" can be corrected in one word; "filed 6
issues in GitHub" cannot. **Never create a tracker, and never file the first issue into
one nobody uses.** A wrong guess doesn't misfile a ticket, it starts a parallel system
the team now has to ignore — so when the evidence is thin, say what you found and ask.

Use whatever tooling is already present to
do the filing; intake finds the tracker, it doesn't reimplement it.

Both modes mint ids and cite them. Both modes therefore owe:

**An id is an INSERT, never an upsert.** Before minting one, prove it is free:
check the active records, anything pending, anything already processed, and
`grep -rn "<PREFIX>-0" .` across the source tree — shipped code cites ids in
comments, and an id is taken the moment anything cites it, not when a file
appears. Assert it is absent and fail loudly if it isn't. After writing, diff
the id set against the previous state: **an id that disappeared is always a
defect.** One reserved id turned out to be claimed by an already-processed
record; separately, a de-duplication pass "resolved" a collision by keeping one
block and dropping the other, destroying a live work item that was tracking
nine imported issues. It was caught only because someone diffed the index
against the previous commit.

**An id you cite is an id you owe.** Every id a record or work item references
must exist by the end of the same run. A citation with nothing behind it is
worse than no citation: the next reader greps, finds nothing, and either
invents a meaning or reuses the number for something else. Four such ids
reached shipped code and a live database error message with no record anywhere.

**Never reconstruct a missing decision from the places that cite it.**
Citations point at a decision's consequences, not its rule. A record rebuilt
that way once described a completely different rule from the original, and was
corrected only when the source turned up. Where an artifact states the rule
unambiguously — a database constraint, an error message — you may write from
that, and the record must say it was reconstructed, from what, and what was not
recoverable. Otherwise the honest record is that the rule is unknown.

**Superseding is a move, not a stack.** Propose it explicitly; on acceptance,
move the old record out of the active set, set its status, and grep for every
reference to it — including code comments. Three source comments once went on
describing a superseded rule as live. The code was correct; the comments were
exactly how a future reader reintroduces a dead rule. Two live decisions on one
topic is the same defect as two records under one id.

## 5. Archive the raw material

Save the transcript to `intake/transcripts/<YYYY-MM-DD>-<slug>.txt` (Project
Control mode: `.ai/archive/intake/`) with a header listing every record it
produced, and point each record back at it. Give the header a stable source
line — original filename, date, duration — so §1 can recognise the same
material re-exported under a new name. If it shouldn't live in git — sensitive
content, other people's words in a repo that might be shared — keep it out and
record a local path instead; provenance can be a pointer.

## Hard rules

- Raw transcripts never enter active working context; the project consumes the
  distilled records. Future work cites the decision, not minute 34 of the call.
- A claim about the world is not a decision. Until something authoritative
  confirms it, it is a question or a verification task — and if it reaches a
  record unverified, the record says so.
- Nothing commits without human confirmation, and silence is not confirmation.
  Intake distills; humans decide.
- Use the team's tracker or none at all. Intake never stands up a workflow the
  team didn't already have.
- Zero-yield intake is legitimate: if a conversation produced nothing
  actionable, archive it, say so, and stop.
