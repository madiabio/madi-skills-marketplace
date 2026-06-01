---
name: discord-ping
description: Send a Discord notification to the work or general channel. Use during long autonomous runs to ping the user at meaningful moments — run started, milestone reached, blocked and need input, run finished, or unexpected failure. Pick the channel with a leading token — "/discord-ping work <msg>" for work-related pings (PRs, deploys, work-repo milestones), "/discord-ping general <msg>" (or no token) for personal/agent-run lifecycle. Also use when the user says "ping me on discord", "notify me when done", or "/discord-ping". Do not use for routine step-by-step narration.
argument-hint: "[work|general] <message>"
---

# Discord ping

Send a short Discord message to the user via a webhook. Useful when you're working autonomously and the user is AFK. There are two channels — **work** and **general** — selected by an explicit leading token.

## Choosing the channel

The first whitespace-separated token of the invocation arguments selects the channel:

- First token is `work` → use the **work** channel (`WORK_DISCORD_WEBHOOK`); the rest is the message.
- First token is `general` → use the **general** channel (`AGENT_DISCORD_WEBHOOK`); the rest is the message.
- First token is **anything else, or there are no arguments** → default to **general**, and the *entire* argument string is the message.

This makes `/discord-ping hi there` (no token → general, message "hi there") and `/discord-ping work PR #14 merged` both work. **Never infer the channel from session context** (`STAGE`, `AWS_PROFILE`, etc. are set globally, so every session looks like "work" — they are not a reliable signal). Channel is explicit-token-only.

| Channel | Use for |
|---------|---------|
| **work** | Work-repo milestones, PRs merged/opened, CI/CD results, deploys, work-context blockers |
| **general** | Personal/agent-run lifecycle: run started, run done, blocked on a personal task, unexpected failure |

When unsure, default to **general**.

## Preconditions

- The webhook for the **resolved** channel must be set:
  - general → `AGENT_DISCORD_WEBHOOK`
  - work → `WORK_DISCORD_WEBHOOK`
- Check the one you need (truncate — it's a secret): `printenv WORK_DISCORD_WEBHOOK | head -c 20` (or `AGENT_DISCORD_WEBHOOK`).
- If the resolved channel's var is unset, **stop** and tell the user that var is missing. Do **not** fall back to the other channel — a wrong-channel ping is worse than no ping. Do not invent or hard-code a URL.

## How to send

Resolve the channel to a single `WEBHOOK_URL` shell variable, then `curl` that variable. Always post to `"$WEBHOOK_URL"`, never to a raw env-var name — that's what keeps the example channel-agnostic.

```bash
# CHANNEL is "work" or "general" (default general). Resolve to one URL.
if [ "$CHANNEL" = "work" ]; then
  WEBHOOK_URL="$WORK_DISCORD_WEBHOOK"
else
  WEBHOOK_URL="$AGENT_DISCORD_WEBHOOK"
fi

[ -z "$WEBHOOK_URL" ] && { echo "channel '$CHANNEL' webhook is unset; not sending"; exit 1; }

curl -sS -X POST -H "Content-Type: application/json" \
  -d '{"content": "your message here"}' \
  "$WEBHOOK_URL"
```

- Single-quote the JSON payload so the shell doesn't expand `$` in the message body.
- If the message contains single quotes or newlines, write the payload to a temp file with `Write` and `curl -d @<file>` instead, to avoid escaping hell.
- Never echo, log, or include either webhook URL in user-facing output — they're secrets.

## When to ping (autonomous runs)

Ping on **state changes the user cares about**, not on every step:

- **Run started** — one line: what you're doing and roughly how long it'll take.
- **Milestone hit** — e.g. "PR #17 merged, moving to WP-B R2".
- **Blocked** — you need a decision, credential, or clarification before continuing.
- **Done** — summary of what shipped + any follow-ups.
- **Failed unexpectedly** — what broke, where you stopped, what you tried.

Do **not** ping for: routine tool calls, file edits, test runs, internal reasoning, or progress on a single task.

## Message style

- Prefix with a short tag so the user can skim: `[start]`, `[done]`, `[blocked]`, `[fail]`, `[milestone]`.
- Include the repo or branch name if relevant.
- One or two sentences. If you need more, link to a PR / commit / file rather than pasting.

Examples:

```
/discord-ping general [start] refactor/split-overweight-files — beginning WP-B R6, ~30 min
/discord-ping work [milestone] PR #14 merged, moving to WP-C
/discord-ping general [blocked] sledge_only.py needs a path to corpus dir — what should I use?
/discord-ping work [done] Shipped WP-A (PRs #13, #14, #15). All green.
/discord-ping general [fail] Benchmark hung after 12 min on goal_007 — killed it. Logs at /tmp/bench-log-7.txt.
```

## Throttling

Don't ping more than every ~10–15 min during normal autonomous work, unless something genuinely changed. Batch routine progress into one message at the next milestone.
