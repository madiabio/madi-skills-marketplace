---
name: swe-best-practices
description: >-
  Apply software-design principles (DRY, SRP, single source of truth, separation of concerns, single-concern files, low coupling/high cohesion, clear naming) as proactive in-flight flags WHILE writing or editing code — flag the violation and propose the small fix before writing the bad version, not after. Composable — invoke alongside any implementation or process skill (e.g. spec-driven-development, tdd) to hold its output to these standards. Use when the user says "swe best practices", "follow best practices", "apply good design", "/swe-best-practices", or whenever writing/editing non-trivial code on any task. NOT a post-hoc audit — for reviewing an existing codebase use improve-codebase-architecture instead.
---

# SWE Best Practices

Apply design judgment *while* writing code. The job is to **flag a violation and propose the small fix before writing the bad version** — a function extraction, a moved import, a named constant — not to do a big refactor later. This skill is flexible, not rigid: every principle below has a "when NOT to apply it" clause. Mechanically applying DRY + tiny-functions makes code *worse*; the goal is **lower total complexity** (how hard the code is to understand and change), and that is the tiebreaker when two principles conflict.

This skill **composes**. When invoked with an implementation or process skill, that skill drives the *workflow*; this skill governs the *shape of the code it produces*. Hold every file the other skill writes to the checklist below.

## Shared vocabulary

