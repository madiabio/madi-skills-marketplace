#!/usr/bin/env bash
# Re-sync the bundled plugin from the canonical dotfiles source.
#
# The plugin under plugins/madi-skills/ is a COPY of the authored skills/agents
# in ~/dotfiles/claude/.claude (plugins get cached on install and can't symlink
# out to ../.., so a copy is required). Run this after editing any source skill
# or agent so the distributable plugin doesn't drift.
#
# It deliberately does NOT touch the plugin's own tell-me-what-you-can-do skill
# (that one lives only in the plugin) or the manifests.

set -euo pipefail

SRC="$HOME/dotfiles/claude/.claude"
PLUG="$(cd "$(dirname "$0")" && pwd)/plugins/madi-skills"

# Skills: copy every authored skill except the plugin-only tour skill.
for d in "$SRC"/skills/*/; do
  name=$(basename "$d")
  rm -rf "$PLUG/skills/$name"
  cp -RL "$d" "$PLUG/skills/$name"
done

# Agents: copy all authored agents.
rm -f "$PLUG"/agents/*.md
cp -L "$SRC"/agents/*.md "$PLUG/agents/"

echo "Synced $(ls "$PLUG/skills" | wc -l | tr -d ' ') skills and $(ls "$PLUG/agents" | wc -l | tr -d ' ') agents."
echo "Run 'claude plugin validate $PLUG' to verify, then commit + bump version in plugin.json."
