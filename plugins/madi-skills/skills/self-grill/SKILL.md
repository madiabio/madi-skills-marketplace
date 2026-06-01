---
name: self-grill
description: Stress-test a draft plan in autonomous mode by spawning the `autonomous-griller` sub-agent paired with a domain-expert sub-agent. They iterate (griller asks, expert defends) until the spec is sharp, then this skill writes a clean SDD spec document to disk for the next stage to consume. Use when the main agent is in autonomous mode (overnight, `/loop`, user said "go autonomous") and is about to commit to a non-trivial implementation. Do NOT use when the user is present — use `/grill-me` or `/grill-with-docs` instead.
---

# Self-grill

Orchestrate a paired griller+expert grilling session, fully autonomous, and produce a sharp SDD spec the next stage can implement against.

## Preconditions

- Main agent is in autonomous mode (user is AFK / overnight / `/loop`). If the user is present and responsive, stop and use `/grill-me` or `/grill-with-docs` instead.
- You have a *draft* plan to grill. If you don't, draft one first (a short markdown plan: goal, approach, key decisions, risks) before invoking this skill.
- The **`autonomous-griller`** agent exists in `Available agent types`. This skill spawns *that specific agent* as the griller — not `general-purpose`, not `Plan`, not any other agent. If `autonomous-griller` is missing, halt and tell the user (it lives at `~/.claude/agents/autonomous-griller.md`).

## Process

1. **Assemble the spawn context** for the sub-agents. Gather:
   - The draft plan (verbatim)
   - Task context — what's being built, why, in which repo
   - Complexity hint: `small-refactor` | `substantial-design` | `architecture-locking`
   - Relevant `CONTEXT.md` snippets (read once, pass excerpts — don't dump the whole file)
   - Relevant `docs/adr/*.md` snippets if any ADR touches this area
   - Domain — what kind of expert is needed (e.g. "Python async", "Postgres migrations", "Isabelle/HOL tactics")

2. **Pick or create the expert agent.**
   - Check `Available agent types` — if a fitting domain expert already exists, use it.
   - If not, spawn `agent-creator` first (or invoke `/agent-creator` directly) to scaffold one before continuing. Don't fall back to `general-purpose` for substantive domains — the point of pairing is *expertise*.

3. **Round 1 — spawn griller + expert in parallel.** Single message, two `Agent` tool calls:
   - `subagent_type: autonomous-griller` with the assembled context. This is the *only* acceptable griller — do not substitute `general-purpose`, `Plan`, or any other agent.
   - `subagent_type: <chosen-expert-agent>` with the same context + a directive to defend / refine / answer when the griller's output arrives.

   Wait for both to return. The griller produces questions; the expert produces their independent take on the plan.

4. **Round 2+ — feed forward.** Spawn `subagent_type: autonomous-griller` again with: original context + griller's prior round + expert's prior round, instructed to either deepen or declare sharp. Spawn the expert agent again with: original context + griller's new questions, instructed to answer point-by-point.

   Continue until the griller's verdict is **"Spec is sharp — proceed to implementation"**, OR until you hit the round budget for the complexity tier:
   - `small-refactor` → max 1 round
   - `substantial-design` → max 3 rounds
   - `architecture-locking` → max 6 rounds

   Hitting the budget is fine — declare sharp with whatever caveats remain.

5. **Handle escalations.** If the griller returns any `ESCALATE:` items at any round, do **not** keep grilling those points. Either:
   - Defer them into the final spec as `## Open questions (require human input)`, OR
   - If they block all further progress, use `/discord-ping` with `[blocked]` and stop.

6. **Write the SDD spec to disk.** Synthesise the final rounds into a clean spec document. Location: `.claude/specs/<short-slug>.md` in the current repo (create the directory if missing). If the repo already has a specs convention (e.g. `docs/specs/`, `specs/`), use it instead — check first.

   Spec format:

   ```markdown
   # <Title>

   **Status:** draft (self-grilled, autonomous)
   **Complexity:** <small-refactor | substantial-design | architecture-locking>
   **Grilled:** <N> round(s) by autonomous-griller + <expert-agent-name>

   ## Goal
   <one paragraph — what this change accomplishes and why>

   ## Approach
   <the agreed plan, post-grilling. Concrete enough that another agent could implement it.>

   ## Key decisions
   - **<decision>**: <choice> — <reasoning from grilling>
   - ...

   ## Out of scope
   - <things explicitly deferred or rejected>

   ## Risks & mitigations
   - <risk> → <mitigation>

   ## Test plan
   <how we'll know it works — concrete checks, not "write tests">

   ## Open questions (require human input)
   - <escalated item>, if any. Omit section if none.

   ## Grilling transcript (collapsed)
   <one-line summary per round; full transcripts not needed unless useful>
   ```

7. **Return the spec path** to the main agent so the next stage (implementation, ADR drafting, issue creation) can consume it. Optionally ping `/discord-ping` with `[milestone] spec ready at <path>` if the run has been long.

## Design rules

- **Two sub-agents per round, in parallel** — don't serialise unless the second depends on the first's output (it doesn't; griller and expert give independent takes that meet in your synthesis).
- **Don't grill the spec yourself.** Your job is orchestration + synthesis. The griller does the grilling.
- **Calibrate.** Don't burn 6 rounds on a small refactor. Don't wave through an architecture change in 1.
- **Write the spec to a real file.** The whole point is that the next stage can pick it up — an inline summary is not a spec.
- **Use the project's existing vocabulary.** If `CONTEXT.md` exists, the final spec must use those terms (not synonyms).
