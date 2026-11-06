---
name: semi-auto-mode
description: Operating discipline for a run where the user is present but wants you to drive — decide and act autonomously on everything minor, and only interrupt for genuinely important decisions (irreversible/outward-facing actions, breaking contract changes, real forks with no repo signal). Questions are non-blocking and queued one at a time. Invoke when the user says "semi-auto", "/semi-auto-mode", "handle the easy stuff yourself and only ask me if it's important", or when another skill (e.g. /review-resolve) runs fix work under it. For a fully AFK run where nobody will answer, use /autonomous-mode instead.
---

# Semi-auto mode

The user is around but doesn't want to be consulted on routine calls. Default to acting.
Interrupt only when the decision is genuinely theirs **and** it matters.

This differs from `/autonomous-mode` in one way: there *is* someone to ask, so the
"truly important" decisions go to them instead of a griller/expert pair. Everything else —
verification, small commits, conventional-commit messages, parallelism — follows
`/autonomous-mode`'s rules.

## The ask threshold

Ask **only** when the decision falls into one of these:

1. **Irreversible or outward-facing beyond what was authorised** — pushing to a shared
   branch, force-push, deleting data/branches, deploying, messaging someone, publishing.
   (If the task already authorised it, e.g. "reply and resolve the threads", that action
   doesn't need asking.)
2. **A breaking or reshaping contract change** — changing a public API, DB schema,
   cross-package type, or event shape in a way that callers/other layers must adapt to,
   or anything that contradicts an ADR or spec.
3. **A real fork with no repo signal** — two reasonable options with materially different
   outcomes, and nothing in the code, docs, ADRs, or conventions tips it.

**Minor changes are handled autonomously, even if they touch a contract** — adding an
optional field, widening a type, an internal rename, a local refactor, a test fix. Decide,
do it, and record the call in the commit message (or PR reply) so it's reviewable later.

When unsure whether something clears the bar: if being wrong costs a `git revert`, act; if
it costs a migration, a broken consumer, or an awkward conversation, ask.

## Work in parallel with sub-agents by default

Semi-auto only pays off if the user isn't waiting on serial work. So:

- **Fan out independent work to sub-agents** (`Agent`, `general-purpose` or a fitting domain
  agent) in a **single message** so they run concurrently. Group by file/concern; work that
  touches the same file or region goes to one agent, never two.
- **Keep the main thread free for the user.** Sub-agents do the edits; the main thread
  answers, asks the queued questions, and reconciles results. Don't block the conversation on
  a long fix you could have delegated.
- **Batch independent tool calls** (reads, greps, `gh`/`git` queries) in one message.
- **Mind RAM before heavy fan-out** — follow the CLAUDE.md memory rules (check
  `memory_pressure`, arm the background watcher, scope each agent's tests to touched files,
  one `tsc` per package at a time). Say in one line how many heavy agents you launched.
- **Reconcile after fan-out.** When agents touched overlapping or shared state, check they
  didn't conflict or make contradictory assumptions before pushing.

## How to ask

- **Non-blocking.** Park the item that needs the answer and keep working on everything
  independent of it. Don't idle waiting.
- **Queue, then ask one at a time.** Each question: one-line context, the options (2–3),
  your recommendation first. Don't stack a multi-question dump.
- **Hard blocks are the only immediate interrupt** — missing credential, contradictory
  instructions, an external system down. Ask straight away, still keep independent work
  moving.

## When running as a sub-agent

A sub-agent spawned under this mode can't talk to the user. It must:
- do everything below the threshold itself,
- **not** guess on anything above it — leave that item untouched and return it in its
  report as `NEEDS_DECISION: <one-line question + options + recommendation>`,
- report back: what it changed, which checks it ran (with result), commit hash(es), and any
  `NEEDS_DECISION` items. The parent agent owns the question queue.
