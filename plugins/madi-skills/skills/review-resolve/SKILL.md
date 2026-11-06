---
name: review-resolve
description: Triage and resolve every review comment on a PR — from human reviewers or the Claude Code Review bot. Groups comments by root cause to separate structural problems (raised to the user, one at a time) from local fixes (fixed immediately by parallel sub-agents in /semi-auto-mode), then replies to and resolves every thread. For the Claude bot, loops on re-review until it's silent. Use when the user says "triage the review comments", "handle the review feedback", "address the PR comments", "resolve the claude review", "/review-resolve", or "/claude-review-resolve".
---

# Review resolve

Work a PR's review comments to zero open threads. The point is **not** to whack-a-mole each
comment: find the root causes, fix the local ones straight away, and bring the structural
ones to the user.

Run the fix work under `/semi-auto-mode`: decide and act on minor things, only interrupt the
user for what clears its ask threshold, and **fan out to parallel sub-agents** wherever the
work is independent. The main thread stays free to talk to the user.

## 0. Identify the PR

- Default to the open PR for the current branch: `gh pr view --json number,url,headRefName,body`.
- If the user passed a PR number, use that. If none or several match, ask. Don't guess.
- Discover OWNER/REPO with `gh repo view --json owner,name` — never hard-code.

## 1. Pull every unresolved comment

Use GraphQL so you get thread IDs for resolving:

```bash
gh api graphql -f query='
query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
      reviews(last:30){ nodes{ id author{login} state body submittedAt } }
      reviewThreads(first:100){
        nodes{
          id isResolved isOutdated
          comments(first:20){ nodes{ author{login} body path line } }
        }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO -F pr=PR_NUMBER
```

- Keep every thread where `isResolved` is false, **from any reviewer**. Read the whole
  thread, not just the first comment: later replies often narrow or retract the ask.
- Also read the **review summary bodies**, since findings can live there with no thread.
  This applies especially to the Claude bot (see §7), which moves findings it couldn't
  anchor into its summary. Track body-only findings separately; they have no thread to resolve.
- Note who wrote each comment (human vs `github-actions`/`github-actions[bot]`), because it
  decides the loop in §6.

**Read the comments in parallel, not one by one.** With more than a handful of comments,
fan out `Explore`/`general-purpose` sub-agents, each covering a slice of the threads. Each one
reads the code each comment points at and returns a one-line root-cause hypothesis per comment.

## 2. Triage: group by root cause, then classify

**First group the comments by root cause.** Several comments that trace back to the same
underlying cause count as one group. Two or more comments sharing a cause is a strong
signal that the group is structural.

Then put each group in a bucket:

| Bucket | Meaning | Action |
|---|---|---|
| **Structural** | The comment is a symptom of a deeper cause. Examples: a missing validation/invariant at a boundary, a wrong contract between layers (DB → API → UI), the same flaw elsewhere in the stack, or a fix that would contradict an ADR/spec | Raise to the user (§4) |
| **Judgment call** | A valid point, but it's a product or taste decision, not a bug | Raise to the user (§4) |
| **Local fix** | Self-contained, the fix is obvious, small blast radius | Fix now (§3) |
| **Not valid** | False positive, or already handled elsewhere | Reply with the reason, resolve |
| **Defer** | Valid but out of scope for this PR | Ticket, link it, resolve (§5) |

**The promotion check, which is what prevents whack-a-mole:** before you call anything a
**local fix**, grep the codebase for the same pattern. If it shows up in places the reviewer
didn't flag, it moves up to **structural**. A band-aid on the flagged line while the same
bug sits in three sibling files is the exact failure this skill exists to prevent.

Minor fixes stay local even if they touch a contract (adding an optional field, widening a
type). Only **breaking or reshaping** changes go up, following `/semi-auto-mode`'s threshold.

When unsure whether a finding is real, trust the code over the comment's claim.

### Present the map

Show the user a compact map: N groups, each with its bucket, a one-line root cause, and
which comments it covers. No long expansions yet.

## 3. Start the local fixes immediately, in parallel

Right after presenting the map, while you go through §4 with the user:

- **Dispatch local fixes to parallel sub-agents in one message**, grouped by file/concern.
  Fixes that touch the same file or region go to one agent. Each agent follows
  `/semi-auto-mode`'s sub-agent rules: no questions, minimal scoped fix, run only the touched
  tests/typecheck/lint, conventional commit. It reports back the fix, the checks it ran with
  results, the commit hash, and any `NEEDS_DECISION` items.
- **Hold back any local fix that overlaps a structural group's code**, since the structural
  decision may rewrite it. It joins that group instead.
- Mind RAM before fanning out heavy agents (see CLAUDE.md), and say in one line how many you
  launched.
- Follow the repo's conventions and the global SWE rules (docstrings, design hygiene).

## 4. Walk structural and judgment groups with the user, one at a time

For each group, in order of blast radius:

1. The root cause in one or two lines, and which comments it explains (with file:line).
2. Where else the pattern lives, from the promotion grep.
3. Two or three ways to fix it, with your recommendation first. Name the trade-off that
   decides between them.
