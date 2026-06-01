---
name: tell-me-what-you-can-do
description: Give a concise, grouped TLDR of the skills and agents available in this environment — what Madi authored, the Matt-Pocock engineering skills, GSD, Superpowers, and anything else — and recommend the few most useful for what the user is doing right now. Use when the user says "tell me what you can do", "what skills do I have", "what can you help with", "give me a tour", or runs /tell-me-what-you-can-do.
---

# Tell me what you can do

Produce a concise, grouped tour of the skills and agents available here, then point the user at the few most useful for their current situation. This is the onboarding entry point for someone who just installed the `madi-skills` plugin.

## Step 1 — Decide the mode

Look at the conversation so far (excluding this invocation):

- **Cold start** (no prior task context — first message, or only greetings): give the **full grouped overview** (Step 3), then a short "where to start" nudge.
- **In-context** (there's real work underway — a bug, a feature, a review, a plan): lead with a **tailored recommendation** (Step 4) of the 2–4 skills that fit what's happening *now*, then offer the full overview as a follow-up ("say `full` for everything").

## Step 2 — Scan what's actually installed

Do not rely on memory — different machines have different things installed. Discover at runtime:

- Skills: list `~/.claude/skills/*/` and read each `SKILL.md` frontmatter `description`. Also note plugin-namespaced skills (they appear as `plugin:skill` in the available-skills list).
- Agents: list `~/.claude/agents/*.md` and read each frontmatter `description`.

Bucket each item by origin:

| Bucket | How to identify |
| --- | --- |
| **Madi's custom skills/agents** | Anything not matched by a rule below. These are the headline of this plugin. |
| **Matt-Pocock engineering skills** | Names in this set: `to-issues`, `to-prd`, `triage`, `diagnose`, `tdd`, `improve-codebase-architecture`, `zoom-out`. (Madi authored these *to* the Matt-Pocock philosophy — call them out as their own group so the coworker understands the convention.) |
| **GSD** | Name starts with `gsd-`. |
| **Superpowers** | Name starts with `superpowers:`. |
| **Other plugins / built-ins** | Any other `plugin:skill` namespace (e.g. `frontend-design:`, `commit-commands:`), or Anthropic built-ins. Summarise briefly; don't enumerate exhaustively. |

Note: a few skills (`diagnose`, `tdd`, `zoom-out`) are both Madi-authored *and* aligned to the Matt-Pocock convention. List them under Matt-Pocock and don't double-count.

## Step 3 — Full grouped overview

Output in this shape. Keep each line to a **one-clause TLDR** — this is a tour, not the manual. Don't list every skill; lead with the high-value ones and collapse the long tail ("…and N more for X").

```
## Madi's custom skills
- spec-driven-development — spec the design goals first, then build section-by-section with TDD
- swe-best-practices — flag DRY/SRP/coupling violations in-flight, before the bad code is written
- grill-me / grill-with-docs — get interrogated on a plan until it's sharp
- self-grill — same, but agent-vs-agent for autonomous runs
- research-decision — parallel-research a "what should we use for X" decision into a cited report
- clean-up / handoff — tidy session artifacts; compact context for another agent
- …and more (caveman, prototype, walk-me-through, …)

## Madi's custom agents
- topic-researcher — deep-dive a technical topic into a cited briefing
- refactor-agent — behavior-preserving refactors / ADR implementation
- frontend-ui-architect, workflow-optimizer, autonomous-griller

## Matt-Pocock engineering skills (domain-driven workflow)
- diagnose, tdd, zoom-out, improve-codebase-architecture, triage, to-issues, to-prd
- These assume a repo with CONTEXT.md / docs/adr/ conventions. Run /setup-matt-pocock-skills to scaffold a repo for them.

## External (if installed)
- Superpowers — discipline skills (TDD, debugging, brainstorming) with strong enforcement
- GSD — heavyweight end-to-end planning framework (see install note below)
- <other plugins present>
```

Adapt the bullets to what the scan actually found. If a bucket is empty, omit it. If GSD/Superpowers aren't installed, say so in one line and link the install note.

## Step 4 — Tailored recommendation (in-context mode)

State what the user appears to be doing in one sentence, then recommend the 2–4 skills that fit, each with *why now*. Examples:

- Debugging a flaky/failing test → `/diagnose` (or `/diagnose tdd` to lock it with a failing test first), then `/code-review`.
- Starting a non-trivial feature → `/grill-me` to sharpen the plan, then `/spec-driven-development`, with `/swe-best-practices` running alongside.
- Facing an architecture/library choice → `/research-decision`.
- Messy codebase area → `/zoom-out` to map it, then `/improve-codebase-architecture`.

End with: "Say `full` for the complete grouped list."

## Step 5 — GSD install note (only if GSD is absent and relevant)

If the user asks about GSD, or a recommendation would benefit from it and it's not installed, surface this — **do not auto-install**, just inform:

> GSD is a heavyweight planning framework (phases, roadmaps, ~67 skills). It's **not bundled** in this plugin and installs separately. Two cautions before you do:
> - **Security:** GSD ships hooks that read files and run on your prompts. Review what you're enabling before trusting it on a work machine.
> - **Fork confusion:** the project appears to have been renamed/forked recently and the canonical source is unclear. Confirm the current official repo/package name yourself before installing — don't take a stale link on faith.
>
> If you want it, check the current GSD project for install instructions rather than relying on a name that may be out of date.

Keep this note out of the output entirely unless GSD is genuinely relevant — don't lecture about a tool the user didn't ask for.

## Style

- Concise. One clause per skill. The goal is "oh, I have all this" in 20 seconds, not a wall of text.
- Use the real `/namespace:skill` form for plugin skills if that's how they're invoked here.
- No emojis.
