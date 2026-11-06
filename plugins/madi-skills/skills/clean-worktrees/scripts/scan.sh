#!/usr/bin/env bash
# scan.sh — READ-ONLY inventory of git worktrees, with a removal verdict per worktree.
#
# Usage: scan.sh [ROOT]   (ROOT defaults to ~/repos; may also be a single repo/worktree path)
#
# Groups worktrees by their parent repo (git common dir) and reports each LINKED worktree (main
# checkouts are skipped — never candidates). Empty fields print as "-". Per worktree:
# branch, PR state, dirty count, unpushed status, Graphite children, processes using it,
# docker compose projects rooted inside it, last activity, and a verdict:
#   remove — PR merged/closed, clean, nothing unpushed, nothing running
#   ask    — no PR, clean, nothing unpushed, idle > STALE_DAYS (default 14)
#   keep   — anything else (reason column says why)
#
# Output: TSV on stdout, one header row. Never modifies anything.

set -uo pipefail
ROOT="${1:-$HOME/repos}"
STALE_DAYS="${STALE_DAYS:-14}"
SELF="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
NOW=$(date +%s)

# Processes' cwds, collected once (fast; avoids lsof +D walking node_modules).
CWDS=$(lsof -a -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | sort -u)
# Compose projects and their working dirs, collected once (empty if docker is down).
COMPOSE=$(docker ps -a --format '{{.Label "com.docker.compose.project"}}	{{.Label "com.docker.compose.project.working_dir"}}' 2>/dev/null | awk -F'\t' '$1!=""' | sort -u)

# Unique common git dirs under ROOT.
commons=$( { [ -e "$ROOT/.git" ] && echo "$ROOT"; for d in "$ROOT"/*/; do [ -e "$d/.git" ] && echo "${d%/}"; done; } \
  | while read -r d; do git -C "$d" rev-parse --path-format=absolute --git-common-dir 2>/dev/null; done | sort -u)

printf 'repo\tworktree\tbranch\tpr\tpr_state\tdirty\tunpushed\tchildren\tbusy\tdocker\tidle_days\tverdict\treason\n'

for common in $commons; do
  main=$(dirname "$common")
  repo=$(basename "$main")
  trunk=$(git -C "$main" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
  gtdb="$common/.graphite_metadata.db"

  git -C "$main" worktree list --porcelain | awk '
    /^worktree /{wt=substr($0,10)} /^branch /{br=substr($0,8); sub("refs/heads/","",br)}
    /^prunable/{pr=1} /^$/{print wt "\t" br "\t" pr; wt="";br="";pr=""} END{if(wt!="")print wt "\t" br "\t" pr}' |
  while IFS=$'\t' read -r wt br prunable; do
    [ "$wt" = "$main" ] && continue   # main checkout is never a removal candidate
    if [ -n "$prunable" ] || [ ! -d "$wt" ]; then
      printf '%s\t%s\t%s\t-\t-\t-\t-\t-\t-\t-\t-\tremove\tprunable (dir missing; git worktree prune)\n' "$repo" "$wt" "$br"; continue
    fi

    dirty=$(git -C "$wt" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    head=$(git -C "$wt" rev-parse HEAD 2>/dev/null)
    last=$(git -C "$wt" log -g -1 --format=%ct HEAD 2>/dev/null || git -C "$wt" log -1 --format=%ct 2>/dev/null)
    idle=$(( (NOW - ${last:-$NOW}) / 86400 ))

    # PR by branch name; detached worktrees (PR review checkouts) fall back to a commit-SHA search.
    pr=""; pr_state=""; pr_oid=""
    q=(--head "$br"); [ -z "$br" ] && q=(--search "$head")
    read -r pr pr_state pr_oid < <(cd "$wt" && gh pr list "${q[@]}" --state all --limit 1 \
      --json number,state,headRefOid --jq '.[0] // empty | "\(.number) \(.state) \(.headRefOid)"' 2>/dev/null)

    # Unpushed: HEAD matches the PR head, or is contained in the upstream / any remote branch / trunk.
    if [ -n "$pr_oid" ] && [ "$pr_oid" = "$head" ]; then unpushed=no
    elif git -C "$wt" merge-base --is-ancestor HEAD "$trunk" 2>/dev/null; then unpushed=no
    elif [ -n "$(git -C "$wt" branch -r --contains HEAD 2>/dev/null | head -1)" ]; then unpushed=no
    else unpushed=yes; fi

    children=""
    if [ -n "$br" ] && [ -f "$gtdb" ]; then
      children=$(sqlite3 -readonly "$gtdb" "select group_concat(branch_name, ',') from branch_metadata where parent_branch_name='${br//\'/\'\'}';" 2>/dev/null)
    fi

    busy=$(printf '%s\n' "$CWDS" | awk -v p="$wt" '$0==p || index($0, p"/")==1' | head -1)
    # Compose projects rooted inside this worktree. Suffix "!shared" when the same project name
    # also has containers rooted elsewhere: `down -v` on it would hit the other checkout's stack.
    docker=$(printf '%s\n' "$COMPOSE" | awk -F'\t' -v p="$wt" '
      { inside = ($2==p || index($2, p"/")==1); if (inside) mine[$1]=1; else other[$1]=1 }
      END { for (k in mine) print k (k in other ? "!shared" : "") }' | sort | paste -sd, -)

    verdict=keep; reason=""
    if   [ "$wt" = "$SELF" ];        then reason="current worktree"
    elif [ -n "$busy" ];             then reason="process running in it"
    elif [ "$dirty" -gt 0 ];         then reason="uncommitted changes"
    elif [ "$unpushed" = yes ];      then reason="commits not on remote"
    elif [ "$pr_state" = MERGED ] || [ "$pr_state" = CLOSED ]; then
      verdict=remove; reason="PR $pr_state"; [ -n "$children" ] && reason="$reason; keep branch (has children)"
    elif [ -z "$pr" ] && [ "$idle" -gt "$STALE_DAYS" ]; then verdict=ask; reason="no PR, idle ${idle}d"
    elif [ -z "$pr" ];               then reason="no PR, recently active"
    else reason="PR $pr_state"; fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$repo" "$wt" "${br:-(detached)}" "${pr:--}" "${pr_state:--}" "$dirty" "$unpushed" "${children:--}" \
      "$([ -n "$busy" ] && echo yes || echo no)" "${docker:--}" "$idle" "$verdict" "$reason"
  done
done
