---
name: bootstrap
description: >
  First-run setup for Project Control in a repository: scan the repo, draft
  PROJECT.md, detect connected tools, propose workstreams and priorities, import
  or seed initial work items, and set context_version to 1. Use when PROJECT.md is
  still a template, when the user says "bootstrap", "set this project up", or
  "point project control at this repo" — and whenever any skill notices the
  project has never been bootstrapped.
disable-model-invocation: false
---

# /bootstrap

Run as Project Control. Bootstrap is the one time you read broadly — after this,
everyone works from slices. It's also collaborative: you draft, the human confirms.
Everything you write here is ordinary state that `/reconcile` maintains afterward.

## Procedure

0. **Scaffold if needed.** If the repo has no `.ai/` directory, create the data
   plane first from this skill's bundled templates: copy `templates/ai/` (which
   sits alongside this SKILL.md — in plugin installs, under the plugin's
   directory) to `.ai/` in the repo root, without overwriting anything that
   exists. Then ensure `CLAUDE.md` at the repo root contains the kit's managed
   block (`pc-kit:begin` … `pc-kit:end`): create the file from
   `templates/CLAUDE.md` if absent, append the block if the file exists without
   it, leave it alone if the block is already there. Tell the human what was
   scaffolded and remind them to commit `.ai/` — state travels with the repo.

1. **Scan the repo.** README and docs; manifests (package.json, pyproject.toml,
   Gemfile, go.mod, Cargo.toml...); top-level structure; recent `git log` for what's
   actively changing; CI config; existing TODO/FIXME density. Goal: what is this,
   who is it for, what stack, what state is it in. Minutes, not an archaeology dig.

2. **Detect adapters** per `.ai/protocol/operations.md`: `gh auth status` for
   GitHub (note the remote's owner/repo); look for Linear and Slack MCP tools.
   Record what's connected in PROJECT.md's canonical-information section.

3. **Draft PROJECT.md** — the 30-60-second version. One paragraph of what we're
   building; who it's for; 3-5 "what currently matters" bullets; hard architectural
   constraints only; where canonical information lives; the before-modifying-anything
   pointer. If who-it's-for or current goals aren't inferable, draft your best guess
   and mark each guess — they become bootstrap questions, not silent fabrications.

4. **Propose workstreams.** Start from `.ai/state/workstreams.yaml` defaults; drop
   what this project clearly doesn't need yet, and say why.

5. **Seed work items.** Sources, in order: open GitHub issues (`gh issue list`) or
   Linear issues → import with `external_ref`; TODO/FIXME clusters worth tracking;
   obvious gaps you found (no tests, no CI, stale README). For each: schema-complete
   entry with honest `touches` and a suggested priority. Cap the initial import at
   ~25 items; note the remainder as a follow-up HYG item rather than flooding the
   index.

6. **Seed priorities and current.md.** Draft `priorities.yaml` (≤5 entries) from
   the human's stated goals plus what you found; fill current.md's Focus section;
   set `context_version: 1` and the `updated` stamp.

7. **Open bootstrap questions.** Anything you guessed in steps 3-6 becomes a
   question via the question schema (kind per the usual reversibility × cost test —
   most bootstrap guesses are `assumption`). Render `/questions`.

8. **Confirm with the human.** Present: PROJECT.md draft, workstreams kept/dropped,
   seeded items table (id, title, priority, source), priorities, and the inbox.
   Apply their edits, then run `/health` as a smoke test and `/status` as the first
   briefing.

## Hard rules

- Bootstrap writes state; it does not start work. Dispatching the first item goes
  through `/start-work` like everything else.
- Never fabricate project intent. A wrong-but-confident PROJECT.md poisons every
  context slice that follows; a marked guess costs the human one inbox answer.
- Re-running bootstrap on a live project is a merge, not a reset: propose diffs to
  existing state, never overwrite decisions, items, or history.
