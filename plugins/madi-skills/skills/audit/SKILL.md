---
name: audit
description: Read-only readability audit of a branch/stack/diff — can a human tell what this code
  is for? Works out the scope and the repo's ground truth once, runs four checks in parallel
  (/naming-audit, /comment-audit, /code-shape-audit, /placement-audit), then merges them into one
  ranked report with overlaps removed. Use when the user says "audit this branch", "readability
  pass", "is this code readable", "does this feel AI-written", or "/audit". For a single check,
  run that skill directly. Not a bug hunt (/code-review) and doesn't apply fixes (/simplify).
---

# Readability audit

Rules for scope, ground truth, calibration and finding format: `~/.claude/skills/audit/shared.md`.
Read it first. Read-only throughout.

## 1. Scope and ground truth (once, here)
Do the Scope and Ground truth steps from shared.md yourself, then write a short brief:
- base..tip, the commit list, and the changed files (minus generated ones);
- glossary terms and banned words;
- where the product's UI copy lives;
- the repo's conventions for naming, comments/docstrings and layering, with a pointer to one
  representative pre-scope file per layer;
- relevant repo rules and ADRs.
If the user only asked for some of the checks, run only those.

## 2. Run the checks in parallel
Launch one `general-purpose` Agent per check, all in a single message. Each prompt contains:
the brief, and "Read `~/.claude/skills/<check>/SKILL.md` and `~/.claude/skills/audit/shared.md`
and follow them. Skip Scope and Ground truth; use this brief instead. Read-only: no edits,
commits or checkouts. Return findings in the shared finding format, plus your leave-alone list,
and (naming-audit only) the drift table. No prose summary."
The checks are read-only and light, so no memory check is needed before fanning out.

## 3. Merge
- Collapse findings that point at the same line or the same root cause into one, and keep the
  link between them. Common pairs: a comment that exists because a name is bad (fix the name,
  drop the comment); a function doing two jobs that is also in the wrong layer (one move fixes
  both).
- Where two checks disagree, pick one and say why in a line.
- Re-rank across checks by how much each change helps a reader understand what the code is for.

## Output (≤1200 words)
- One-paragraph diagnosis: where the purpose gets lost in this code, across all four checks.
- Top 15 changes, ranked, in the shared finding format, each tagged with its check(s).
- Naming drift table (from /naming-audit).
- Placement: the layer model in a few lines, then the moves.
- Comments to cut / rewrite / add, with one before → after example.
- Remaining smaller findings, one line each, grouped by check.
- Leave-alone list with the convention each one follows.
No edits. The user picks what to apply.
