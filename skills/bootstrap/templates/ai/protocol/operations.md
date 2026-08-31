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
| Code, branches, commits, PRs, CI/tests, releases | Git host (GitHub) |
| Work-item lifecycle: status, priority, assignment, milestones | Tracker (Linear / GitHub Issues if no tracker) |
| Conversation, raw human input, pre-reconciliation decisions | Chat (Slack) |
| Accepted decisions, dependencies, constraints, leases, agent coordination, cross-system relationships | `.ai/` in this repo |

`.ai/state/work-items.yaml` is Project Control's **reconciled index** of the tracker —
it carries fields trackers model poorly (`touches`, `depends_on`, `context_version`,
`external_ref`). If a tracker is connected, the tracker owns lifecycle fields and the
index mirrors them; if not, the index is the tracker until one is connected.

## Operations → adapters

| Operation | GitHub (gh CLI / MCP) | Linear (MCP) | Slack (MCP) | Local fallback |
|---|---|---|---|---|
| `get_work_item(id)` | `gh issue view` | get issue | — | read `state/work-items.yaml` |
| `update_work_item(id, fields)` | `gh issue edit` / comment | update issue | — | edit index (PC only) |
| `create_work_item(item)` | `gh issue create` | create issue | — | append to index |
| `find_related_work(concepts)` | `gh issue list --search` | search issues | — | grep index `touches` |
| `get_pull_request(id)` | `gh pr view` | — | — | — |
| `record_decision(decision)` | — | — | — | write `.ai/decisions/active/` (PC only) |
| `publish_context_invalidation(notice)` | comment on issue | comment on issue | post to channel | write `.ai/invalidations/` (always) |
| `get_active_workers()` | — | — | — | read `state/leases.yaml` |
| `search_conversations(query)` | — | — | search messages | — |
| `notify_human(digest)` | — | — | DM / channel post | write `.ai/INBOX.md` (always) |

Rules of engagement:

- The **local fallback column always executes** for `record_decision`,
  `publish_context_invalidation`, `get_active_workers`, and `notify_human` — external
  systems are projections of these, not replacements.
- Detect adapters at runtime: `gh auth status` for GitHub; presence of Linear/Slack MCP
  tools for the rest. If an operation's preferred adapter is unavailable, use the
  fallback and note the gap in the reconcile log rather than failing the operation.
- Writes to external systems happen only during `/reconcile` and `/bootstrap`
  (single-writer rule). Workers may *read* through adapters when their Work Brief
  points them at an external artifact.
- When adding a new platform, add a column here and map the operations. Do not teach
  skills or agents vendor syntax.
