---
name: spec-driven-development
description: Write a short, sharp spec of design GOALS (rarely any code) BEFORE implementing, then build against it section by section with TDD — write failing tests for each spec section, have a reviewer confirm the tests actually encode the spec's goals (via /zoom-out) before implementing to green, on a feature branch that follows the repo's git convention. Invoke when the user says "spec-driven development", "SDD", "write a spec first", "spec this out before building", or before starting any non-trivial, multi-file, or ambiguous implementation.
---

# Spec-Driven Development (SDD)

Write the spec first, align on it, then implement against it. The spec is the contract; the code conforms to the spec, not the other way around. Calibrate to size — a one-line fix needs no spec; anything multi-step, multi-file, or ambiguous does.

## Process

### 1. Write the spec (before any code)

Create a markdown spec. Location: `.claude/specs/<slug>.md` (or the repo's existing spec convention — `docs/specs/`, `specs/` — check first). Keep it tight; a spec is not a novel.

**A spec defines design *goals*, not implementation. It should rarely contain code.** The whole point of spec-first is to think at the level of *what* must be true and *why* before getting pulled into *how* — dropping code into the spec collapses that altitude and quietly turns the spec into a draft implementation, which defeats the purpose. So write the spec in terms of behavior, constraints, and acceptance criteria. Only include a code snippet when a contract genuinely can't be expressed in prose without ambiguity — an exact public API signature, a wire/serialization format, a specific data shape another system depends on. If you're tempted to write code to explain *how* you'll build it, that belongs in the implementation, not the spec.

```markdown
# <Title>

**Status:** draft
**Scope:** <one line — what this delivers>

## Goal
<one paragraph: what this accomplishes and why it matters>

## Behavior & design goals
<what must be TRUE when this is done, in terms of observable behavior and
design properties — not how it's coded. Each goal should be something a test
can later prove. Describe the data flow and the modules/boundaries involved at
the level of responsibility, not implementation. Name files only when the
boundary itself is a decision.>

## Acceptance criteria
- <a concrete, checkable statement of done — these become the test sections in step 4>

## Key decisions
- **<decision>**: <choice> — <reasoning / trade-off>

## Out of scope
- <what this explicitly does NOT do — deferred or rejected>

## Risks & mitigations
- <risk> → <mitigation>

## Test plan
<how you'll prove it works — concrete checks and commands, not "write tests".
Maps to the acceptance criteria above.>
```

### 2. Sharpen the spec

Before implementing, stress-test it:
- **User present?** Use `/grill-me` or `/grill-with-docs` to challenge the design.
- **Autonomous?** Use `/self-grill` (griller + domain expert) until the spec is sharp.
- Resolve every "I'm not sure" in the spec before writing code. Ambiguity in the spec becomes bugs in the code.

### 3. Set up the work branch

Before writing tests or code, decide where the work lands — **let the repo's existing framework be the blueprint**:
- If the repo documents a git/PR workflow (in `CLAUDE.md` / `AGENTS.md`, an ADR, or a memory like the dotfiles "commit straight to main" rule), follow it.
- If there's no such convention, default to best practice: create a **feature branch**, do the work there, open a **PR**, and after merge **delete the branch** (local + remote). Don't leave dead branches around.

### 4. Build the spec, one section at a time — TDD with a test-review loop

Implement the spec **section by section** (one acceptance-criterion / design-goal cluster at a time), not all at once. For *each* section, run this loop before touching implementation code:

**a. Write the failing tests for this section (test-writer).** Spawn a `test-writer` subagent (or use `superpowers:test-driven-development` inline if the section is tiny). It writes tests that target *this section's goals* and watches them fail for the right reason (red). No implementation yet.

**b. Review the tests against the spec's goals (reviewer).** Spawn a separate `reviewer` subagent. Its job is NOT "are these good tests" in the abstract — it's "**do these tests actually prove the GOAL this spec section describes**, or do they assert incidental behavior that could pass while the goal is unmet?" The reviewer uses `/zoom-out` to lift back to what the section is really trying to achieve, then checks the tests against that. (If subagents aren't warranted — present user driving a small change — the main agent can play reviewer inline, but keep the roles distinct: write, then critically re-read against the goal.)

**c. Iterate until aligned.** test-writer and reviewer go back and forth — reviewer flags gaps ("the spec says X must hold under concurrent writes; no test exercises that"), test-writer adds/fixes tests — until both are confident the failing tests genuinely encode the section's goals. Only then proceed.

**d. Implement to green.** Before writing any implementation, **invoke the `swe-best-practices` skill** (via the Skill tool) and load its in-flight checklist — do this even if the user only invoked `/spec-driven-development`; you don't wait to be asked. Then write the minimum implementation to pass this section's tests, applying every flag as you go — catch DRY/SRP/SSOT/coupling/naming violations and make the small fix *before* writing the bad version, not after. Also follow the repo's own conventions (structure, error handling, docstrings). Refactor green. Commit this section atomically.

**e. Next section.** Repeat a–d for the next spec section.

If implementation (or test review) reveals the spec was wrong, **update the spec first**, then continue. The spec stays the source of truth — never let code and spec silently diverge.

### 5. Verify against the spec's test plan

Run exactly the checks the spec's "Test plan" section names. Every item must pass. Use `superpowers:verification-before-completion` — evidence, not assertion.

### 6. Close out

- All test-plan items green (verified, not assumed)
- Spec's "Out of scope" honored — no scope creep
- Mark the spec `Status: implemented` (or delete it if it was a throwaway session artefact — see `/clean-up`)
- Finish the branch per step 3: open/update the PR, merge, and **delete the branch** (unless the repo's convention says otherwise). Commit messages reference what the spec delivered.

## Rules

- **No production code before the spec exists** for non-trivial work
- **The spec defines goals, not code.** Specs should rarely contain code — only an exact contract (API signature, wire format, data shape) that prose can't express unambiguously. Code that explains *how* you'll build it belongs in the implementation; putting it in the spec defeats spec-first thinking.
- **No implementation before a reviewed, goal-aligned failing test.** Within each section: write the failing test, have it reviewed against the spec's goal (via `/zoom-out`), align, *then* implement. A passing test that doesn't prove the goal is worse than no test.
- **One section at a time.** Don't write all tests or all code up front — cycle test→review→implement per spec section, so each goal is locked in before the next.
- **Spec and code never diverge** — if you change direction, change the spec first
- **Keep the spec short** — goal, behavior/design goals, decisions, scope, tests. If it's longer than the code, it's too long
- **A spec is not a plan dump** — it's the contract the tests must encode and the code must satisfy, written so verification is mechanical
- **Branch per the repo's blueprint** — follow the repo's git/PR convention if it has one; otherwise feature-branch → PR → merge → delete the branch when done
- **Always invoke `swe-best-practices` at step 4d** — SDD auto-loads it (via the Skill tool) before implementing each section, whether or not the user invoked it explicitly. SDD owns the workflow; `swe-best-practices` governs the shape of the code it produces.

## When to skip

Trivial, single-file, unambiguous changes (a typo, a rename, a config tweak) don't need a spec — just do them with TDD. When unsure whether something is "trivial", it isn't: write the spec.
