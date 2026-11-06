---
name: diagram-artifact
description: Explain the current issue, bug, design or concept as a diagram-first Artifact page, so the user can understand it at a glance. Use when the user says "/diagram-artifact", "make an artifact so I can see what's going on", "draw me the issue", "visualise this", "I need a picture of this", or "explain this with diagrams".
---

# Diagram artifact

Turn what we've found in this session into a published Artifact where diagrams carry the explanation and text only labels them. Success test: the user looks at the first screen for ten seconds and can say back what the issue is.

## Process

1. **Nail the one sentence first.** Write "The issue is: ___" in plain words. If you can't, the analysis isn't done: finish it (read the code, reproduce) before drawing. Never draw a guess as if it were fact.
2. **Load `artifact-diagramming` and `artifact-design`** for SVG mechanics, theming and the page contract. This skill adds the editorial rules on top; don't duplicate theirs.
3. **Pick the diagram form from the shape of the issue**, not from habit:
   - things happen in the wrong order / race / retry → sequence diagram or timeline
   - data goes somewhere wrong / gets lost → flow diagram with the break marked
   - wrong state or transition → state machine with the bad edge highlighted
   - broken vs fixed, option A vs B → side-by-side twins with identical layout (small multiples)
   - what owns / contains what → nested boxes
   - numbers (latency, counts, sizes) → a chart, via the `dataviz` skill
4. **Plan, then audit the plan before rendering.** List each diagram's boxes and arrows, and check each one maps to something real (a file, function, table, service, request). Anything unconfirmed is drawn dashed and labelled "hypothesis".
5. **Build the page in this order:**
   1. Title + the one sentence.
   2. **Hero diagram**: the single picture that shows the mechanism of the issue. If the user saw only this, they'd get it.
   3. Supporting diagrams, one idea each, each with a ≤2-sentence caption that says what to notice.
   4. "Where in the code": the real `file:line` references, short.
   5. Fix / next step, ideally as the "after" twin of the hero.
   6. Details (logs, edge cases, raw data) in collapsed `<details>`, never above the fold.
6. **Publish** with the Artifact tool, then reply with the link and the one sentence. Don't repeat the page's content in chat.

## Visual rules

- **Mark the problem on the picture.** One accent colour (red/orange) reserved for "this is where it breaks"; everything else neutral. Annotate at the point of failure, not in a legend far away.
- **Show the mechanism, not the topology.** A box-and-arrow map of every service explains nothing; show the path the failing request actually takes.
- **Use real names** from the code and domain (function, table, endpoint names, the repo's `CONTEXT.md` terms), not "Service A".
- **Erase test.** For every element ask "can I delete this without losing clarity?" If yes, delete it. Aim for ≤7 boxes per diagram; split rather than cram.
- **Twins share a layout.** Before/after or A/B diagrams use identical positions so only the difference moves.
- **Numbered steps** (①②③) on arrows when order matters, matching the caption.
- **Readable first:** labels ≥13px, high contrast in light and dark, no text inside thin arrows, no crossing lines you can avoid, works at phone width.
- **Interactivity only if it guides attention**, e.g. a stepper that walks a sequence one step at a time. No open sandboxes, no decorative animation.
- **Prose is a fallback.** If a section needs a paragraph to be understood, redraw the diagram instead.
