---
name: agent-creator
description: Scaffold a new Claude Code subagent (the kind invoked via the Agent tool). Use when the user asks to "create an agent", "make a subagent", "add an expert for X", or "/agent-creator" — OR when, mid-task, you notice a recurring specialised job (e.g. dense log triage, security review, migration planning) where having a dedicated agent would help on this and future runs. Writes the agent file to `~/.claude/agents/` (global) or `<repo>/.claude/agents/` (project).
---

# Agent creator

Turn a need for specialised expertise into a working subagent file. Subagents are spawned via the `Agent` tool with `subagent_type: <name>` and run in their own context.

## When to self-invoke (autonomous mode)

You may invoke this skill on your own — without being asked — when *all* of these hold:

1. You're in autonomous / long-running work.
2. You're about to do (or just did) a task that is **specialised, repeatable, and well-scoped** — something you'd want done the same way next time.
3. No existing agent in the listed `Available agent types` already covers it.

Examples that warrant a new agent: "review SQL migrations for lock safety", "triage flaky test logs", "write ADRs from a design discussion", "audit a PR for secrets". Examples that do **not**: one-off questions, generic coding, anything the `Explore` / `general-purpose` / `Plan` agents already handle.

When self-invoking, skip the user-facing questions in step 1 below and infer answers from context. Save the agent, then mention what you created and why in one sentence.

## Process

1. **Gather requirements.** If the user explicitly asked, use `AskUserQuestion` for anything unclear:
   - What is the agent's job? (one sentence)
   - What triggers should invoke it? (phrases / situations)
   - Global (`~/.claude/agents/`) or project-level (`<repo>/.claude/agents/`)?
   - Tool restrictions? Default to `*` (all tools). Restrict only if there's a clear safety reason (e.g. read-only research agent → no `Edit`/`Write`/`Bash`).
   - Model preference? Default to inherit (omit field). Use `opus` for hard reasoning, `sonnet` for balanced, `haiku` for cheap/fast.

2. **Pick a kebab-case name.** Short, descriptive. Examples: `migration-reviewer`, `log-triager`, `adr-writer`. Avoid generic names like `helper`, `expert`, `assistant`.

3. **Write the description carefully.** The dispatcher reads this to decide whether to route to the agent. Make it:
   - Specific about *what* the agent does and *when* to use it.
   - Include trigger phrases verbatim if the user gave any.
   - Note when *not* to use it, if there's overlap with another agent.
   - 1–3 sentences.

4. **Write the agent file** at `<dir>/<name>.md` with this frontmatter:

   ```markdown
   ---
   name: <kebab-name>
   description: <what + when, 1-3 sentences>
   tools: <comma-separated list, or omit for all>
   model: <opus|sonnet|haiku, or omit to inherit>
   ---

   # <Title>

   <One-paragraph overview: what the agent does, what it produces.>

   ## Instructions

   <Numbered, imperative steps. Be concrete: which tools, what to ask, what to return. Remember the agent starts with no conversation context — anything it needs must be in the spawn prompt or discoverable at runtime.>

   ## Output format

   <What the agent should return to the caller — a report, a diff, a checklist, etc. Keep it tight; the caller relays a summary to the user.>
   ```

5. **Save.**
   - Global: `~/.claude/agents/<name>.md`
   - Project: `<repo>/.claude/agents/<name>.md`
   - `mkdir -p` the directory first.

6. **Confirm.** Tell the user the path and that it'll appear in the `Available agent types` list on the next prompt — invokable via the `Agent` tool with `subagent_type: <name>`.

## Design rules

- **One agent, one job.** If the description has "and", consider splitting.
- **Agents are not skills.** Skills are instructions the main agent loads; agents are spawned processes with their own context. Use an agent when the work would pollute the main context or benefits from a focused system prompt.
- **Triggers belong in the description.** The body is *how*; the description is *when to route here*.
- **Write to the agent in imperative voice.** ("Read X. Return Y.") Not third person ("This agent will...").
- **Tool restrictions are a feature, not paranoia.** Restrict only when it materially shapes behaviour (e.g. forcing a research agent to actually research instead of edit).
- **No emojis** unless the user explicitly asks.
