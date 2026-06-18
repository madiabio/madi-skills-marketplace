# Report format

The report is one self-contained HTML file. Tailwind and Mermaid both load from CDNs. Mermaid handles graph-shaped diagrams (call graphs, dependencies, sequences); hand-built divs and inline SVG handle editorial visuals (mass diagrams, cross-sections, layered bands). Mix the two — leaning on Mermaid for everything makes it look generic.

## Scaffold

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{{title}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "loose" });
    </script>
    <style>
      .seam { stroke-dasharray: 4 4; }
      .leak { stroke: #dc2626; }
      .deep { background: linear-gradient(135deg, #0f172a, #1e293b); }
      body { font-feature-settings: "kern", "liga"; }
    </style>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="cards" class="space-y-12">...</section>
      <section id="closing">...</section>
    </main>
  </body>
</html>
```

## Header

Subject title (serif works well), date, a one-line context row (repo/branch/scope as relevant), and a compact legend explaining the visual vocabulary you use (e.g. solid box = module, dashed = seam, red = divergence/leak, dark box = the consolidated/deep thing). No intro paragraph beyond one orienting sentence — go straight to the cards.

## Card (for reviews / options / findings)

Each item is one `<article class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">`:

- **Badge row** — a strength/severity badge (`Strong`/`Worth exploring`/`Speculative`, or `High`/`Medium`/`Low`) as a coloured pill: emerald = strong/positive, amber = medium/caution, slate = speculative/low, rose = risk/safety. Add a category tag pill if useful.
- **Title** — short, names the thing.
- **Before / After (or A / B) diagram** — the centrepiece. Two columns side by side (`grid md:grid-cols-2 gap-6`). One is the problem state, the other the proposed/contrasting state. ~320px tall each.
- **Files / context** — monospaced list, `font-mono text-xs text-slate-600`.
- **Problem** — one sentence.
- **Solution / takeaway** — one sentence.
- **Wins / notes** — bullets, ≤6 words each.
- **Callout** (optional) — one-line amber (`bg-amber-50 border-amber-200`) or rose (`bg-rose-50 border-rose-200`) box for a caveat, dependency, or risk.

## Comparison columns (for A-vs-B)

When the report is "option A vs option B vs option C", use equal columns (`grid md:grid-cols-2` or `grid-cols-3`) of cards with a shared row of dimensions down the side, each cell a short verdict. Reserve one accent colour for the recommended column.

## Diagram patterns — pick per card, mix them

**Mermaid graph** (dependencies / call flow / "X→Y→Z, look at the mess"):

```html
<div class="rounded-lg border border-slate-200 bg-white p-4">
  <pre class="mermaid">
    flowchart LR
      A[Handler] --> B[Validator] --> C[Repo]
      C -.leak.-> D[PricingClient]
      classDef leak stroke:#dc2626,stroke-width:2px;
      class C,D leak
  </pre>
</div>
```
Sequence diagrams work for "before: 6 round-trips; after: 1". Escape special chars in node labels (use `#64;` for `@`, `<br/>` for line breaks; avoid raw parens/colons inside `[...]`).

**Hand-built boxes-and-arrows** — modules as bordered `<div>`s, arrows as absolutely-positioned inline SVG `<line>`/`<path>` over a `relative` container. Use when you want the "after" to feel like one thick-bordered deep/consolidated box with greyed-out internals — Mermaid won't render that with the right weight. Use the `.deep` gradient class for the consolidated box.

**Cross-section** (layered shallowness) — stack horizontal bands (`h-12 border-l-4`). Before: many thin layers each doing little. After: one thick band with the consolidated responsibility.

**Mass diagram** (interface-as-wide-as-implementation) — two rectangles per item: interface surface vs implementation. Before: interface nearly as tall as implementation. After: interface short, implementation tall.

**Call-graph collapse** — before: nested boxes of calls. After: one box with the now-internal calls faded inside.

## Closing section

One larger card (a dark accent like `bg-indigo-950 text-indigo-50` reads well): the top recommendation or overall summary — what to do first and one sentence why, with an anchor link to its card. That's it.

## Style

- Editorial, not corporate-dashboard. Generous whitespace. `font-serif` headings over stone/slate.
- Colour sparingly: one accent (emerald or indigo) + red for divergence/leak + amber for caution + rose for risk.
- Diagrams ~320px tall so before/after sits side by side without scrolling.
- Module/element labels inside diagrams: `text-xs uppercase tracking-wider` — schematic, not UI.
- Only scripts are the Tailwind CDN and the Mermaid ESM import. Otherwise fully static.
- No hedging, no "it's worth noting that…". If a sentence could be a bullet, make it a bullet. If a bullet could be cut, cut it.
