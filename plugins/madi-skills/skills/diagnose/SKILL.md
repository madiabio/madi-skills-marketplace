---
name: diagnose
description: Disciplined diagnosis loop for hard bugs and performance regressions. Reproduce → minimise → hypothesise → instrument → fix → regression-test. Use when user says "diagnose this" / "debug this", reports a bug, says something is broken/throwing/failing, or describes a performance regression. Pass "tdd" (/diagnose tdd) to make the failing regression test mandatory and fix under the tdd skill.
argument-hint: "[tdd] <what's broken>"
---

# Diagnose

A discipline for hard bugs. Skip phases only when explicitly justified.

When exploring the codebase, use the project's domain glossary to get a clear mental model of the relevant modules, and check ADRs in the area you're touching.

## Modes

The first whitespace-separated token of the invocation arguments may select a mode; the rest is the bug description.

- First token is `tdd` (i.e. `/diagnose tdd ...`) → **TDD mode**. Run every phase as normal, but Phase 5 changes: the failing regression test is **mandatory** (the "no correct seam → skip it" escape is closed — see Phase 5), and once it fails for the right reason you hand the fix off to the [`tdd`](../tdd/SKILL.md) skill (invoke it via the Skill tool) so the green-and-refactor steps run under red-green-refactor discipline.
- First token is anything else, or there are no arguments → **normal mode**, and the entire argument string is the bug description.

TDD mode does **not** skip Phases 1–2. You cannot write a good failing test without first understanding and reproducing the bug — building the feedback loop and reproducing come first regardless of mode. The mode only governs how Phase 5 behaves.

## Phase 1 — Build a feedback loop

**This is the skill.** Everything else is mechanical. If you have a fast, deterministic, agent-runnable pass/fail signal for the bug, you will find the cause — bisection, hypothesis-testing, and instrumentation all just consume that signal. If you don't have one, no amount of staring at code will save you.

Spend disproportionate effort here. **Be aggressive. Be creative. Refuse to give up.**

### Ways to construct one — try them in roughly this order

1. **Failing test** at whatever seam reaches the bug — unit, integration, e2e.
2. **Curl / HTTP script** against a running dev server.
3. **CLI invocation** with a fixture input, diffing stdout against a known-good snapshot.
4. **Headless browser script** (Playwright / Puppeteer) — drives the UI, asserts on DOM/console/network.
5. **Replay a captured trace.** Save a real network request / payload / event log to disk; replay it through the code path in isolation.
6. **Throwaway harness.** Spin up a minimal subset of the system (one service, mocked deps) that exercises the bug code path with a single function call.
7. **Property / fuzz loop.** If the bug is "sometimes wrong output", run 1000 random inputs and look for the failure mode.
8. **Bisection harness.** If the bug appeared between two known states (commit, dataset, version), automate "boot at state X, check, repeat" so you can `git bisect run` it.
9. **Differential loop.** Run the same input through old-version vs new-version (or two configs) and diff outputs.
10. **HITL bash script.** Last resort. If a human must click, drive _them_ with `scripts/hitl-loop.template.sh` so the loop is still structured. Captured output feeds back to you.

Build the right feedback loop, and the bug is 90% fixed.

### Iterate on the loop itself

Treat the loop as a product. Once you have _a_ loop, ask:

- Can I make it faster? (Cache setup, skip unrelated init, narrow the test scope.)
- Can I make the signal sharper? (Assert on the specific symptom, not "didn't crash".)
- Can I make it more deterministic? (Pin time, seed RNG, isolate filesystem, freeze network.)

A 30-second flaky loop is barely better than no loop. A 2-second deterministic loop is a debugging superpower.

### Non-deterministic bugs

The goal is not a clean repro but a **higher reproduction rate**. Loop the trigger 100×, parallelise, add stress, narrow timing windows, inject sleeps. A 50%-flake bug is debuggable; 1% is not — keep raising the rate until it's debuggable.

### When you genuinely cannot build a loop

Stop and say so explicitly. List what you tried. Ask the user for: (a) access to whatever environment reproduces it, (b) a captured artifact (HAR file, log dump, core dump, screen recording with timestamps), or (c) permission to add temporary production instrumentation. Do **not** proceed to hypothesise without a loop.

Do not proceed to Phase 2 until you have a loop you believe in.

## Phase 2 — Reproduce

Run the loop. Watch the bug appear.

Confirm:

- [ ] The loop produces the failure mode the **user** described — not a different failure that happens to be nearby. Wrong bug = wrong fix.
- [ ] The failure is reproducible across multiple runs (or, for non-deterministic bugs, reproducible at a high enough rate to debug against).
- [ ] You have captured the exact symptom (error message, wrong output, slow timing) so later phases can verify the fix actually addresses it.

