---
name: skill-creator
description: Scaffold a new Claude Code skill. Use when the user wants to create, add, or author a new skill (e.g. "make a skill that does X", "create a skill for Y", "/skill-creator"). Walks through naming, writing a tight description, and saving SKILL.md to the right location.
---

# Skill creator

Your job: turn a rough idea into a working skill file at `~/.claude/skills/<name>/SKILL.md` (or project-local `.claude/skills/<name>/SKILL.md`).

## Process

1. **Gather requirements.** Ask the user (use AskUserQuestion if more than one thing is unclear):
   - What should the skill do? (one sentence)
   - When should it trigger? (the phrases/situations that should invoke it)
   - User-level (`~/.claude/skills/`) or project-level (`.claude/skills/`)?
   - Does it need scripts/assets, or just instructions in SKILL.md?

2. **Pick a kebab-case name.** Short, descriptive, verb-or-noun. Examples: `pr-summary`, `db-migrate`, `release-notes`. Avoid generic names like `helper` or `tool`.

3. **Write the description carefully.** This is the most important field — Claude reads it to decide whether to invoke the skill. Make it:
   - Specific about *what* the skill does
   - Explicit about *when* to trigger (include trigger phrases the user might say)
   - One to three sentences max

4. **Write SKILL.md** using this format:

   ```markdown
   ---
   name: <kebab-name>
   description: <what + when, 1-3 sentences>
   ---

   # <Title>

   <One-paragraph overview of what the skill does.>

   ## Process / Instructions

   <Numbered steps the agent should follow. Be concrete: which tools to use, what to ask the user, what to produce.>

   ## Examples (optional)

   <Concrete input → output examples if the format matters.>
   ```

5. **Save to the right location.**
   - User-level: `~/.claude/skills/<name>/SKILL.md`
   - Project-level: `<repo>/.claude/skills/<name>/SKILL.md`
   - Use `mkdir -p` first via Bash, then Write the file.

6. **Confirm.** Tell the user the path, that they can invoke with `/<name>`, and that newly created skills are picked up on the next prompt (no restart needed).

## Design rules

- **One skill, one job.** If the description has "and", consider splitting.
- **Skills are not subagents.** SKILL.md is instructions the *main* agent loads when invoked — keep it terse and imperative ("Do X, then Y"), not narrative.
- **Triggers belong in the description.** The body is *how*; the description is *when*. If the user describes triggers ("whenever I say release notes"), put those words verbatim into the description.
- **No emojis** unless the user explicitly asks.
- **Don't invent file paths or tools** the user hasn't mentioned. If the skill needs to know about project structure, instruct the agent to discover it at runtime instead of hard-coding.

## Anti-patterns to avoid

- Long preambles or motivation sections — the agent already knows it was invoked
- Re-explaining how Claude Code works
- Listing every possible edge case; cover the common path and let the agent reason about the rest
- Describing the skill in third person ("This skill will...") — write in imperative voice to the agent ("Do X")
