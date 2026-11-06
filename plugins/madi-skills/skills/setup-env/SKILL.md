---
name: setup-env
description: Copy the gitignored local env files (.env, .env.local, agent .env files, .claude/settings.local.json) from the main checkout into the current git worktree so it can run locally (e.g. ./local/scripts/up.sh). Use when the user says "/setup-env", "copy the .env files in here", "set up env for this worktree", or has just checked out a worktree and wants to run the stack locally.
---

# Setup env for a worktree

Fresh worktrees have no gitignored files, so `./local/scripts/up.sh` fails (e.g. it needs
`apps/agents/patient-agent/.env` for `ACTOR_SLUG`). This skill copies them over from the
main checkout.

## Steps

1. Confirm you're inside the target worktree (`git rev-parse --show-toplevel`). If the user
   named a different source (e.g. "from ~/repos/vptech-elitemx"), pass it as the argument;
   otherwise the script defaults to the repo's **main worktree**.
2. Run:

   ```bash
   bash ~/.claude/skills/setup-env/copy-env.sh [--force] [SOURCE_DIR]
   ```

   It copies every gitignored `.env`, `.env.*` and `.claude/settings.local.json`
   (skipping `node_modules`, `.venv`, `.sandbox-home`), preserves symlinks, and **never
   overwrites** an existing differing file unless `--force` is given.
3. Report the summary line. If any file was `SKIPPED`, list them and ask before rerunning
   with `--force` — the worktree copy may hold deliberate overrides.
4. Tell the user they can now run `./local/scripts/up.sh`. Don't run it yourself unless
   asked (it starts docker and is heavy on RAM).

## Rules

- **Never print, cat, diff or echo the contents** of these files — they hold secrets. Paths only.
- **Never `git add` them.** They are gitignored; if `git status` ever shows one as staged or
  untracked-not-ignored, stop and tell the user rather than committing it.
- No commit is produced by this skill — there's nothing tracked to commit.
