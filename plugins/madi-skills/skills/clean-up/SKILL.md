---
name: clean-up
description: Identifies and deletes session-generated artefacts (planning docs, specs, self-grill outputs, code review working docs, .claude/specs) that were created during development but have no value in the merged codebase. Invoke when the user says "clean up docs", "remove slop docs", "clean up before merge", "tidy up the branch artefacts", or "clean up the session docs".
---

# Clean Up Session Artefacts

Audit the current branch for docs and files created during the development session (planning, review, grilling, specs) rather than as permanent codebase additions. Present a classified list for confirmation, then delete only what the user approves.

## Process

### 1. Discover what was added

```bash
# Tracked files added on this branch
git diff --name-only --diff-filter=A $(git merge-base HEAD origin/develop 2>/dev/null || git merge-base HEAD develop) HEAD

# Untracked files (check .claude/specs/, docs/, etc.)
git ls-files --others --exclude-standard
```

### 2. Read content before classifying

For every non-code file discovered, **read it** before assigning a verdict — filename heuristics alone are unreliable. Look for:
- Frontmatter `Status:` fields (e.g. `draft`, `pre-grill`, `sharp (self-grilled)`) → DELETE
- Prose explaining WHY something was built (design decisions, trade-offs, deferred items) → KEEP
- Grilling transcripts, implementation specs, fix plans → DELETE
- "Not a bug (verified)" sections, named deferred decisions → lean KEEP

### 3. Classify each file

Assign one of three verdicts:

**DELETE** — created to serve the session, now superseded by the code:
- `.claude/specs/` — all files (draft plans, self-grill specs, implementation specs)
- `.planning/` — if tracked (should be gitignored; if not, remove and add to gitignore)
- Files with frontmatter `Status: draft`, `pre-grill`, or `self-grilled`
- Files whose entire purpose was to plan or review work that is now in commits

**KEEP** — has genuine value for future readers of the codebase:
- Design specs explaining WHY (architecture decisions, trade-offs, deferred items, verified-not-a-bug rationale) — e.g. `DESIGN-SPEC.md`
- ADRs (`docs/adr/`)
- User-facing operational docs (how to run a script, how to use a feature)
- Agent files that have clear ongoing utility beyond this branch — read the `description:` field; if it's well-formed and covers a domain the codebase will keep touching, lean KEEP

**ASK** — genuinely ambiguous; ask the user before deciding:
- `CODE-REVIEW.md` files — lean KEEP if the file contains deferred rationale, "verified not a bug" sections, or named architectural decisions; lean DELETE if it's purely a list of findings that are all resolved and in commits
- Agent files added on this branch but unrelated to the feature — read the description; if it's well-formed and future-useful, suggest keeping it (or moving to `~/.claude/agents/` globally); if it looks accidental or low-quality, suggest deleting
- Any doc in `docs/` that doesn't clearly fit KEEP or DELETE

### 4. Present the classification

Show a **numbered list** before touching anything — numbers are required so the user can skip specific items:

```
Session artefacts to DELETE:
  1. .claude/specs/foo-draft.md        [untracked] — draft pre-grill spec
  2. .claude/specs/foo-final.md        [untracked] — self-grill implementation spec
  3. docs/feature/CODE-REVIEW.md       [tracked]   — code review working doc (all findings resolved)

Files to KEEP (no action):
  - docs/feature/DESIGN-SPEC.md        [untracked] — design rationale, worth keeping
  - .claude/agents/my-agent.md         [tracked]   — useful ongoing agent

Files to ASK about:
  ? .claude/agents/unrelated-agent.md  [tracked]   — unrelated to this feature; keep or delete?

Note: [tracked] deletions will be staged with git rm and require a commit.
      [untracked] deletions are permanent immediately — not recoverable from git.
      All [tracked] deletions are recoverable via git after commit.
```

Also flag any KEEP files that are **untracked** — they may need to be staged:
```
Note: docs/feature/DESIGN-SPEC.md is KEEP but currently untracked — run `git add` if you want it in the PR.
```

Ask: **"Delete the items listed above? Enter y to delete all, n to cancel, or numbers to skip (e.g. '1 3' to skip items 1 and 3)."**

### 5. Delete approved files

For each confirmed deletion, check whether tracked or untracked:

```bash
# Tracked files:
git rm <file>

# Untracked files:
rm <file>

# Remove any directories that are now empty (only the ones affected):
for dir in $(dirname <deleted-files> | sort -u); do
  find "$dir" -type d -empty -delete 2>/dev/null || true
done
```

### 6. Commit tracked deletions — with confirmation

If any **tracked** files were deleted, show the staged diff and ask before committing:

```
Staged deletions:
  deleted: .claude/agents/pbs-scripting-expert.md
  deleted: docs/feature/CODE-REVIEW.md

Commit these as "chore: remove session artefacts before merge"? (y/n)
```

If yes:
```bash
git commit -m "chore: remove session artefacts before merge"
```

Note: lefthook will run on this commit (prettier, lint, typecheck). If hooks fail, fix them before proceeding.

## Classification heuristics (quick reference)

| File pattern | Default | Notes |
|---|---|---|
| `.claude/specs/*` | DELETE | Always session artefacts |
| `.planning/*` (if tracked) | DELETE | Should be gitignored; also add to .gitignore |
| `*-PLAN.md`, `*-RESEARCH.md` | DELETE | Planning artefacts |
| `*-CONTEXT.md` in `.claude/` | DELETE | GSD context docs |
| `*-CONTEXT.md` in `docs/` or repo root | ASK | Could be a Matt-Pocock domain vocabulary doc — read it first |
| `DESIGN-SPEC.md` | KEEP | Explains WHY |
| `docs/adr/*` | KEEP | Always keep |
| `CODE-REVIEW.md` | ASK | Read content — keep if WHY rationale exists, delete if pure findings list |
| `.claude/agents/*.md` — well-formed, future-useful | KEEP | Read description; if covers a domain the codebase will keep touching, keep |
| `.claude/agents/*.md` — accidental / low-quality | ASK | Suggest delete or move to global `~/.claude/agents/` |
| Grilling transcript files | DELETE | |

## Hard rules

- **Never delete code files** (`.ts`, `.tsx`, `.py`, `.tf`, etc.), tests, or config
- **Never delete without showing the numbered list and getting confirmation**
- **Read the file content** for anything not obviously in `.claude/specs/` before classifying
- When in doubt, classify as **ASK** rather than DELETE
- A doc explaining WHY is always KEEP; a doc explaining HOW we got to the code is DELETE
