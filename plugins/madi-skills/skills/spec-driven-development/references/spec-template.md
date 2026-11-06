# <Title: what will be true when this is done>

**Status:** draft | aligned | implementing | implemented
**Ticket / ADR:** <links, number and title in the link text>

## Goal

One or two sentences: what must be true afterwards, for whom, and why it matters.

## Design goals and behaviour

What the system must do, as behaviour and constraints, not code. One numbered cluster per
acceptance-criterion group; each becomes one TDD section in step 5.

1. **<Cluster name>.** The behaviour, in prose. *Acceptance:* the observable condition a test checks.
2. ...

## Shared external state (step 1b)

Either "No shared external state", or the subsystem this work plugs into:

- **Subsystem:** its name, and what it owns.
- **Model:** what is recorded, and whether facts are appended or a slot is overwritten.
- **States:** the states, and who moves each one.
- **Convergence:** how our copy catches up with the external system's truth (webhook, sweep).

| Invariant                 | Failure scenario                                                         | Expected outcome                       |
| ------------------------- | ------------------------------------------------------------------------ | -------------------------------------- |
| <e.g. money is never lost> | Crash between steps / two writers / external down / retry / state changed after our read | <what happens; how it's detected and compensated if it can't be prevented> |

## Key decisions

Each decision with its one-line reason; link an ADR when it's architectural.

## Out of scope

What this explicitly does not do, and where it goes instead.

## Open questions

Resolve every one before step 5. An unresolved question here becomes a bug in the code.

## Test plan

The exact checks step 6 runs: test files or suites, teeth-checks (which mutation must turn red), and
any manual check.