Reuse the terms from `improve-codebase-architecture` (don't invent parallel ones — that itself violates single-source-of-truth):

- **Module** — anything with an interface and an implementation (function, class, file, package).
- **Deep module** — lots of behaviour behind a small interface. The ideal. **Shallow** = interface nearly as complex as the implementation.
- **Seam** — where an interface lives; a place behaviour can change without editing in place.
- **Complexity** — anything that makes the system hard to understand or change. The thing every rule below exists to reduce.

## The in-flight checklist

Ask these BEFORE writing, not as a post-hoc review. Most fire silently and pass. When one trips, make the small fix in the same edit. If a fix would expand scope the user explicitly narrowed, note the debt instead of silently widening scope.

**Before a value / constant / type**
1. Does this fact already live somewhere? Reference it — don't restate it. A magic literal appearing a 2nd/3rd time → name it once. *(DRY / SSOT)*
2. Could this state be **derived** instead of stored-and-synced? Derive it rather than keeping two copies in lockstep. *(SSOT)*

**Before extracting / abstracting**
3. Is this duplication of the same *knowledge*, or just code that *looks* similar? Only dedupe shared knowledge. If you'd need a flag/conditional to make one function serve both callers, that's the wrong abstraction — keep them separate. *(DRY done right / AHA)*
4. Do you have 2–3 real uses AND is the abstraction's shape obvious? If not, tolerate the duplication for now. The wrong abstraction is costlier than duplication. *(WET / YAGNI)*

**Before a function / class / file**
5. Can you describe this unit in one sentence with no "and"? If the honest name needs "and" (`parseAndSave`), it has >1 reason to change → split along the reason-to-change axis. *(SRP)*
6. Are you mixing pure logic with I/O / persistence / presentation (a `fetch`/DB/`console.log`/file-write inside a computation)? Push side effects to the edges; keep the core pure. *(Separation of concerns)*
7. Is this file still one cohesive concept? If it mixes unrelated export groups (and is getting large, ~300–400+ lines), split by concept. Cohesion over line count — a 600-line cohesive state machine is fine; a 120-line junk drawer is not. *(Single-concern files)*

**Before splitting (the anti-dogma gate)**
8. If you're about to shatter a cohesive function into tiny ones that share hidden state and are only ever called in sequence — will a reader now bounce across files to follow one behaviour? If yes, DON'T. Keep it together and comment the *why*. Over-decomposition creates shallow "lasagna" code. *(overrides naive "small functions")*

**Before a dependency / parameter**
9. Are you introducing shared mutable state, a positional/ordering dependency, or a reach into another module's internals? Prefer named params, explicit passing, narrow interfaces; keep strong couplings *inside* one module and expose only weak ones. *(low coupling / high cohesion)*
10. Are you building generality for a need that exists NOW? "Might need it later" → delete it — unless it's an irreversible/external-contract decision (public API shape, data migration, security). *(YAGNI)*

**Before naming**
11. Does the name reveal intent, tell the truth about side effects, and match the codebase's existing vocabulary (and CONTEXT.md if present)? `data`/`tmp`/`manager`/`doStuff`, or a name that lies (`getUser()` that mutates) → rename now. Don't rename against an established convention just to satisfy an abstract "better" name — consistency wins. *(clear naming)*

**Before finishing**
12. Net complexity check: did this change make the code easier or harder to understand and change *overall*? This is the final gate when principles conflict. *(Ousterhout tiebreaker)*
13. Did you leave a swallowed error, a silent default masking a failure, or a now-stale docstring/comment? Fix it in the same edit. *(fail-fast + docstring-staleness policy)*

## Signals → action reference

Consult when a checklist item trips and you want the concrete tell and fix.

| Principle | Observable signal in the diff | Action | When NOT to |
|---|---|---|---|
| **DRY / SSOT** | Same literal/rule/type in 2–3+ places that must change in lockstep | Hoist the *knowledge* to one authority; reference it | Copies only *look* alike but model different decisions (coincidental duplication) — leave them |
| **SRP** | Honest name needs "and"; one unit imports unrelated subsystems | Split along the reason-to-change / actor axis | Splitting would create shallow units sharing hidden state — keep cohesive |
| **SSOT (state)** | `fullName` beside `first`/`last`; a cached count beside the list; FE type mirroring BE schema by hand | Derive it; generate types from the schema | Deliberate perf cache — but mark it derived and keep derivation one-directional |
| **Separation of concerns** | I/O / SQL / HTTP / logging inline in a computation | Push side effects to the edge; pure core | Don't erect hexagonal layers for a 50-line script (YAGNI) |
| **Single-concern file** | Can't summarise the file without "and"; imports span unrelated subsystems | Extract the unrelated group into a file named for its concept | A large *cohesive* file is fine — don't split to hit a number |
| **Coupling / cohesion** | Shared mutable global; required call ordering; callers depending on internal field names; dependency cycle | Narrow interfaces; named params over positional; one owner for state | Zero coupling is impossible — don't add event buses/interfaces for a direct call |
| **Clear naming** | `data`/`temp`/`manager`/`doStuff`; name lies about side effects; `create(true, false)` | Intention-revealing, honest, searchable name; named options over positional booleans | Don't over-qualify (`user.userName`) or fight an established convention |
| **YAGNI** | Config flag / abstraction layer / generic param with exactly one current use | Build it when actually needed | Irreversible / external-contract decisions do warrant forethought |
| **Fail-fast** | Empty catch; silent `?.`/`\|\| default` masking failure; null-on-error with no signal | Validate at boundaries; throw/return typed errors | Degrade gracefully at the *perimeter*; fail fast *internally* |

## Where the authorities disagree (don't cargo-cult)

Use judgment, not a single book's law:

- **Function length** — Clean Code wants 2–4 lines; Ousterhout shows over-decomposition produces shallow, information-leaking modules. → Split by *reason to change / depth*, not line count.
- **Comments** — Clean Code says "comments are failures"; Ousterhout says they're essential for the *why* and non-obvious contracts. → Comment the *why*; don't narrate *what* the code already says.
- **Abstraction timing** — DRY-forward vs. AHA/WET (tolerate duplication until the shape is obvious). → Prefer the latter; the wrong abstraction is the costlier mistake.

Both camps agree: modularity and naming matter, and over-decomposition is real. They disagree on the cure, not the disease — so reason, don't recite.

## Composing with other skills

- **With `spec-driven-development` / `tdd`**: that skill owns the loop (spec → tests → implement); apply this checklist to every chunk of implementation code it produces, and flag design issues before writing the green code.
- **With `improve-codebase-architecture`**: that's the *retrospective* review skill (produces a report, asks the user). This one is *in-flight*. If a checklist flag reveals deep structural rot across an existing codebase rather than a local fix, hand off to `improve-codebase-architecture`.
- Stay lightweight: this skill is a set of flags, not a workflow. It should add a sentence or two of design reasoning to the work the other skill is already doing — not take it over.
