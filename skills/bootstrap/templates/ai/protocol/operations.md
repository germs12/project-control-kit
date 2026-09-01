# Operations & Adapters v0.1

Project Control and its skills speak in **tool-agnostic operations**, never in
vendor-specific tool calls. This is what lets the same system run against
GitHub + Linear + Slack today and GitLab + Jira + Teams tomorrow without redesigning
the operating model. When executing an operation, resolve it through the adapter table
below, preferring whatever is actually connected in this session.

## Source-of-truth authority

When systems disagree, the system authoritative for that **class** of information wins.
Never silently prefer whichever source you read most recently.

| Class of information | Authoritative system |
|---|---|
| Code, branches, commits, PRs, CI/tests, releases | The git host (GitHub, GitLab, Bitbucket…) |
| Work-item lifecycle: status, priority, assignment, milestones | **The tracker this team actually uses** — see below |
| Conversation, raw human input, pre-reconciliation decisions | The chat tool (Slack, Teams, Discord…) |
| Accepted decisions, dependencies, constraints, leases, agent coordination, cross-system relationships | `.ai/` in this repo |

`.ai/state/work-items.yaml` is Project Control's **reconciled index** of the tracker —
it carries fields trackers model poorly (`touches`, `depends_on`, `context_version`,
`external_ref`). If a tracker is connected, the tracker owns lifecycle fields and the
index mirrors them; if not, the index is the tracker until one is connected.

## Operations → adapters

The operations below are the interface. **Which tool implements them is a per-repo fact
you DETECT, never a default you assume** — see "Finding the tracker".

| Operation | Any tracker adapter | Git host | Any chat adapter | Local fallback |
|---|---|---|---|---|
| `get_work_item(id)` | view issue / ticket | — | — | read `state/work-items.yaml` |
| `update_work_item(id, fields)` | update issue, or comment | — | — | edit index (PC only) |
| `create_work_item(item)` | create issue | — | — | append to index |
| `find_related_work(concepts)` | search issues | — | — | grep index `touches` |
| `get_pull_request(id)` | — | view PR/MR | — | — |
| `record_decision(decision)` | — | — | — | write `.ai/decisions/active/` (PC only) |
| `publish_context_invalidation(notice)` | comment on issue | — | post to channel | write `.ai/invalidations/` (always) |
| `get_active_workers()` | — | — | — | read `state/leases.yaml` |
| `search_conversations(query)` | — | — | search messages | — |
| `notify_human(digest)` | — | — | DM / channel post | write `.ai/INBOX.md` (always) |

Concrete bindings, once you know which tool it is:

| Operation | GitHub Issues | GitLab | Linear / Jira / Shortcut / Asana / Notion |
|---|---|---|---|
| `get_work_item` | `gh issue view` | `glab issue view` | their MCP tool |
| `update_work_item` | `gh issue edit` / comment | `glab issue update` | their MCP tool |
| `create_work_item` | `gh issue create` | `glab issue create` | their MCP tool |
| `find_related_work` | `gh issue list --search` | `glab issue list` | their MCP tool |
| `get_pull_request` | `gh pr view` | `glab mr view` | n/a — git host, not tracker |

And nothing connected → the local fallback column, which is a complete
implementation and not a degraded mode.

## Finding the tracker

**We are helping here, not creating new workflows and processes.** Do not file into a
tracker a team does not use, and never create the first issue in one nobody uses — a wrong
guess does not misfile a ticket, it starts a parallel system the team now has to ignore.

**Being hosted on GitHub is not evidence that a team uses GitHub Issues.** Plenty of repos
on GitHub run Linear, Jira, Shortcut or Asana. Work down the evidence and **stop at the
first step that answers**:

0. **Has this already been answered?** If `.ai/PROJECT.md` records a tracker, use it — do
   not re-derive. Re-deriving is how two runs reach two answers on one repo. Re-open it
   only when something contradicts it, and then change the record.
