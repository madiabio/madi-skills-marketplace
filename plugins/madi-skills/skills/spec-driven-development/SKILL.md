---
name: spec-driven-development
description: Write a short, sharp spec of design GOALS (rarely any code) BEFORE implementing, then build against it section by section with TDD — write failing tests for each spec section, have a reviewer confirm the tests actually encode the spec's goals (via /step-back) before implementing to green, on a feature branch that follows the repo's git convention. First aligns with the repo's own spec/PR/doc standards (falling back to bundled house templates only where the repo is silent). In PR-based repos, opens a draft PR seeded from the spec, keeps its body in sync as code lands, and adds manual-verification steps at close-out. Invoke when the user says "spec-driven development", "SDD", "write a spec first", "spec this out before building", or before starting any non-trivial, multi-file, or ambiguous implementation.
---

# Spec-Driven Development (SDD)

Write the spec first, align on it, then implement against it. The spec is the contract; the code conforms to the spec, not the other way around. Calibrate to size — a one-line fix needs no spec; anything multi-step, multi-file, or ambiguous does.

## Process

### 0. Align with the repo's standards (exploratory — do this first)

Before writing the spec, **find out whether the repo already has its own conventions** for the artefacts this skill produces, and prefer them. This skill ships a *house standard* (the `references/` templates, the draft-PR lifecycle), but the house standard is a **fallback** — a repo's own documented way of working always wins. Do a quick exploratory pass (a `general-purpose` or `Explore` subagent is ideal here; it keeps the survey out of the main context):

- **Spec / planning format** — existing `.claude/specs/`, `docs/specs/`, `specs/`, a PRD/ADR layout (`docs/adr/`), `CONTEXT.md`, or a template file? If so, match it.
- **Git / PR workflow** — does the repo use PRs at all, or commit straight to the default branch (check `CLAUDE.md`/`AGENTS.md`, ADRs, and memories — e.g. the dotfiles "commit straight to main" rule)? Branch naming?
- **PR-body convention** — a `.github/PULL_REQUEST_TEMPLATE.md`, an `## Agent skills` / contributing block, or a recognisable house style in recent merged PRs (`gh pr list --state merged` + view a couple)? Authorship-credit convention (e.g. the `coderabbit-resolve` `Author: Claude …` style)?
- **Docstring / structure / testing conventions** — already covered by `swe-best-practices` at build time, but note anything spec-relevant.

Then decide, and **state the decision in one line before proceeding**:

- **Default: align.** If the repo has a relevant convention, follow it and use this skill's templates only to fill gaps the repo's convention is silent on (e.g. repo has a PR template but no manual-test checklist → keep that idea from `references/pr-body-template.md`).
- **Fallback: house standard.** If the repo has no relevant convention, use this skill's `references/` templates and the lifecycle as written.
- **Opt-out.** If the user explicitly says *don't align with the repo standards* (or "just use your standard"), skip the alignment and use the house standard regardless.

Everywhere below where this skill names a template or a PR step, read it as "**the repo's convention if step 0 found one, else the house standard**."

### 1. Write the spec (before any code)

