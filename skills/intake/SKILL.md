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

## 1. Get text

- Transcript file, notes, or pasted text → use directly.
- Audio (.m4a / .mp3 / .wav) → look for a sidecar transcript first (Voice Memos
  on recent iOS/macOS produces one you can export). Otherwise transcribe
  locally, e.g. `whisper <file> --model medium.en --output_format txt`
  (`pip install openai-whisper` + ffmpeg, or whisper.cpp on Apple Silicon).
  Ask before installing anything. Never commit the audio binary to git.

## 2. Distill — extract with provenance

Read the whole transcript, then pull out, each with a short supporting quote or
timestamp:

- **Settled decisions** — things the participants actually agreed on.
- **Unsettled debates and open questions** — including suggestions that got no
  clear yes.
- **Action items, feature ideas, bugs** — with an owner when one was named.
- **Constraint or direction changes** — deadlines, scope cuts, priority shifts.
- **Contradictions** with the project's existing decisions or docs — flag
  explicitly ("this conversation may supersede X"). Never silently override.

Attribute carefully: "Sam suggested X" is not "we decided X." When the
transcript is ambiguous about whether something was decided, it is a question,
not a decision.

## 3. Confirm with the human

Present the distillation as one table — decisions / action items / questions /
changes / conflicts — each row carrying its quote. The human strikes, edits,
and promotes rows (question → decision) before anything commits. The person who
was in the room is authoritative over the transcript.

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
questions / Notable context sections, each entry attributed and quoted. Then
offer — don't assume — to also file action items where the project tracks work:
GitHub issues via `gh` if authenticated, an existing `TODO.md`, or the user's
tracker of choice.

## 5. Archive the raw material

Save the transcript to `intake/transcripts/<YYYY-MM-DD>-<slug>.txt` (Project
Control mode: `.ai/archive/intake/`) with a header listing every record it
produced, and point each record back at it. If it shouldn't live in git —
sensitive content, other people's words in a repo that might be shared — keep
it out and record a local path instead; provenance can be a pointer.

## Hard rules

- Raw transcripts never enter active working context; the project consumes the
  distilled records. Future work cites the decision, not minute 34 of the call.
- Nothing commits without human confirmation. Intake distills; humans decide.
- Zero-yield intake is legitimate: if a conversation produced nothing
  actionable, archive it, say so, and stop.
