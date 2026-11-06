---
name: clean-worktrees
description: Find and remove git worktrees that are no longer in use — PR merged/closed (via gh + Graphite stack data), clean, nothing unpushed, nothing running — plus their local branch (gt delete) and the docker compose stack rooted in them. Scans every repo under ~/repos by default. Shows a verdict table, removes the definitely-stale batch on one confirmation, asks one at a time about idle no-PR worktrees, never touches dirty/unpushed ones. Use when the user says "clean up worktrees", "remove old worktrees", "prune worktrees", or "/clean-worktrees". Not for deleting session doc artefacts — that's /clean-up.
---

# Clean worktrees

## 1. Scan (read-only)

```bash
~/.claude/skills/clean-worktrees/scripts/scan.sh [ROOT]   # ROOT defaults to ~/repos
```

Takes ~20s (one `gh` call per worktree). It emits TSV, one row per **linked** worktree; main
checkouts are skipped since they're never candidates. Columns: `repo, worktree, branch, pr,
pr_state, dirty, unpushed, children, busy, docker, idle_days, verdict, reason`.

The verdict is decided in the script, so don't re-derive it. Its rules:

- **remove**: the PR is MERGED or CLOSED, there are no uncommitted changes, nothing is
  unpushed, and no process has its working directory inside the worktree.
- **ask**: there's no PR, the worktree is otherwise clean, and it's been idle for more than
  `STALE_DAYS` (default 14).
- **keep**: everything else. Also always the worktree you're running from.

"Unpushed" means HEAD is none of: the PR's head commit, contained in trunk, or contained in
any remote branch. That way squash-merged branches whose remote branch was deleted don't
read as unpushed. Detached-HEAD worktrees (PR review checkouts) are matched to their PR by
commit SHA.

## 2. Show the table

Show a compact table grouped by verdict: **remove** first, then **ask**, then **keep** with
reasons. For remove rows, list what will happen to each one: the worktree, the branch (unless
`children` is non-empty, in which case the branch stays because other stack branches sit on
it), and docker projects (unless marked `!shared`).

## 3. Remove the batch on one confirmation

Ask once: "remove these N?" Then, for each **remove** row, in this order:

1. **Docker**, for each project in `docker` that is **not** marked `!shared`:
   `docker compose -p <project> down -v --remove-orphans`. Then check that
   `docker volume ls -q --filter label=com.docker.compose.project=<project>` is empty, and
   `docker volume rm` anything left over. **Never** run `down` on a `!shared` project, since
   the same project name is backing another checkout's stack. Report it instead. Never run
   `docker system prune` or any global prune.
2. **Worktree**: `git -C <main> worktree remove <worktree>`. **No `--force`.** If git refuses,
   something changed since the scan, so skip that row and report it.
3. **Branch**, only when `children` is `-` and the row has a branch:
   `gt --cwd <main> delete <branch> --no-interactive` (it doesn't prompt for merged or closed
   branches, and it clears the Graphite metadata). If Graphite doesn't track the branch, fall
   back to `git -C <main> branch -D <branch>`. Never pass `gt delete --force`, `--upstack` or
   `--close`.

Rows with `prunable` (directory already gone) just need step 4.

4. Per repo, at the end: `git -C <main> worktree prune`.

Removals in different repos are independent, so batch their tool calls. Within one repo,
run them one at a time, because git locks `.git/worktrees` during each removal.

## 4. The "ask" rows, one at a time

For each one, show the path, the last commit subject (`git -C <wt> log -1 --format=%s`),
the idle days, and whether the branch exists on the remote. Ask remove or keep. If it's
removed, follow §3.

## 5. Verify and report

Re-run the scan. Confirm the removed rows are gone and nothing in the keep set changed.
Report how many worktrees were removed, which branches were deleted, which docker projects
were taken down, and anything skipped with the reason (the `!shared` docker projects in
particular).

## Never

- `gt sync`: it restacks branches and can overwrite trunk, which is far more than cleanup.
- Touching remote branches or PRs.
- Removing the main checkout, the current worktree, or anything dirty, unpushed or busy, even
  if the user asks for the batch. Point them at the reason column instead.
