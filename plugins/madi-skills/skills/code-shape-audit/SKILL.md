---
name: code-shape-audit
description: Read-only audit of whether the structure of a branch/stack/diff shows what the code
  is for — functions that do more than their name says, purpose buried in an expression, magic
  values, clever one-liners, and indirection or file splits that make the reader hop. Use when the
  user says "audit the code shape", "is this code readable", "I can't tell what this does", or
  "/code-shape-audit". Also run as one of the checks inside /audit.
---

# Code-shape audit

Follow `~/.claude/skills/audit/shared.md` for read-only rules, scope, ground truth, calibration
and finding format.

The test: **could a reader who has never seen this code tell what it is for, and what it
does, from the structure alone?** This is not a complexity or efficiency review: duplication,
deep nesting, dead code and wasted work belong to `/simplify`. Flag something here only when the
shape hides the purpose.

## Look for (each with file:line and a sketch of the reshaped code)
1. Body does more than the name says: `syncUser` that also flags accounts. Propose splitting it
   into named steps, and **list every caller** that would have to call the new step, so the
   split doesn't silently drop behaviour.
2. Purpose buried in an expression: a `filter(...).length > 3` that is really asking "too many
   active devices?". Propose a named function or variable that asks the question.
3. Magic values: unexplained literals (`2592000000`, `3`, status codes, string keys). Propose a
   named constant, written in readable units (`30 * 24 * 60 * 60 * 1000`), plus a why-comment if
   the value is a policy choice.
4. Clever one-liners: dense chains, nested ternaries, or reduce tricks a reader has to unpick.
   Propose the plain version, and leave idioms the repo uses everywhere alone.
5. Mixed levels of abstraction: one function that orchestrates high-level steps and also does
   low-level fiddling inline. Propose pulling the low-level part out under a name.
6. Indirection that adds nothing: facades, one-line delegates and re-exports the reader has to
   step through to reach the real code.
7. Files split so finely the reader has to hop between several to follow one idea.

## Output (standalone run, ≤600 words)
- One-paragraph diagnosis: where the purpose gets lost.
- Ranked findings in the shared finding format, each with a short before → after sketch, and
  the caller list for any split.
- Leave-alone list with the convention each one follows.
