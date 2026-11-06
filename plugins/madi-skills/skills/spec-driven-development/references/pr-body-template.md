<!--
House PR body, the fallback when the repo has no PR template (a repo template wins; fold these
sections into it). Prose paragraphs; bullets only for genuinely list-shaped content. Every ticket or
PR reference is a markdown link with its number and title. The PR is opened, and stays, a draft.
-->

<Opening paragraph: the big picture. Where this PR sits in the larger feature (epic or ticket, the
stack, what comes before and after), so a reviewer who knows nothing can orient. Link the spec:
`.claude/specs/<slug>.md` (status: implementing).>

## Current state on UAT

<What the app does in this area today, user-visible where possible. Use the repo's staging or test
environment's name if it has no UAT.>

## Future state after this PR

<What changes once it merges. If nothing is visible yet (infra, schema, a lower stack PR), say so
plainly.>

## What changed

<The change, in prose. Then the acceptance checklist from the spec, unticked at draft time and ticked
as each section goes green:>

- [ ] <spec acceptance criterion 1>
- [ ] <spec acceptance criterion 2>

## Why

<The reason, citing the ticket and any ADR. Key decisions from the spec, refined as the build teaches
more. Out of scope, with where it goes.>

## Testing

<Automated tests run, with counts, and the teeth-checks (which mutation turned which tests red).>

<Manual test, when there is user-observable behaviour; otherwise one line saying why there's nothing
to test by hand:>

- [ ] Setup: <how to run the stack, or which environment, and any caveat such as "only after #X lands">
- [ ] <Step>: <what to do> → <what you should see>
- [ ] Cross-check: <how to confirm it's real: DevTools, logs, a second source>

<Authorship per repo convention, e.g. the 🤖 Generated with Claude Code footer.>
