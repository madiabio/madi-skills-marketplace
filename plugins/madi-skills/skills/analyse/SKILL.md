---
name: analyse
description: Lightweight critical analysis of a design decision or proposal — weighs pros/cons, spots holes, and actively pushes back if the idea has problems. Trigger when the user floats a design choice, asks "what do you think?", or presents a plan for quick gut-check before committing to deeper research. Does NOT do deep research — that's /discuss-decision. The goal is fast, honest, unbiased analysis that does not default to agreement.
---

# Analyse

Quick critical analysis of a proposal. The primary job is to **find problems first**, then weigh tradeoffs. Do not anchor on the user's framing or default to agreement — if the idea has holes, say so directly.

## Instructions

1. **Restate the proposal in one sentence.** Strip the framing; name only what is actually being proposed. This keeps the analysis honest and not influenced by how the user framed it.

2. **Check relevant context in parallel — take only what's needed, skip the rest:**
   - Codebase: grep/read files that are directly implicated (schema, config, infra, relevant service code).
   - Session context: what decisions, constraints, or goals have already been established in this conversation.
   - Docs/MCP: if Context7 is available (`mcp__context7__*`) and the proposal involves a library or framework, query it for relevant behaviour or gotchas. Do not query it for things already known from the codebase.
   - Do NOT do broad web research — that's /discuss-decision's job.

3. **Identify failure modes first.** Before listing any pros, explicitly ask: *Under what conditions does this go wrong? What does this break, miss, or assume that might not hold?* List these as "Risks / holes" — be specific and reference evidence from the codebase or docs where possible.

4. **Then list genuine advantages.** Only real ones — do not pad this list to soften the risks.

5. **Give a verdict.** One of:
   - **Looks solid** — proceed, with caveats noted
   - **Workable with changes** — state the minimum changes needed
   - **Has a real problem** — state what needs to be resolved before committing

6. **If you disagree with the user's conclusion, say so directly.** Do not soften disagreement with "it depends" or excessive hedging. If the proposal has a clear flaw, name it and explain why. The user can override — but they should have to, not be led there by omission.

## Format

Keep it short. Use:
- **Proposal:** one sentence restatement
- **Risks / holes:** bullet list (most serious first)
- **Advantages:** bullet list
- **Verdict:** one of the three options above, 1–2 sentences

No long preambles. No "great question". No section headers beyond the above.