4. Ask. Once there's an answer, dispatch the fix (a sub-agent if it's independent of the
   remaining groups) and move to the next group. Don't stack every group in one message.

If the user decides "not now", treat the group as **Defer** (§5).

## 5. Defer, then create a tracking ticket

- **File it in the active issue tracker** (resolve it as global CLAUDE.md "Issue trackers"
  says: the repo's `docs/agents/issue-tracker.md`, then my `project-manage` choice). For
  EliteMx that's Linear (team ELI) or Jira (project ELITE). If the repo has no tracker
  convention at all, use `gh issue create`.
- The ticket body summarises the finding, links the PR, and quotes file:line. For structural
  groups, list every affected location.
- Link the ticket in the thread reply. After all comments are handled, add a "Deferred from
  review" section to the PR body listing each ticket.

## 6. Reply to and resolve every thread, then push once

Every thread gets a reply and is resolved: fixed (cite the commit), not valid (give the
reason), deferred (link the ticket), or structural (describe the fix that landed).

**Sign every comment you author**, including thread replies, ticket links and PR-body notes,
with:

`<sub>— Claude {model} ({effort} effort), with Madi driving.</sub>`

Fill in the **actual** model and reasoning effort you're running as, e.g.
`<sub>— Claude Opus 5.5 (high effort), with Madi driving.</sub>`. If you can't determine the
effort, drop the parenthetical.

**Never write `@claude` in a PR comment.** `.github/workflows/claude.yml` fires on it and
starts a separate agent run. Refer to the reviewer as "the Claude review".

```bash
# reply
gh api graphql -f query='mutation($tid:ID!,$body:String!){
  addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$tid,body:$body}){
    comment{ id } } }' -F tid=THREAD_ID -F body="..."
# resolve
gh api graphql -f query='mutation($id:ID!){
  resolveReviewThread(input:{threadId:$id}){ thread{ isResolved } } }' -F id=THREAD_ID
```

Independent reply and resolve calls can be batched in one message.

- **Reconcile before pushing.** Once the fix agents report back, check that their commits
  don't conflict or contradict each other, and that nothing is still waiting on a
  `NEEDS_DECISION` item.
- **Push once per round**, after all of that round's fixes have landed. On Graphite that's
  `gt modify -a` / `gt create -am` followed by `gt submit --no-interactive`. Batching the
  push matters: a second push cancels a Claude review that's already running.
- Re-run the §1 query and confirm **zero unresolved threads**.

### Loop policy

- **Human reviewers: one pass.** Fix, reply, resolve, push. Don't re-request review and
  don't poll.
- **Claude bot: loop** per §7 until a fresh review has nothing actionable.

## 7. Claude Code Review bot specifics

The bot is `.github/workflows/claude-code-review.yml`. It posts formal reviews with inline
comments as `github-actions` / `github-actions[bot]` (match both). Graphite shows these as
"Changes requested", but they're ordinary GitHub threads, so work them with `gh`.

- **Bot vs other bot comments:** other workflows may also comment as `github-actions`. Only
  count a comment as the reviewer's if it belongs to a formal review (the `reviews` nodes).
- **The summary body carries real findings.** A finding that couldn't be anchored to a line
  in the diff goes there. Always read the newest review's body.
- **Resolving threads doesn't clear `CHANGES_REQUESTED`.** It clears only when a newer review
  arrives on the pushed commit.
- **The push is the re-trigger.** The workflow runs on `opened, synchronize,
  ready_for_review, reopened, labeled`. Don't post a comment to re-trigger it.
- **No run after the push?** Check the stack-depth job's log first. It skips on purpose when:
  - the PR is more than 3 PRs above `develop` in the Graphite stack: add the `claude-review`
    label (`gh pr edit PR --add-label claude-review`; re-adding it re-fires the event);
  - the PR edits the review workflow itself (`claude-code-review.yml` or
    `.github/actions/claude-review-attempt/`): no review is possible, so skip the loop and say so;
  - the base branch has no PR: add the label to force a run.
- **Loop:** use `/loop` to pace the polling yourself
  (`gh run list --workflow=claude-code-review.yml --branch <branch>`), then go back to §1. Spot
  new comments by comparing review and thread IDs with what you've already processed.
- **A red `claude-review` job isn't always a finding.** "None of the 4 Claude accounts
  persisted a review" means the shared account pool is exhausted. Re-run it once; if it's
  still on quota, report that and stop.
- **Stop when the goal is met**, not after a fixed number of rounds: a fresh review with
  nothing actionable. The bot never APPROVEs, so don't wait for that. Be frugal, since each
  pass uses up the shared pool.

## 8. Finalise the PR body

Before reporting done, edit the PR body with `gh pr edit --body-file`:

- **Manual-test section as tickable checkboxes** (`- [ ]`), grounded in the actual change
  (read the touched components/endpoints first). Include a **Setup** group. Call out any
  difference by environment or any dependency on unmerged PRs. Leave auto-generated blocks
  untouched.
- **Freshness pass:** status lines, test counts, file references and acceptance-criteria
  claims all match what landed. The "Deferred from review" section is present. Update any
  coordination board or issue too.

Then report: groups handled per bucket, commits, tickets created, and anything still open.
