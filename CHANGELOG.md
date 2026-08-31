# Changelog

## 0.2.0 — first public release

- `/intake` skill: ingest audio recordings, transcripts, and notes into project
  state — local Whisper transcription, attribution discipline ("suggested" ≠
  "decided"), human confirmation gate, provenance archive. Dual-mode: full
  Project Control pipeline, or standalone dated records + optional GitHub issues.
- Plugin + marketplace packaging (`/plugin marketplace add germs12/project-control-kit`)
- `/bootstrap` now self-scaffolds the `.ai/` data plane and CLAUDE.md managed
  block from bundled templates, making plugin installs self-sufficient
- Example transcript fixture with expected distillation (regression prose-tests)
- CI validation workflow; MIT license; contribution guide

## 0.1.0 — initial kit

- Project Control constitution + worker contract + tool-agnostic operations layer
- 7 worker agents; 8 skills (bootstrap, start-work, finish-work, reconcile,
  impact, questions, health, status)
- 6 schemas: Decision, WorkItem, ChangeEnvelope, Question, Lease,
  ContextInvalidation
- `.ai/` data plane; no-clobber installer
