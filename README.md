# madi-skills-marketplace

Madi's Claude Code engineering skills, agents, and workflows, packaged as a plugin so you can install them in one step. After installing, run **`/madi:tell-me-what-you-can-do`** for a guided tour.

## What's inside

- **Madi's custom skills** — spec-driven development, in-flight code-design enforcement, plan grilling, decision research, session cleanup/handoff, and more.
- **Matt-Pocock engineering skills** — `diagnose`, `tdd`, `zoom-out`, `improve-codebase-architecture`, `triage`, `to-issues`, `to-prd`. These assume a repo set up with the Matt-Pocock conventions (`CONTEXT.md`, `docs/adr/`); run `/madi:setup-matt-pocock-skills` to scaffold one.
- **Agents** — `topic-researcher`, `refactor-agent`, `frontend-ui-architect`, `workflow-optimizer`, `autonomous-griller`.

Not bundled: **GSD** (a separate heavyweight planning framework) and **Superpowers** (a separate marketplace). The tour skill points you at GSD's install with security/fork caveats if you want it.

## Install

Replace `<github-user>/madi-skills-marketplace` with wherever this repo is hosted.

```shell
/plugin marketplace add <github-user>/madi-skills-marketplace
/plugin install madi@madi-skills-marketplace
```

Then in any session:

```shell
/madi:tell-me-what-you-can-do
```

Run it **cold** (start of a session) for a full grouped overview of everything, or **mid-task** to get the 2–4 skills most relevant to what you're doing right now.

### Try it before installing

```shell
claude --plugin-dir /path/to/madi-skills-marketplace/plugins/madi-skills
```

Plugin skills are namespaced (`/madi:<skill>`) so they never collide with your own.

## Updating

```shell
/plugin marketplace update madi-skills-marketplace
```

## Notes

- This plugin intentionally **does not** ship hooks or `settings.json` — those in Madi's dotfiles carry machine-specific paths and GSD coupling, and aren't portable. Skills and agents are.
- `version` is set in `plugin.json`; bump it on each release so installers get updates.
