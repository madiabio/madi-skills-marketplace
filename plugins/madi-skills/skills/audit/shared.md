# Shared rules for the readability audits

Used by /audit and by each check it runs (/naming-audit, /comment-audit, /code-shape-audit,
/placement-audit). When /audit runs a check, it has already done the Scope and Ground truth
steps and passes the results in; skip them and use what you were given.

## Read-only
Never edit, commit, checkout, stash or rebase. If another agent may be editing the working tree,
read only COMMITTED code via git (`git show <ref>:<path>`, `git diff <base>..<tip>`), never the
working tree. The user picks what to apply.

## Scope
The argument names what to audit: a base..tip range, a branch, a PR stack, or a path. Default:
`git diff $(git merge-base origin/<default-branch> HEAD)..HEAD`. List the commits
(`git log --oneline <base>..<tip>`) so each finding can name the commit/PR it lands in.
Ignore generated files (migration snapshots, lockfiles, baselines, codegen).
Audit ONLY code the scope adds or changes. Note drift with older code, but changes that reach
code outside the scope belong in their own refactor PR.

## Ground truth (find these before judging anything)
1. The domain glossary (CONTEXT.md, docs/GLOSSARY.md, or similar), including any "avoid" /
   banned-word lists.
2. The product's own UI copy (design handoff, specs, i18n strings, existing screens).
3. Conventions in neighbouring code that PREDATES the scope: how services, repositories,
   procedures/handlers, hooks and components are named, what each layer is allowed to do, how
   comments and docstrings are written.
4. Repo rules: CLAUDE.md/AGENTS.md, ADRs in docs/adr/, lint config (max-lines, import
   boundaries, exhaustive-table rules, etc.).
The fix always follows the repo, not a new style.

## Calibrate
Sort every finding into:
(a) clear win, worth changing now;
(b) judgement call, with the trade-off in one line;
(c) looks odd but follows an established convention or a documented decision: leave alone and
    say which.
For each (a)/(b), say whether the change stays inside the scope's own code or reaches code that
predates it.

## Finding format
One line per finding, then the proposal:
`[a|b|c] <check> · <file>:<line> (<commit/PR>) · <problem in one line>`
`  → <proposal: old → new, or what moves where> · reach: in-scope | pre-scope`
Rank by how much the change helps a reader understand what the code is for.