Do not proceed until you reproduce the bug.

## Phase 3 — Hypothesise

Generate **3–5 ranked hypotheses** before testing any of them. Single-hypothesis generation anchors on the first plausible idea.

Each hypothesis must be **falsifiable**: state the prediction it makes.

> Format: "If <X> is the cause, then <changing Y> will make the bug disappear / <changing Z> will make it worse."

If you cannot state the prediction, the hypothesis is a vibe — discard or sharpen it.

**Show the ranked list to the user before testing.** They often have domain knowledge that re-ranks instantly ("we just deployed a change to #3"), or know hypotheses they've already ruled out. Cheap checkpoint, big time saver. Don't block on it — proceed with your ranking if the user is AFK.

## Phase 4 — Instrument

Each probe must map to a specific prediction from Phase 3. **Change one variable at a time.**

Tool preference:

1. **Debugger / REPL inspection** if the env supports it. One breakpoint beats ten logs.
2. **Targeted logs** at the boundaries that distinguish hypotheses.
3. Never "log everything and grep".

**Tag every debug log** with a unique prefix, e.g. `[DEBUG-a4f2]`. Cleanup at the end becomes a single grep. Untagged logs survive; tagged logs die.

**Multi-component bugs.** When the bug lives in the seams between components (CI→build→sign, API→service→DB) rather than inside one function, don't guess which layer is at fault — instrument every boundary at once and read off where good becomes bad. When the error surfaces deep in the call stack, trace the bad value backward to its source rather than guarding at the crash site. Both techniques are in [multi-component-tracing.md](multi-component-tracing.md).

**Perf branch.** For performance regressions, logs are usually wrong. Instead: establish a baseline measurement (timing harness, `performance.now()`, profiler, query plan), then bisect. Measure first, fix second.

## Phase 5 — Fix + regression test

Write the regression test **before the fix** — but only if there is a **correct seam** for it.

A correct seam is one where the test exercises the **real bug pattern** as it occurs at the call site. If the only available seam is too shallow (single-caller test when the bug needs multiple callers, unit test that can't replicate the chain that triggered the bug), a regression test there gives false confidence.

**In normal mode**, if no correct seam exists, that itself is the finding. Note it — the codebase architecture is preventing the bug from being locked down — and flag it for the next phase.

**In TDD mode (`/diagnose tdd`)**, the test is not optional. A shallow seam means you have not yet found the right one, not that you skip the test. Widen the loop (a higher-level integration or e2e seam often exercises the real bug pattern when no unit seam does), or treat the missing seam as a blocker to surface to the user — but do **not** fix without a failing test that reproduces the bug. The whole point of this mode is "no fix without a failing test first".

Then, with a correct seam:

1. Turn the minimised repro into a failing test at that seam.
2. Watch it fail — and confirm it fails for the *right reason* (the bug, not a typo or setup error).
3. **In TDD mode**, hand the fix off to the [`tdd`](../tdd/SKILL.md) skill: invoke it via the Skill tool and run green → refactor under red-green-refactor discipline, with this failing test as the starting RED. **In normal mode**, just apply the fix.
4. Watch it pass.
5. Re-run the Phase 1 feedback loop against the original (un-minimised) scenario.

**If three fixes have failed, stop fixing and question the architecture.** When each fix either reveals a new problem in a different place, requires "massive refactoring" to land, or creates fresh symptoms elsewhere, that is not a run of bad hypotheses — it's a signal the underlying structure is wrong (hidden coupling, shared mutable state, a pattern fighting the grain of the system). A fourth fix attempt on the same architecture is thrashing. Surface this to the user, and route to `/improve-codebase-architecture` with the specifics rather than continuing to patch symptoms.

## Phase 6 — Cleanup + post-mortem

Required before declaring done:

- [ ] Original repro no longer reproduces (re-run the Phase 1 loop)
- [ ] Regression test passes (in normal mode, a documented absence of seam is acceptable; in TDD mode the test is mandatory)
- [ ] All `[DEBUG-...]` instrumentation removed (`grep` the prefix)
- [ ] Throwaway prototypes deleted (or moved to a clearly-marked debug location)
- [ ] The hypothesis that turned out correct is stated in the commit / PR message — so the next debugger learns

**Then ask: what would have prevented this bug?** If the answer involves architectural change (no good test seam, tangled callers, hidden coupling) hand off to the `/improve-codebase-architecture` skill with the specifics. Make the recommendation **after** the fix is in, not before — you have more information now than when you started.
