---
name: fix-ci-until-green
description: Autonomously drive a GitHub Actions CI/CD pipeline to green — set a /goal of "pipeline is green", then loop on the latest run finding failing (especially deployment) jobs, diagnose and fix each via /diagnose, push, and let /goal re-check until the pipeline passes. Use when the user says "get CI green", "fix the pipeline", "loop on CI and fix the failures", "make the deploy pass", or "/fix-ci-until-green". Stops and pings Discord when a failure is not auto-fixable (missing secret, permissions, flaky external dependency).
---

# Fix CI until green

Drive the GitHub Actions pipeline for the current repo to a passing state. Each iteration: read the latest run, fix one failure (via `/diagnose`), push, and wait for the re-run. Loop until green or until a failure that you cannot fix yourself forces an escalation.

This is a **composition** skill: it orchestrates `/loop`, `/diagnose`, and the repo's git/`gh` tooling. You are not inventing CI logic — you are reading status, classifying failures, and routing the fixable ones to the diagnosis loop.

## Preconditions

1. Confirm `gh` is authenticated: `gh auth status`. If not, stop and tell the user to run `! gh auth login`.
2. Confirm you're in a git repo with a GitHub remote and on a branch CI runs against. Note the branch — every fix must land on it for CI to re-evaluate.

## Set the goal first

Before the first iteration, register the completion condition with the built-in `/goal` command. `/goal` is the termination oracle: after every turn a fast model checks the condition against the conversation and auto-continues you until it holds, then stops. Set it to a *verifiable* end-state:

```
/goal The GitHub Actions pipeline for branch <branch> is green — the latest run is completed + success, proven by `gh run view <latest-run-id>` showing conclusion=success for every job.
```

This means you don't hand-roll the "keep looping until green" control flow — `/goal` owns it. Your job each turn is to advance one failure toward that state. (`/goal` pairs naturally with `/loop` if the user invoked one; if not, `/goal` alone will auto-continue your turns.)

If you hit the **Escalate** path (a failure `/goal` can never satisfy on its own — e.g. a missing secret), call `/goal clear` so the session doesn't keep auto-continuing against an unreachable goal.

## The loop

One failure per iteration — fix, push, re-check — so each diagnosis stays focused. `/goal` re-fires you until the pipeline is green.

1. **Read the latest run for the current branch.**
   ```
   gh run list --branch <branch> --limit 1
   gh run view <run-id>
   ```
   - If status is `completed` + `success` → the pipeline is **green**. Go to **Done**.
   - If status is `in_progress` / `queued` → wait, then re-check. Poll with a delay matched to typical job time (don't busy-poll).
   - If `completed` + `failure` → continue.

2. **Pull the failing logs only** (cheap on context — skips passing steps):
   ```
   gh run view <run-id> --log-failed
   ```
   Identify each failed job and the failing step. Prioritise **deployment jobs** (deploy/release/publish stages) — they're the user's stated focus and usually gate everything downstream.

3. **Classify the failure.** This decides the route:
   - **Code/config failure** (test failure, type error, lint, build break, bad workflow YAML, broken Terraform/manifest) → **auto-fixable**. Go to step 4.
   - **Environment failure** (missing/expired secret, IAM/permissions denied, quota, a flaky or down external service, anything needing a human credential or decision) → **not auto-fixable**. Go to **Escalate**.
   - If genuinely ambiguous, attempt one diagnosis pass; if the root cause turns out to be environmental, escalate.

4. **Fix it.** Invoke `/diagnose` on the failing job, passing the relevant `--log-failed` excerpt as the symptom. Let `/diagnose` reproduce locally where possible, find root cause, and apply the fix. Keep the change scoped to that one failure.

5. **Land the fix.** Commit with a Conventional Commit (`fix(ci): ...` / `fix(deploy): ...`), then push to the branch. (This dotfiles-style convention: commit straight to the working branch — no PR ceremony unless the repo requires it.)

6. **Re-check.** A push triggers a new run. Go back to step 1 against the new run id. Each loop should reduce the failing-job count; if a fix doesn't change the failure, treat it as not-yet-root-caused and diagnose deeper rather than re-pushing the same change.

## Escalate (not auto-fixable)

When step 3 lands on an environment failure, or the same failure survives 2 fix attempts:

1. **Stop the loop.** Do not keep pushing.
2. **Summarise the blocker**: which job, the failing step, the root cause, and specifically what a human must do (e.g. "rotate `AWS_DEPLOY_ROLE` secret", "grant `packages:write`").
3. **Ping Discord** via `/discord-ping work [blocked] CI red on <branch>: <one-line blocker + needed action>`. Use the `work` channel for work repos. If neither Discord webhook env var is set, skip the ping silently and just report in-session.

## Done (pipeline green)

When the latest run is `success`, `/goal` will detect it and stop auto-continuing. On that final turn:

1. Confirm the *whole* pipeline is `success` (not just that your last fix's job passed) — run `gh run view <latest-run-id>` so `/goal` has the proof it checks against.
2. Summarise: which failures were fixed and how (one line each), and anything skipped/escalated.
3. Ping Discord with a completion message (`/discord-ping work CI green on <branch> ...`) if a webhook is configured and this was an autonomous/long run.

## Guardrails

- **One failure per iteration.** Resist batching unrelated fixes — it muddies which change fixed what when the next run comes back.
- **Never disable, skip, or `continue-on-error` a job to force green.** That's faking the result, not fixing it. If a test is genuinely flaky, say so and escalate rather than silencing it.
- **Don't touch secrets or workflow permissions yourself** — those are the escalation cases.
- **Cap the loop.** `/goal` will happily auto-continue forever. If you've gone ~5 iterations without reaching green, run `/goal clear`, stop, and escalate with a summary of what's been tried — you're likely missing a root cause and further auto-continues just burn tokens.
