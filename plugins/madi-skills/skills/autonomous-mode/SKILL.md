---
name: autonomous-mode
description: Establishes the operating discipline for a fully-autonomous run where the user is AFK and will NOT answer questions. Invoke when the user says "go autonomous", "work autonomously", "full autonomous mode", "don't stop to ask me questions", "/loop", or otherwise signals they're stepping away and you must drive to completion without them.
---

# Autonomous Mode

You are running unattended. The user will not answer questions. Your job is to drive the task to a verified, committed, pushed conclusion making every decision yourself — and to never block waiting on input.

## Core rules

1. **Never ask the user a question.** No `AskUserQuestion`, no "should I…?", no waiting. If a decision is genuinely the user's to make and you cannot infer it, pick the most reversible / conservative option, record the assumption in your work (commit message, doc, or a `DECISIONS.md`), and continue. Only ping (see below) if truly hard-blocked.

2. **Self-grill instead of asking.** When you'd normally ask the user to validate a plan or design, spawn the `autonomous-griller` sub-agent paired with a domain-expert sub-agent (use `/self-grill`) and let them sharpen it. Scale rounds to risk: 1 for a small refactor, several for architecture.

3. **Verify everything before claiming done.** Run the tests, the typecheck, the lint, the build — whatever the repo provides. Paste/observe real output. "It should work" is not acceptable. Use `superpowers:verification-before-completion`.

4. **TDD and spec-driven by default.** Write the failing test first (`superpowers:test-driven-development`); root-cause before fixing (`superpowers:systematic-debugging`); for non-trivial work write a short spec first (`/spec-driven-development`).

5. **Commit in small, verified increments.** One logical change per commit, tests green at each. Use conventional-commit messages. Branch off the default branch if you're on it.

6. **Track progress with the task list.** Create tasks for each phase up front; mark in_progress/completed as you go so the run is auditable.

## Decision-making without the user

When you hit a fork:
- **Conventional default exists?** Take it, note it.
- **Reversible vs irreversible?** Prefer the reversible path. Never do something destructive or externally-visible (force-push, delete data, send email, deploy) unless the task explicitly authorized it.
- **Genuinely ambiguous and high-stakes?** Spawn a griller+expert pair to reason it out. Proceed on their conclusion.
- **Truly hard-blocked** (missing credential, external system down, contradictory instructions that can't be reconciled)? Stop that thread, `/discord-ping` with a `[blocked]` tag explaining what you need, and continue any other independent work. Do not spin.

## Pinging the user

Use `/discord-ping` at meaningful state changes only — run started, milestone reached, blocked, run finished, unexpected failure. Identify which session/branch you are. Don't narrate every step. If no webhook is configured, skip silently.

## Parallelism

Run independent work concurrently — dispatch multiple sub-agents in one message (`superpowers:dispatching-parallel-agents`), or kick off long-running commands (deploys, CI) in the background and continue other tasks while they run. Don't idle waiting on a deploy if there's a skill to write or a review to run.

## Definition of done

The run is complete only when:
- All task-list items are completed (or explicitly deferred with a recorded reason)
- Tests + typecheck + lint + build are green (verified, not assumed)
- Work is committed and pushed
- Any review loop the task asked for (e.g. CodeRabbit) has converged to no outstanding issues
- A final `/discord-ping` summarizes what shipped

## Red flags — you're doing it wrong

- About to call `AskUserQuestion` → STOP, decide yourself or self-grill
- "I'll just wait for them to confirm" → they're AFK; proceed
- Claiming success without running the verification commands → run them
- Writing production code before a failing test → delete it, start with the test
- Polling a deploy in a tight loop doing nothing else → background it, do other work
