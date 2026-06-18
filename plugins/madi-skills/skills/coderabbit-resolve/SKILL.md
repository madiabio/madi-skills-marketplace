---
name: coderabbit-resolve
description: Work through every CodeRabbit review comment on a PR — evaluate each, fix the valid ones (in parallel where possible), reply-and-resolve the rest with a Claude-credited rationale, then post "@coderabbit review" and loop until CodeRabbit has nothing left to say. Use when the user says "handle the CodeRabbit comments", "resolve the coderabbit review", "address the coderabbit feedback", or "/coderabbit-resolve".
---

# CodeRabbit resolve loop

Drive a PR's CodeRabbit review to zero open comments, fixing what's valid and justifying what isn't, then re-trigger review and repeat until CodeRabbit is silent.

## 0. Identify the PR

- Default to the open PR for the **current branch**: `gh pr view --json number,url,headRefName,body`.
- If the user passed a PR number as an argument, use that.
- If no PR is found, or several match, ask the user which one. Do not guess.

## 1. Pull all CodeRabbit review threads

Fetch the unresolved review threads (CodeRabbit posts as review comments on threads, not just issue comments). Use GraphQL so you get thread IDs needed to resolve them:

```bash
gh api graphql -f query='
query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
      reviewThreads(first:100){
        nodes{
          id isResolved
          comments(first:20){ nodes{ author{login} body path line } }
        }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO -F pr=PR_NUMBER
```

Keep only threads where `isResolved` is false and the comment author is `coderabbitai` (or `coderabbitai[bot]`). Capture each thread's `id`, file `path`/`line`, and comment `body`. Also scan top-level issue comments from CodeRabbit for actionable items, but the **thread `id`** is what you need to resolve.

## 2. Evaluate every comment

For each comment, decide **valid** or **not valid**:
- **Valid** — a real bug, correctness issue, security problem, or a clear, justified improvement. → fix it.
- **Not valid** — false positive, stylistic preference you disagree with, out-of-scope, or already handled elsewhere. → reply with the reason and resolve.

When in doubt about whether a finding is real, lean on reading the actual code rather than the comment's claim.

## 3. Fix the valid ones — in parallel

- Group the valid fixes by independence. **Dispatch parallel `Agent` (general-purpose) sub-agents** for fixes that touch disjoint files/concerns so they run concurrently. Apply coupled fixes (same file/region) in a single agent or inline to avoid conflicts.
- Each fix must be minimal and scoped to the comment. Follow the repo's conventions and the user's global SWE rules (docstrings, conventional commits, design hygiene).
- After fixes land, **commit and push** (conventional-commit messages) so CodeRabbit re-reviews real code, not a stale diff.

### Risky fixes — gate on autonomy
- If a valid fix touches **architecture, a public API/contract, or has broad blast radius**, and you are **not in autonomous mode**, surface it to the user (one decision at a time) before applying.
- If you **are** in autonomous mode (`/loop`, "go autonomous", AFK), apply it and note the decision in the PR reply; don't block.

## 4. Defer → create a GitHub issue

If a comment is valid but you decide **not** to fix it now (out of scope, needs design, too large for this PR):
- Create a tracking issue: `gh issue create --title "..." --body "..."` — body should summarize the finding, link the PR, and quote the relevant file/line.
- In the PR reply for that thread, link the issue explicitly.
- After processing all comments, **edit the PR body** (`gh pr edit --body`) to add a "Deferred from CodeRabbit review" section listing each deferred issue by number/link.

## 5. Reply + resolve EVERY thread

For **not-valid** and **deferred** comments, post a reply explaining why, then resolve the thread. For **fixed** comments, optionally reply noting the fix commit, then resolve.