Create a markdown spec. Location: `.claude/specs/<slug>.md` (or the repo's existing spec convention — `docs/specs/`, `specs/` — check first; see step 0). Keep it tight; a spec is not a novel.

**A spec defines design *goals*, not implementation. It should rarely contain code.** The whole point of spec-first is to think at the level of *what* must be true and *why* before getting pulled into *how* — dropping code into the spec collapses that altitude and quietly turns the spec into a draft implementation, which defeats the purpose. So write the spec in terms of behavior, constraints, and acceptance criteria. Only include a code snippet when a contract genuinely can't be expressed in prose without ambiguity — an exact public API signature, a wire/serialization format, a specific data shape another system depends on. If you're tempted to write code to explain *how* you'll build it, that belongs in the implementation, not the spec.

Use the house spec shape in **`references/spec-template.md`** as the fallback — *unless* step 0 found a repo spec convention to align with, in which case follow that.

### 2. Sharpen the spec

Before implementing, stress-test it:
- **User present?** Use `/grill-me` or `/grill-with-docs` to challenge the design.
- **Autonomous?** Use `/self-grill` (griller + domain expert) until the spec is sharp.
- Resolve every "I'm not sure" in the spec before writing code. Ambiguity in the spec becomes bugs in the code.

### 3. Set up the work branch

Before writing tests or code, decide where the work lands — **let the repo's existing framework be the blueprint**:
- If the repo documents a git/PR workflow (in `CLAUDE.md` / `AGENTS.md`, an ADR, or a memory like the dotfiles "commit straight to main" rule), follow it.
- If there's no such convention, default to best practice: create a **feature branch**, do the work there, open a **PR**, and after merge **delete the branch** (local + remote). Don't leave dead branches around.

### 4. Open a draft PR seeded from the spec (when the repo uses PRs)

**Only if the repo's convention from step 3 uses PRs.** Some repos commit straight to the default branch (e.g. a personal dotfiles repo with a "commit straight to main" memory) — for those, **skip this step entirely**; there's no PR to open or keep in sync. For a repo that does PR-based work (e.g. `vptech-elitemx`), open the PR **now, as a draft, before writing implementation code** — so the spec is visible for early feedback and the body becomes the living record of the work as it lands.

- Push the (so-far empty or scaffold-only) feature branch and open it with `gh pr create --draft`.
- **Seed the PR body from the spec**, using the repo's PR convention if step 0 found one, else the house shape in **`references/pr-body-template.md`**. The spec is the source, the body is its public face. The body should let a reviewer understand the change without opening the diff:
  - **Header** — title, milestone/board reference if the repo uses one, status (`🚧 Draft — implementing`), and how it relates to sibling PRs (depends-on / independent-of).
  - **One-paragraph summary** — what the change does, in plain language.
  - **📄 Spec** — link to the spec file (`.claude/specs/<slug>.md`) and its current status.
  - **What will land** — a checklist derived from the spec's acceptance criteria, **unchecked** at draft time. These get ticked as each section goes green in step 5.
  - **Key decisions** — lifted from the spec's "Key decisions"; refine as the build teaches you more.
  - **Scope / out of scope** — what this PR does and explicitly does NOT do (from the spec).
  - **Relationship to other PRs** — dependencies, what's deferred to a follow-up.
- **Credit authorship** per the repo's convention. If the repo follows the `coderabbit-resolve` style, that means an `Author: Claude <model>, <effort>` line and the standard `🤖 Generated with Claude Code` footer — match whatever sibling PRs in the repo already do.
- Keep it a **draft** until close-out (step 7). Draft signals "not ready to merge" while still surfacing the work.

### 5. Build the spec, one section at a time — TDD with a test-review loop

Implement the spec **section by section** (one acceptance-criterion / design-goal cluster at a time), not all at once. For *each* section, run this loop before touching implementation code:

**a. Write the failing tests for this section (test-writer).** Spawn a `test-writer` subagent (or use `superpowers:test-driven-development` inline if the section is tiny). It writes tests that target *this section's goals* and watches them fail for the right reason (red). No implementation yet.

**b. Review the tests against the spec's goals (reviewer).** Spawn a separate `reviewer` subagent. Its job is NOT "are these good tests" in the abstract — it's "**do these tests actually prove the GOAL this spec section describes**, or do they assert incidental behavior that could pass while the goal is unmet?" The reviewer uses `/step-back` to lift back to what the section is really trying to achieve, then checks the tests against that. (If subagents aren't warranted — present user driving a small change — the main agent can play reviewer inline, but keep the roles distinct: write, then critically re-read against the goal.)

**c. Iterate until aligned.** test-writer and reviewer go back and forth — reviewer flags gaps ("the spec says X must hold under concurrent writes; no test exercises that"), test-writer adds/fixes tests — until both are confident the failing tests genuinely encode the section's goals. Only then proceed.

**d. Implement to green.** Before writing any implementation, **invoke the `swe-best-practices` skill** (via the Skill tool) and load its in-flight checklist — do this even if the user only invoked `/spec-driven-development`; you don't wait to be asked. Then write the minimum implementation to pass this section's tests, applying every flag as you go — catch DRY/SRP/SSOT/coupling/naming violations and make the small fix *before* writing the bad version, not after. Also follow the repo's own conventions (structure, error handling, docstrings). Refactor green. Commit this section atomically.

**e. Update the PR body to match what just landed (if a PR exists).** When a section goes green, the PR body must move with it — a body that describes intent the code no longer matches is worse than no body. So after committing each section (and especially when a **key decision shifted, behaviour drifted, or scope changed** during the build):
- **Tick the "what will land" checklist item** for the section now complete.
- **Sync key decisions** — if the build refined or reversed a decision, edit the body's "Key decisions" to reflect what actually happened (and note it was refined during build). This mirrors the spec update you just made.
- **Correct scope** — if a sub-behaviour turned out to belong to a follow-up PR, move it from "what will land" to "out of scope / deferred" with the reason.
- Edit the body in place with `gh pr edit --body-file` (or `--body`); don't append a changelog of edits — the body should always read as the *current* truth, not a diff history. Skip this whole sub-step in repos that commit straight to the default branch (no PR).

**f. Next section.** Repeat a–e for the next spec section.

If implementation (or test review) reveals the spec was wrong, **update the spec first** (then the PR body), then continue. The spec stays the source of truth — never let spec, code, and PR body silently diverge.

### 6. Verify against the spec's test plan

Run exactly the checks the spec's "Test plan" section names. Every item must pass. Use `superpowers:verification-before-completion` — evidence, not assertion.

### 7. Close out

- All test-plan items green (verified, not assumed)
- Spec's "Out of scope" honored — no scope creep
- Mark the spec `Status: implemented` (or delete it if it was a throwaway session artefact — see `/clean-up`)
- **Finalise the PR body (if a PR exists).** Before flipping out of draft, do a freshness pass so the body is an accurate final record:
  - Flip the status header from `🚧 Draft — implementing` to `✅ Implemented — ready for review`.
  - Every "what will land" checklist item is ticked and reflects what actually shipped; key decisions and scope match the merged code.
  - **Add a "🧪 Manual test" section if manual verification is relevant** — i.e. when the change has user-observable behaviour a reviewer should confirm by hand (a UI affordance, an end-to-end flow, anything tests can't fully assert). Use the manual-test block in **`references/pr-body-template.md`** as the shape: a **checklist of concrete steps** a human ticks as they go — setup (how to run the stack / where to look), the exact steps, what they should observe at each, and how to cross-check it's real (e.g. against DevTools, logs, or a second source). Call out any environment caveats (local vs remote, "only works after PR #X lands"). Skip this section when the change is purely internal (a refactor, a lib with full test coverage) and there's nothing meaningful to click.
  - Run `gh pr ready` to take it out of draft once the body is accurate and all checks pass.
- Finish the branch per step 3: merge the PR, and **delete the branch** (unless the repo's convention says otherwise). Commit messages reference what the spec delivered.

## Rules

- **Align with the repo's standards first (step 0), house standard as fallback.** Before writing anything, check for the repo's own spec format, git/PR workflow, and PR-body convention, and follow them. This skill's `references/` templates and draft-PR lifecycle are the *default* for repos that have no convention — and are overridden only by a repo convention or an explicit user opt-out, never silently.
- **No production code before the spec exists** for non-trivial work
- **The spec defines goals, not code.** Specs should rarely contain code — only an exact contract (API signature, wire format, data shape) that prose can't express unambiguously. Code that explains *how* you'll build it belongs in the implementation; putting it in the spec defeats spec-first thinking.
- **No implementation before a reviewed, goal-aligned failing test.** Within each section: write the failing test, have it reviewed against the spec's goal (via `/step-back`), align, *then* implement. A passing test that doesn't prove the goal is worse than no test.
- **One section at a time.** Don't write all tests or all code up front — cycle test→review→implement per spec section, so each goal is locked in before the next.
- **Spec and code never diverge** — if you change direction, change the spec first
- **Keep the spec short** — goal, behavior/design goals, decisions, scope, tests. If it's longer than the code, it's too long
- **A spec is not a plan dump** — it's the contract the tests must encode and the code must satisfy, written so verification is mechanical
- **Branch per the repo's blueprint** — follow the repo's git/PR convention if it has one; otherwise feature-branch → PR → merge → delete the branch when done
- **Open the PR as a draft, seeded from the spec, before implementing** — but only in repos that use PRs; repos that commit straight to the default branch have no PR step. The body is the spec's public face: header/status, summary, spec link, an acceptance-criteria checklist, key decisions, scope, and sibling-PR relationships, with authorship credited per repo convention.
- **The PR body never diverges from the code** — sync it as each section lands (tick the checklist, update decisions/scope when the build drifts), edited in place to read as current truth, not a changelog. Spec, code, and PR body stay in lockstep.
- **Add manual-verification steps to the PR body at close-out when relevant** — a checklist of concrete, tickable steps (setup, actions, what to observe, how to cross-check) for any user-observable behaviour; skip for purely internal changes. Flip out of draft (`gh pr ready`) only once the body is accurate and checks pass.
- **Always invoke `swe-best-practices` before implementing each section** (step 5d) — SDD auto-loads it (via the Skill tool), whether or not the user invoked it explicitly. SDD owns the workflow; `swe-best-practices` governs the shape of the code it produces.

## When to skip

Trivial, single-file, unambiguous changes (a typo, a rename, a config tweak) don't need a spec — just do them with TDD. When unsure whether something is "trivial", it isn't: write the spec.