1. **Is Project Control itself the tracker?** If `.ai/state/work-items.yaml` exists and
   holds items, **this repo's tracker is that index** unless a connected tool says
   otherwise. Check this BEFORE reading commit subjects, because of the trap in step 2.
2. **Commit and branch history — with two traps that make it useless if ignored.**
   `git log --oneline -50` and `git branch -r`. An id like `ENG-123` / `PROJ-456` suggests
   Linear, Jira or Shortcut… **but:**
   - **Project Control's OWN ids are that shape.** `workstreams.yaml` mints `ENG-`,
     `PROD-`, `QA-`, `DOC-`, `HYG-`, and `/reconcile` REQUIRES agents to cite them in
     commit messages and PR bodies. **Exclude every prefix in `workstreams.yaml` before
     concluding anything** — otherwise every repo running this kit detects as Linear.
   - **`#123` is evidence about the GIT HOST, not the tracker.** GitHub's squash merge
     writes the pull-request number into every commit subject, so `(#412)` appears on
     GitHub repos whichever tracker they use. It tells you nothing here. Ignore it.
   If foreign ids and `#N` both appear — the common Linear-on-GitHub case — that is not a
   conflict, because `#N` was never evidence. If two FOREIGN prefixes appear, the team
   probably migrated: prefer the one in recent commits, and say so when you report.
   A shallow clone or a young repo returns nothing here; **that is uninformative, not a
   negative** — carry on to 3.
3. **Connected tools.** An available Linear / Jira / Asana / Notion integration is strong
   evidence — and stronger than `gh auth status` succeeding, which is true on nearly every
   developer's machine regardless of where work is tracked.
4. **What the repo says about itself.** `CONTRIBUTING.md`, the pull-request template,
   README links, an issue-template directory present or conspicuously absent.
5. **Files in the tree.** `TODO.md`, `docs/TASKS.md`.

**Report the evidence, not the conclusion.** *"Recent branches are `eng-*` and commits cite
`ENG-###`, so this looks like Linear — confirm?"* can be corrected in one word. *"Filed 6
issues in GitHub"* cannot. Record the answer and its evidence in `PROJECT.md` so the next
run reuses it rather than re-interrogating the repo and possibly deciding differently.

When the evidence is thin or contradictory, **say what you found and ask.** The local
fallback is always available in the meantime, so nothing is blocked by not knowing.

Rules of engagement:

- The **local fallback column always executes** for `record_decision`,
  `publish_context_invalidation`, `get_active_workers`, and `notify_human` — external
  systems are projections of these, not replacements.
- Detect adapters at runtime by the evidence above, not by which CLI happens to be
  installed. If an operation's adapter is unavailable, use the fallback and note the gap
  in the reconcile log rather than failing the operation.
- Writes to external systems happen only during `/reconcile` and `/bootstrap`
  (single-writer rule). Workers may *read* through adapters when their Work Brief
  points them at an external artifact.
- When adding a new platform, add a column here and map the operations. Do not teach
  skills or agents vendor syntax.

## If merges deploy, apply migrations BEFORE you merge

Find out whether merging to the default branch deploys — by watching, not by reading the
docs, because the two disagree more often than not. In one project the changelog said
merges deploy automatically and the operations doc described batched deploys on the
owner's say-so; ~30 observed deployments settled it in an afternoon.

If merging deploys, then **the migration goes in first**. Merging code that reads a column
that does not exist yet ships a broken product in the minutes before anyone notices, and
the notice usually arrives as a customer.

Two habits that cost nothing and have each caught a real one:

- **Verify the destructive statements against real data first.** A migration that deletes
  rows with no resolvable parent should be run against a count, not a hope. One such
  DELETE turned out to affect zero rows — which is what made it safe to run, and was not
  knowable without asking.
- **Verify the object exists AFTER applying, by reading the catalog** — `pg_proc`,
  `pg_policies`, `information_schema` — not by trusting the tool's success response.

And audit for drift periodically, in both directions. A table-level diff misses a
migration that only adds a function or a constraint: in one project three migrations had
never been applied, two of them invisible to a table diff, and one would have refused
every login the moment a dependent ticket merged.

