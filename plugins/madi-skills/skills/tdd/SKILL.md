---
name: tdd
description: Test-driven development with red-green-refactor loop. Use when user wants to build features or fix bugs using TDD, mentions "red-green-refactor", wants integration tests, or asks for test-first development.
---

# Test-Driven Development

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through public APIs. They describe _what_ the system does, not _how_ it does it. A good test reads like a specification - "user can checkout with valid cart" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means (like querying a database directly instead of using the interface). The warning sign: your test breaks when you refactor, but behavior hasn't changed. If you rename an internal function and tests fail, those tests were testing implementation, not behavior.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## The one rule

> **No production code without a failing test that came first.**

Wrote the code before the test? Delete it and start fresh from the test — don't keep it "as reference", don't "adapt it" while writing the test. Adapting it *is* writing the test after the code, and a test written after the code it describes passes immediately, which proves nothing about whether it tests the right thing. The only sanctioned exceptions are the ones below, and they're a conversation with the user, not a unilateral call.

## When to Use

Apply to new features, bug fixes, and behavior changes. Exceptions worth raising with the user first: throwaway prototypes (then discard the exploration and rebuild test-first), generated code, and pure config. "This one is too simple / I'm in a hurry / I'll test it after" is not an exception — it's the rationalization the rule exists to catch. See the table below.

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal slicing" - treating RED as "write all tests" and GREEN as "write all code."

This produces **crap tests**:

- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- You end up testing the _shape_ of things (data structures, function signatures) rather than user-facing behavior
- Tests become insensitive to real changes - they pass when behavior breaks, fail when behavior is fine
- You outrun your headlights, committing to test structure before understanding the implementation

**Correct approach**: Vertical slices via tracer bullets. One test → one implementation → repeat. Each test responds to what you learned from the previous cycle. Because you just wrote the code, you know exactly what behavior matters and how to verify it.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```

## Workflow

### 1. Planning

When exploring the codebase, use the project's domain glossary so that test names and interface vocabulary match the project's language, and respect ADRs in the area you're touching.

Before writing any code:

- [ ] Confirm with user what interface changes are needed
- [ ] Confirm with user which behaviors to test (prioritize)
- [ ] Identify opportunities for [deep modules](deep-modules.md) (small interface, deep implementation)
- [ ] Design interfaces for [testability](interface-design.md)
- [ ] List the behaviors to test (not implementation steps)
- [ ] Get user approval on the plan

Ask: "What should the public interface look like? Which behaviors are most important to test?"

**You can't test everything.** Confirm with the user exactly which behaviors matter most. Focus testing effort on critical paths and complex logic, not every possible edge case.

### 2. Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

This is your tracer bullet - proves the path works end-to-end.

### 3. Incremental Loop

For each remaining behavior:

```
RED:   Write next test → fails
GREEN: Minimal code to pass → passes
```

Rules:

- One test at a time
- Only enough code to pass current test
- Don't anticipate future tests
- Keep tests focused on observable behavior

### 4. Refactor

After all tests pass, look for [refactor candidates](refactoring.md):

- [ ] Extract duplication
- [ ] Deepen modules (move complexity behind simple interfaces)
- [ ] Apply SOLID principles where natural
- [ ] Consider what new code reveals about existing code
- [ ] Run tests after each refactor step

**Never refactor while RED.** Get to GREEN first.

## Checklist Per Cycle

```
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
```

## When you're about to skip the test

These are the thoughts that precede every abandoned TDD session. If you catch yourself here, stop — the answer is to write the test first.

| Thought | Why it's wrong |
|---------|----------------|
| "Too simple to test" | Simple code still breaks, and the test costs 30 seconds. |
| "I'll write the tests after" | Tests written after pass immediately. Passing immediately proves nothing about whether they test the right thing. |
| "I already manually tested it" | Ad-hoc, unrecorded, un-rerunnable. Manual testing ≠ a test. |
| "Deleting the code I wrote is wasteful" | Sunk cost. The time is already spent; keeping code you can't trust is the actual waste. |
| "I'll keep it as reference and write the test first" | You'll adapt the reference — that's testing after. Delete means delete. |
| "I need to explore the shape first" | Fine. Explore, then throw the exploration away and start test-first. |
| "Hard to test" | Listen to that. Hard to test = hard to use. Fix the interface, don't skip the test. |
| "TDD is dogmatic, I'm being pragmatic" | Test-first finds bugs before commit. Debugging in prod later is the un-pragmatic path. |