- **Credit Claude in every PR comment you author** — thread replies, the `@coderabbit review` trigger, deferred-issue links, PR-body notes: any GitHub text you write. End each with an authorship line of the form:
  `Author: Claude {model}, {effort level}`
  Fill in the **actual** model and reasoning-effort you are running as (e.g. `Author: Claude Opus 4.8, high` or `Author: Claude Sonnet 4.6, medium`) — do not leave the placeholders literal. If you cannot determine the effort level, omit it and write just `Author: Claude {model}`.
- Reply to a thread (issue-comment style summary is fine for the explanation):
  ```bash
  gh api graphql -f query='mutation($pr:ID!,$body:String!){ addPullRequestReviewThreadReply(input:{... }) ...}'
  ```
  If the threaded reply mutation is awkward, post a normal PR comment referencing the file/line, then resolve the thread.
- Resolve the thread:
  ```bash
  gh api graphql -f query='mutation($id:ID!){ resolveReviewThread(input:{threadId:$id}){ thread{ isResolved } } }' -F id=THREAD_ID
  ```
- **Goal: zero unresolved CodeRabbit threads.** Re-run the query from step 1 to confirm none remain before moving on.

## 6. Re-trigger and loop

- Once all threads are resolved, post a PR comment: `gh pr comment PR --body "@coderabbit review"` (include the `Author: Claude {model}, {effort level}` line from step 5).
- **Loop:** wait for CodeRabbit to post a fresh review, then go back to step 1. Use the `/loop` skill to self-pace the polling (no fixed interval; CodeRabbit takes a few minutes). Detect "new comments" by comparing review/thread IDs against what you've already processed.
- **Termination is goal-driven, not capped:** stop only when a fresh CodeRabbit review produces **no new actionable threads** (it may post an approval or a "no comments" summary). Once it converges, **do step 7 before reporting done** — the loop isn't finished until the PR body is finalized. Use `/step-back` if you lose track of whether the loop is converging.

## 7. Finalize the PR body (once the loop has converged)

After CodeRabbit is silent and all threads are resolved, bring the PR body up to date **before** declaring done. Two required edits via `gh pr edit --body-file <file>`:

### 7a. Manual-review section — tickable checkboxes
The PR body **must** contain a manual-test section so a human reviewer can verify the change in the running app, written as **tickable checkboxes** (`- [ ]`), not a prose paragraph.

- If a manual-test section is **absent**, add one. If it exists but is prose or stale, convert/refresh it.
- **Ground the steps in the actual change** — read the touched component(s)/endpoint(s) first so the steps describe real, observable behaviour (where the UI element renders, what header/response to inspect, what the expected result is). Do not write generic boilerplate.
- Group checkboxes by the behaviours being verified; include a **Setup** group (how to run it — local stack command and/or the deployed URL).
- Where verification differs by **environment** (local vs remote deployment) or depends on **another unmerged PR**, say so explicitly — a small "where it works" table or a blockquote caveat is ideal, so the reviewer isn't misled into thinking a check is impossible when it's only gated on a dependency.
- Preserve any CodeRabbit auto-generated blocks (e.g. the `<!-- ... release notes by coderabbit.ai -->` section) untouched — insert/replace only the authored portion.

### 7b. Body-freshness pass
Re-read the whole PR body and make sure it still matches what actually landed after this round of fixes:

- Status lines / "what landed" checklists reflect the final state (e.g. flip ⏳/🚧 → ✅, tick completed items).
- Test counts, file references, and acceptance-criteria claims still match the code on the branch.
- Any "Deferred from CodeRabbit review" section (from step 4) is present and lists the issues created.
- If this PR is tracked on a coordination board/issue, update that issue's status too (both the table row and any checklist — keep the two representations consistent).

Only after 7a + 7b are done should you report the final summary.

## Notes

- Discover `OWNER`/`REPO` at runtime from `gh repo view --json owner,name` — don't hard-code.
- CodeRabbit's bot login may be `coderabbitai` or `coderabbitai[bot]`; match both.
- If CodeRabbit posts "actionable" vs "nitpick"/"outside diff" sections, treat nitpicks with judgment — fix cheap ones, justify-and-resolve the rest.
