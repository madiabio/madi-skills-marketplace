---
name: are-you-following-asdlc
description: Pre-work gate that checks the ASDLC (Agentic Software Development Life Cycle) ticket hygiene BEFORE starting implementation — verifies a matching Jira ticket exists (not a duplicate), is in the right status, and has clear acceptance criteria. Actively searches live Jira via the Atlassian MCP tools and offers to update/create/transition tickets. Invoke when about to start non-trivial work, or when the user says "are you following ASDLC", "did you do the ticket stuff", "/are-you-following-asdlc", or "/are-you-following-ADSLC".
---

# Are you following ASDLC?

A pre-flight gate run BEFORE writing implementation code. It makes sure the agentic
software development life cycle (ASDLC) ticket hygiene is done first: a Jira ticket
exists for this work, doesn't duplicate an existing one, is in the right status, and
has clear acceptance criteria. Do NOT skip straight to coding — run this check first
and resolve anything missing.

## Process

1. **Learn this repo's ASDLC conventions first (if you haven't already).** Don't assume
   a generic process — discover what *this* repo uses and how. Check, in order:
   `CLAUDE.md` / `AGENTS.md` (look for an ASDLC / workflow / ticketing section),
   `CONTRIBUTING.md`, `README`, `docs/` (esp. `docs/adr/`, `docs/agents/`), and any
   `.github/` templates. Pull out: the Jira project key(s), the ticket-status workflow
   (what counts as "ready to work"), branch/commit conventions tied to ticket keys, and
   what acceptance criteria look like here. If conventions are genuinely undocumented,
   say so and ask the user briefly rather than guessing.

2. **Summarise the work in one line.** State what you're about to implement, in the
   user's own terms, so the Jira search has good keywords.

3. **Search live Jira for matching tickets.** Use the Atlassian MCP tools (load via
   ToolSearch if deferred):
   - `searchJiraIssuesUsingJql` with terms inferred from the work summary (text ~
     keywords, recent/open issues, current sprint/board where known). If the project
     key is unknown, `getVisibleJiraProjects` first.
   - Read the top candidates with `getJiraIssue` to judge real overlap, not just a
     keyword collision.

4. **Decide: existing or new.** Present what you found as a short orienting list
   (ticket key, title, status, one-line relevance). Then ask the user — one decision:
   - **Matches an existing ticket** → that's the ticket; go to step 5.
   - **No match** → offer to create one with `createJiraIssue` (propose summary,
     description, acceptance criteria; confirm project/type before creating).
   - **Partial / related** → flag it and ask whether to extend the existing ticket,
     link to it (`createIssueLink`), or create a sibling.

5. **Check ticket status.** Confirm the ticket is in the correct pre-work state
   (per the repo's workflow from step 1 — e.g. *In Progress*, assigned to the user).
   If not, offer to transition it with `getTransitionsForJiraIssue` →
   `transitionJiraIssue`, and assign via `editJiraIssue` if needed. Don't transition
   without confirmation.

6. **Check acceptance criteria.** Read the ticket — does it have a clear definition of
   done / acceptance criteria? If absent or vague, draft them from the work context
   and offer to add them (`editJiraIssue` or `addCommentToJiraIssue`). Coding against
   undefined criteria is the failure this gate exists to prevent.

7. **Report the gate result.** End with a short verdict:
   - **PASS** — ticket `<KEY>` matches, status `<X>`, acceptance criteria present →
     clear to start.
   - **BLOCKED** — list exactly what's missing (e.g. "no ticket", "status is To Do",
     "no acceptance criteria") and what you did/offered to fix it.

## Rules

- This is a **gate, not a build step** — produce a verdict, don't start implementing.
- **Never create, transition, edit, or comment on a Jira ticket without confirming**
  with the user first — these are outward-facing writes.
- If the Atlassian MCP tools aren't available in this environment, say so and fall back
  to asking the checklist questions (ticket exists & matches? right status? acceptance
  criteria clear?) without touching Jira.
- Keep it terse: orient with a short list, then one decision at a time.
