---
name: research-decision
description: Parallel decision-research for software, architecture, and implementation choices — the equivalent of ~30 minutes of a human reading docs, tech blogs, and AWS docs to pick the best approach. Frames the decision with /zoom-out, decomposes it into focused research questions, fans out topic-researcher agents in parallel (one per question), then writes a bias-aware report that leads with key findings and even-handed approaches (with pros/cons and a trade-off table) and ends with the recommendation, with citations attributed inline throughout. Lighter than /deep-research. Use when the user says "research the best way to X", "what should we use for Y", "compare options for Z", "research this architecture/implementation choice", or "/research-decision". Operates autonomously by default; only pauses for question review if asked.
---

# Research a decision

Drive a focused, parallel research pass on a software/architecture/implementation decision and return a recommendation. Target depth: what a competent engineer would produce in ~30 minutes of reading docs, vendor pages (AWS etc.), and reputable tech blogs — not an exhaustive survey.

## Process

1. **Frame the decision with `/zoom-out`.** Before researching anything, invoke the `zoom-out` skill on the topic to surface the *real* decision: what's actually being chosen, the constraints and forces in play (existing stack, scale, team, cost, ops burden), and what "good" looks like here. Pull constraints from the repo when relevant (read `CLAUDE.md`, `CONTEXT.md`, `docs/adr/`, package manifests) so the research is grounded in *this* project, not generic advice. If `zoom-out` isn't available, do the framing inline — same goal.

2. **Derive the research questions.** From the framing, write a focused list of independent questions — each one a thing a researcher can go answer on its own. **Size the list to the decision**: a narrow library pick might be 2–3 questions; a multi-dimensional architecture choice might be 5–7. Don't pad. Each question should name what to investigate AND what a good answer contains (e.g. "Compare X vs Y for Z — maturity, AU-region support, operational cost, failure modes").

3. **Review gate (autonomous by default).** Dispatch immediately without showing the questions — UNLESS the user asked to review them (e.g. "let me review the questions first", "show me the plan", or a `--review` flag). If review was requested, list the questions, ask for edits via AskUserQuestion or a plain prompt, and wait for go-ahead before dispatching.

4. **Fan out `topic-researcher` agents in parallel.** Spawn one `topic-researcher` agent per question **in a single message** so they run concurrently. Give each a self-contained prompt: the specific question, the project constraints from step 1 that matter to it, and an instruction to return a citation-backed briefing with concrete trade-offs and a clear answer to its question. Tell each researcher explicitly to: (a) **attribute every claim to its source inline** (URL + what the source is) so the synthesis can carry those attributions through, and (b) **surface disagreement between sources** rather than picking one silently — note where a vendor doc and an independent benchmark/blog conflict and under what conditions each holds. (Do NOT tell the researchers to use `/zoom-out` — that's a main-conversation framing move you already did; researchers get a tight question.)

5. **Synthesize the report — recommendation goes LAST, on purpose.** Once the briefings return, produce a decision-oriented writeup in this exact order. The ordering is deliberate: lead with evidence and options so the reader forms their *own* view before seeing yours — leading with the recommendation anchors them and defeats the point. Sections, top to bottom:

   1. **Key findings** — the factual ground, first. A tight paragraph per research question, each claim attributed inline (see citation style below). This is what the research actually turned up, stated neutrally, before any options framing.

   2. **Approaches** — *only include this section if more than one approach is genuinely valid.* First decide honestly whether the decision is open or settled:
      - **If multiple valid approaches exist:** present each one with a short summary (what it is, when you'd reach for it) and explicit **pros / cons**. Present them even-handedly — do NOT tip your hand toward the eventual pick here. The reader should be able to disagree with your later recommendation using this section.
      - **If there's genuinely only one sound approach** (the others are clearly inferior, deprecated, or don't fit the constraints): say so plainly in a sentence or two and skip the multi-approach presentation. Do NOT manufacture strawman alternatives to look balanced — fake options are their own bias. Note *why* the alternatives are non-starters, with citations.

   3. **Trade-off table** — options as rows; the dimensions that actually matter (cost, ops burden, maturity, fit-to-stack, lock-in, etc.) as columns. Omit if there's only one viable approach (nothing to trade off).

   4. **Risks / unknowns** — what's still uncertain or would need a spike to resolve.

   5. **Recommendation** — LAST. The approach you'd pick, stated plainly, rationale tied back to the constraints from step 1. By now the reader has seen the findings, the options, and the trade-offs, and can judge whether your pick follows from them.

   6. **Sources** — the full list of sources the researchers used, as a reference (this is in addition to the inline attributions, not a replacement for them).

   **Citation style — attribute inline, throughout.** Don't relegate sourcing to a footer list. Every non-obvious claim names its source where it's made, and conflicting guidance is surfaced explicitly rather than smoothed over. Write like: "AWS recommends X for this ([Aurora failover docs](url))" and "while AWS suggests X, [this Vespa benchmark](url) argues Y is faster above ~10M vectors, so the right answer depends on scale." When two reputable sources disagree, show both and explain the condition under which each wins — that disagreement is signal, not noise to resolve away.

6. **Save and report.** Write the synthesis to `.claude/research/<short-slug>.md` in the current repo (or the current directory if not in a repo). Tell the user the path. Keep the same bias-aware ordering in the inline chat reply too — don't open the chat message with the recommendation; if you're keeping the inline version short, point them at the saved report for the full findings/approaches/trade-offs rather than collapsing it to just the verdict.

## Rules

- **Scale to the decision.** Number of questions and researchers is dynamic — derive it from the framing, don't fix it. Log how many you dispatched and why.
- **Ground in the project.** A recommendation that ignores the existing stack/constraints is generic slop. The whole point of step 1 is to avoid that.
- **Parallel, single message.** All `topic-researcher` spawns go in one message — sequential dispatch wastes the concurrency.
- **Lighter than deep-research.** No adversarial multi-round verification loop. One focused pass per question, synthesized. If the user wants exhaustive fact-checking, point them at `/deep-research` instead.
- **Lead with evidence, recommend at the end.** The report is ordered to avoid anchoring the reader: key findings → approaches → trade-offs → risks → recommendation (last). Present competing approaches even-handedly; the reader should be able to reach a *different* conclusion than yours from the sections above the recommendation.
- **Don't fake alternatives.** If only one approach is genuinely sound, say so and skip the approaches/trade-off sections — a strawman second option to look balanced is its own bias. If several are viable, show each with honest pros/cons.
- **Cite inline, surface disagreement.** Attribute claims to their sources where they're made, not just in a footer. When sources conflict (vendor doc vs. independent benchmark/blog), show both and the conditions under which each holds — don't silently pick a winner.
- **Still recommend.** Leading with evidence does not mean ending without a call — the final section is a decision with rationale, not a neutral info dump.
