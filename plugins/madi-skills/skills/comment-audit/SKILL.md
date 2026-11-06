---
name: comment-audit
description: Read-only audit of the comments and docstrings in a branch/stack/diff — flags comments
  that repeat the code, narrate steps, carry ticket history, sound AI-generated, have gone stale,
  or are longer than what they describe, and places that need a "why" but have none. Use when the
  user says "audit the comments", "comments are too verbose", "docstrings feel AI-written", or
  "/comment-audit". Also run as one of the checks inside /audit.
---

# Comment audit

Follow `~/.claude/skills/audit/shared.md` for read-only rules, scope, ground truth, calibration
and finding format.

The test for every comment: **does it tell the reader something the code can't?** That means
the why, the intent, a non-obvious constraint, or a trap. Anything else is noise that hides the
comments that matter.

## Look for (each with file:line and a before → after)
1. Repeats the code: `// increment the counter` above `count++`; a docstring that restates the
   signature in prose.
2. Narrates steps: `// Now we loop over the items`, `// Step 3: save`. The code already says
   this; if the steps aren't clear, that's a code-shape problem, not a missing comment.
3. History instead of intent: ticket IDs, "previously this did X", "changed per review",
   "fixed bug where…". That belongs in the commit message or PR.
4. AI-sounding filler: "This robust helper ensures…", "comprehensive", "seamlessly", hedging,
   restating the obvious with confident adjectives.
5. Too long for what it describes: a docstring longer or more complicated than the function;
   paragraphs where one line would do.
6. Stale or lying: the comment describes behaviour the code no longer has.
7. Covering for a bad name: a comment that exists only because the name doesn't say what the
   thing is. Propose the rename and delete the comment.
8. Missing why: code that is genuinely surprising (a workaround, an ordering requirement, a
   magic number, a deliberate "does NOT do X") with nothing explaining it. Propose the comment.

## Don't flag
- A docstring for merely existing, when the repo or the user's instructions require one (e.g. a
  module docstring on every file). Judge its content, not its presence.
- Comments that follow a documented repo convention (license headers, lint-disable reasons,
  generated-code markers).

## Output (standalone run, ≤600 words)
- One-paragraph diagnosis: which pattern is doing the most damage.
- Comments to **cut**, **rewrite** and **add**, ranked, in the shared finding format with a
  before → after for each rewrite/add.
- Leave-alone list with the convention each one follows.
