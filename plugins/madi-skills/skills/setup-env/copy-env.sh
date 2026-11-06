#!/usr/bin/env bash
# Copy gitignored local-config files (.env*, .claude/settings.local.json) from a
# source checkout into the current git worktree, so the worktree can run
# ./local/scripts/up.sh without hand-copying secrets.
#
# Usage: copy-env.sh [--force] [SOURCE_DIR]
#   SOURCE_DIR defaults to the repo's main worktree (first entry of `git worktree list`).
#   Existing files in the destination are left alone unless --force is passed.
#   Never prints file contents — only paths.
set -euo pipefail

force=0
if [[ "${1:-}" == "--force" ]]; then force=1; shift; fi

dest=$(git rev-parse --show-toplevel)
src=${1:-$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')}
src=$(cd "$src" && pwd -P)
dest=$(cd "$dest" && pwd -P)

if [[ "$src" == "$dest" ]]; then
  echo "Source and destination are the same checkout ($src) — run this from a worktree." >&2
  exit 1
fi

# Only gitignored files, skipping dependency/tool dirs that may contain look-alikes.
# .env.example is committed, so it never appears in the ignored list.
# (while-read rather than mapfile: macOS ships bash 3.2.)
copied=0; skipped=0
while IFS= read -r f; do
  if [[ -e "$dest/$f" || -L "$dest/$f" ]] && (( ! force )); then
    if cmp -s "$src/$f" "$dest/$f"; then
      echo "same     $f"
    else
      echo "SKIPPED  $f (exists and differs; rerun with --force to overwrite)"
    fi
    skipped=$((skipped + 1))
    continue
  fi
  mkdir -p "$dest/$(dirname "$f")"
  # -P keeps symlinks as symlinks (up.sh links apps/{api,web}/.env -> .env.example).
  cp -P -f "$src/$f" "$dest/$f"
  echo "copied   $f"
  copied=$((copied + 1))
done < <(
  git -C "$src" ls-files --others --ignored --exclude-standard \
    | grep -vE '(^|/)(node_modules|\.venv|\.sandbox-home|\.git)/' \
    | grep -E '(^|/)\.env(\.[^/]*)?$|(^|/)\.claude/settings\.local\.json$' \
    || true
)

echo "---"
echo "$copied copied, $skipped already present ($src -> $dest)"
