---
name: are-you-following-asdlc
description: Pre-work gate that checks the ASDLC (Agentic Software Development Life Cycle) ticket hygiene BEFORE starting implementation — verifies a matching ticket exists in the active issue tracker (Jira or Linear), isn't a duplicate, is in the right status, and has clear acceptance criteria. Actively searches the live tracker via its MCP tools and offers to update/create/transition tickets. Invoke when about to start non-trivial work, or when the user says "are you following ASDLC", "did you do the ticket stuff", "/are-you-following-asdlc", or "/are-you-following-ADSLC".
---

# Are you following ASDLC?

A pre-flight gate run BEFORE writing implementation code. It makes sure the agentic
software development life cycle (ASDLC) ticket hygiene is done first: a ticket exists
for this work in the active issue tracker, doesn't duplicate an existing one, is in the
right status, and has clear acceptance criteria. Do NOT skip straight to coding — run
this check first and resolve anything missing.

## Process

1. **Resolve the active tracker** (Jira or Linear) as global CLAUDE.md "Issue trackers"
   describes: the repo's `docs/agents/issue-tracker.md` `tracker:` default, then the
   user's `project-manage` choice, else ask. Read that tracker's doc for its project/team,
   statuses and conventions.
2. **Learn this repo's ASDLC conventions (if you haven't already).** Don't assume a
   generic process. Check CLAUDE.md / AGENTS.md (an ASDLC / workflow / ticketing
   section), CONTRIBUTING.md, README, docs/ (esp. docs/adr/, docs/agents/), and any
   .github/ templates. Pull out the ticket-status workflow (what counts as "ready to
   work"), branch/commit conventions tied to ticket keys, and what acceptance criteria
   look like here. If conventions are genuinely undocumented, say so and ask briefly.
3. **Summarise the work in one line**, in the user's own terms, so the search has good
   keywords.
4. **Search the live tracker for matching tickets** (load its MCP tools via ToolSearch if
   deferred), then read the top candidates to judge real overlap, not just a keyword hit.
   The operations by tracker:

   | Operation          | Jira (`mcp__atlassian__*`)                             | Linear (`mcp__linear-server__*`)                         |
   | ------------------ | ------------------------------------------------------ | -------------------------------------------------------- |
   | Search             | `searchJiraIssuesUsingJql` (`text ~ …`, open, sprint)  | `list_issues` with `team`, `query`, `state`              |
   | Read               | `getJiraIssue`                                         | `get_issue` (+ `list_comments` for discussion)           |
   | Create             | `createJiraIssue`                                      | `save_issue` without `id` (`team` required)              |
   | Edit / assign      | `editJiraIssue`                                        | `save_issue` with `id`                                   |
   | Change status      | `getTransitionsForJiraIssue` → `transitionJiraIssue`   | `save_issue` with `id` and `state`                       |
   | Comment            | `addCommentToJiraIssue`                                | `save_comment`                                           |
   | Link / block       | `createIssueLink`                                      | `save_issue` with `blocks` / `blockedBy` / `relatedTo`   |

   If the project/team is unknown, list them first (`getVisibleJiraProjects` /
   `list_teams`).
5. **Decide: existing or new.** Present what you found as a short orienting list
   (ticket link with title, status, one-line relevance). Then ask the user — one decision:
   - **Matches an existing ticket** → that's the ticket; go to step 6.
   - **No match** → offer to create one (propose title, description, acceptance
     criteria; confirm project/team and type, or type label in Linear, before creating).
   - **Partial / related** → flag it and ask whether to extend the existing ticket, link
     to it, or create a sibling.
6. **Check ticket status.** Confirm it's in the correct pre-work state per the repo's
   workflow (e.g. *In Progress*, assigned to the user). If not, offer to change status
   and assign. Don't change it without confirmation.
7. **Check acceptance criteria.** Does the ticket have a clear definition of done? If
   absent or vague, draft criteria from the work context and offer to add them (edit the
   description or comment). Coding against undefined criteria is the failure this gate
   exists to prevent.
8. **Report the gate result.** End with a short verdict:
   - **PASS** — ticket <link + title> matches, status <X>, acceptance criteria present →
     clear to start.
   - **BLOCKED** — list exactly what's missing (e.g. "no ticket", "status is Todo", "no
     acceptance criteria") and what you did/offered to fix it.

## Rules

- This is a **gate, not a build step** — produce a verdict, don't start implementing.
- **Never create, change status, edit, or comment on a ticket without confirming** with
  the user first — these are outward-facing writes.
- Write as the user: in EliteMx, Jira writes go through `mcp__atlassian__*` (the Rovo
  connector is signed in as someone else); Linear writes use the user's own login.
- If the active tracker's MCP tools aren't available, say so and fall back to asking the
  checklist questions (ticket exists & matches? right status? acceptance criteria
  clear?) without touching the tracker.
- Keep it terse: orient with a short list, then one decision at a time.
