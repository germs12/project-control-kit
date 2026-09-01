# Project Control Kit

**A small agent operating system for Claude Code.** One Project Control
coordinator maintains canonical project state and dispatches worker agents —
engineering, product, QA, docs, marketing, research, hygiene — that operate
under a strict protocol: **lease → context slice → execute → Change Envelope →
reconcile**. The product is not an agent that writes code or tickets; it's the
layer that prevents a swarm of very fast workers from diverging into different
versions of reality.

Coordination and state coherence become the bottleneck once implementation
throughput gets cheap. Agents rip through tickets, then don't turn around and
clean up: the decision on ticket A silently affects B, C, and D; in-flight work
keeps building on assumptions that died an hour ago; four conversations of
back-and-forth clog every context window after conversation five scrapped the
whole idea. This kit attacks exactly that.

```
                      HUMAN  ◀── one deduplicated decision inbox
                        │
                 PROJECT CONTROL          (the main Claude Code session)
        state · dispatch · impact · reconciliation · invalidation · hygiene
            │              │              │
        engineer        product        marketing   ... (subagents, isolated
            │              │              │             context slices)
            └──────── CHANGE ENVELOPES ───┘
                        │
                   RECONCILE  ──▶  update queued work · invalidate in-flight
                        │          context · supersede decisions · archive
        your git host / tracker / chat     (projections, not truth)
```

## What's inside

- **The constitution** (`skills/bootstrap/templates/CLAUDE.md` +
  `templates/ai/protocol/`) — binds the main session as Project Control:
  single writer of state, no work without a lease, no completion without an
  envelope, decisions are records not conversations.
- **7 worker agents** (`agents/`) — engineer, product, qa, docs-writer,
  marketing, researcher, librarian — each bound by the worker contract.
- **9 skills** (`skills/`) — `/bootstrap`, `/start-work`, `/finish-work`,
  `/reconcile`, `/impact`, `/questions`, `/health`, `/status`, and `/intake`
  (turn meeting recordings, transcripts, and notes into project state —
  transcribed locally, human-confirmed, provenance-archived).
- **6 schemas** — Decision, WorkItem, ChangeEnvelope, Question, Lease,
  ContextInvalidation — each a commented template with a worked example.
- **The `.ai/` data plane** — versioned with your code: PROJECT.md (the
  60-second read), state (work index, leases, questions, priorities,
  `context_version`), decisions active/superseded, envelopes, invalidations,
  archive.

## Install

**Installer** (recommended — bare `/skill` names, data plane included):

```bash
git clone https://github.com/germs12/project-control-kit.git
./project-control-kit/install.sh /path/to/your/repo
cd /path/to/your/repo && claude
> /bootstrap
```

**As a plugin:**

```
/plugin marketplace add germs12/project-control-kit
/plugin install project-control@germs12
> /bootstrap        (scaffolds .ai/ and the CLAUDE.md block on first run;
                     plugin skills also answer to /project-control:<skill>)
```

`/bootstrap` scans the repo, drafts PROJECT.md, **detects which tracker the team actually uses** (see operations.md § *Finding the tracker* — being on GitHub is not evidence of GitHub Issues), **imports its open items as work items**
(`gh`, Linear/Slack MCP), imports open issues as work items, turns its guesses
into inbox questions instead of fabricating intent, and finishes with `/health`
and your first `/status`. Commit `.ai/` — state travels with the repo.

## The daily loop

```
/status                      where are we
/questions                   answer what's waiting on you (Q-81: B)
/start-work ENG-142          PC slices context, leases, dispatches worker(s)
        ...workers run in parallel, return Change Envelopes...
/reconcile                   commit envelopes, propagate impact, invalidate
                             stale in-flight context, update tracker, clean up
/intake call.m4a             turn the roadmap call into decisions & work items
/health                      periodically: is the project still coherent?
```

Or just talk — "work on the auth tickets", "ingest this recording" — the
constitution makes the protocol the default, not a ceremony.

## The mechanics that make it work

**Change Envelopes.** Workers never report "done!"; they return a structured
commit: behavior changes, interfaces, assumptions invalidated, affected work,
doc impacts, questions, cleanup, verification. Reconciliation then acts by
status class — backlog items get edited *before* pickup, in-flight leases get a
**Context Invalidation** notice immediately (cache invalidation for agents),
done work gets reviewed for reopen.

**Decisions are immutable records.** Once accepted, a decision is one small
file; the deliberation that produced it goes to cold storage. Future agents
consume `AUTH-014`, not the 13,000 tokens behind it.

**One human inbox.** Agents can't pepper you with questions. Project Control
merges questions that share an underlying decision, attaches options and a
recommendation, and lets low-risk work proceed under explicit, reversible,
logged assumptions. You answer once; N agents update.

**Scale-independence.** Nothing reads "the whole project" except `/bootstrap`
(once) and `/health` (audit). Every task gets a Work Brief ending in
`Everything else: DO NOT LOAD.` 30 tickets or 3,000 — same per-task context.

**Tools are projections.** The git host is authoritative for code, the tracker for
lifecycle, chat for conversation, `.ai/` for reconciled truth. Skills speak
tool-agnostic operations; swap GitHub+Linear+Slack for GitLab+Jira+Teams by
editing one adapter table (`templates/ai/protocol/operations.md`).

## Honest limits (v0.2)

Single-writer is enforced by protocol and audited by `/health`, not by
permissions — a PreToolUse hook is the natural hardening (see roadmap).
In-flight interruption is file-based: invalidations are guaranteed to be seen
at `/finish-work` at the latest; Project Control additionally steers running
workers when it can. Envelopes sitting in `pending/` mean the project is
provisionally out of sync, and both `/status` and `/health` nag about it.

## Contributing

Very welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). The roadmap wants:
`/triage`, `/plan`, `/sweep`, `/release` skills; architecture and release
agents; a single-writer enforcement hook; fleshed-out adapters for more trackers and chat tools;
more `/intake` fixtures (see [`examples/`](examples/)).

## License

[MIT](LICENSE)
