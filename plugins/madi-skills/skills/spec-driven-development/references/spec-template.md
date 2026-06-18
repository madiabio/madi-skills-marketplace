# Spec template (house standard)

The fallback spec shape for `/spec-driven-development` when the repo has no spec
convention of its own. If the repo already has a spec format (an existing
`.claude/specs/`, `docs/specs/`, a PRD/ADR layout, a template file), prefer
**that** — this is only the default.

**A spec defines design *goals*, not implementation. It should rarely contain
code.** Write in terms of behavior, constraints, and acceptance criteria. Only
include a code snippet when a contract genuinely can't be expressed in prose
without ambiguity — an exact public API signature, a wire/serialization format,
a specific data shape another system depends on. If you're tempted to write code
to explain *how* you'll build it, that belongs in the implementation, not the
spec. Keep it tight; a spec is not a novel — if it's longer than the code, it's
too long.

---

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
- <a concrete, checkable statement of done — these become the test sections in the build loop, and the "what will land" checklist in the PR body>

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
