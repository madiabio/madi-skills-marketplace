---
name: visual-report
description: Generate a self-contained, browser-opened HTML report (Tailwind + Mermaid via CDN) with before/after diagrams, cards, badges, and a top-recommendation section. Trigger when the user asks to "make a visual report", "HTML report", "diagram report", "before/after diagram", "visualise this comparison/analysis/findings", or wants an architecture review / investigation findings / design comparison rendered as a shareable visual page.
---

# Visual report

Render an analysis as a single self-contained HTML file — Tailwind (CDN) for layout, Mermaid (CDN) for graph-shaped diagrams, hand-built divs/SVG for editorial visuals — then write it to the OS temp dir, open it, and print the absolute path. The diagrams carry the weight; prose is sparse.

Read [REPORT-FORMAT.md](REPORT-FORMAT.md) for the full HTML scaffold, diagram patterns, and styling rules before writing. Don't reproduce the scaffold from memory — open the file.

## Process

1. **Know the content first.** You must already have the findings/candidates/comparison to render — this skill is the rendering step, not the analysis. If the analysis isn't done, do it (or say so) before invoking the format.
2. **Pick the report shape** from REPORT-FORMAT.md: candidate cards (for reviews/options), finding cards (for investigations), or comparison columns (for A-vs-B). Mix freely.
3. **Compute the output path.** `${TMPDIR:-/tmp}/visual-report-<slug>-<timestamp>.html` — `<slug>` is a short kebab descriptor of the subject; `<timestamp>` is `date +%Y%m%d-%H%M%S` so each run is fresh. Never write into the repo.
4. **Write the HTML** following REPORT-FORMAT.md: the CDN scaffold, a header with a legend, the cards/columns, and a closing top-recommendation (or summary) section. Each comparison gets a before/after or A/B visual. Keep diagrams ~320px tall so pairs sit side by side.
5. **Open it and report the path.** `open <path>` on macOS, `xdg-open <path>` on Linux, `start <path>` on Windows. Tell the user the absolute path in your reply.

## Rules

- **Self-contained.** Only external resources are the Tailwind CDN script and the Mermaid ESM import. No app code, no local assets, no interactivity beyond Mermaid's own rendering.
- **Visual over verbose.** If a section needs a paragraph to be understood, redraw the diagram. Bullets ≤6 words. No throat-clearing.
- **Don't vary the look per section by accident** — but do vary *diagram patterns* (Mermaid graph, hand-built boxes, cross-section, mass diagram) so the report doesn't read as generic.
- **Temp dir only.** This artifact is throwaway; it must not land in the user's repo or git status.
