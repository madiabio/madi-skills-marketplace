# PR-body template (house standard)

The fallback PR-body shape for `/spec-driven-development` in repos that use PRs
but have **no** PR template / body convention of their own. If the repo has a
`.github/PULL_REQUEST_TEMPLATE.md`, a house style visible in recent sibling PRs,
or an `## Agent skills` / contributing convention, prefer **that** and only
borrow the ideas below (living checklist, spec link, manual-test section) where
the repo's template has no equivalent.

The body is the spec's public face: a reviewer should understand the change
without opening the diff. It is a **living record** — open it as a draft seeded
from the spec, keep it in lockstep with the code as each section lands, and
finalise it (status flip + manual-test steps) at close-out. Always edit in place
so it reads as *current truth*, never a changelog of edits.

Placeholders are `<…>`. Drop any section that doesn't apply (e.g. "Relationship
to other PRs" for a standalone change).

---

```markdown
# <PR title> — <one-line what-it-does>

**Milestone / board:** <ref, if the repo tracks one>
**Status:** 🚧 Draft — implementing   <!-- → ✅ Implemented — ready for review at close-out -->
**Relationship:** <independent / depends on #<n> / blocks #<n>>

<One-paragraph plain-language summary of what the change does and why.>

## 📄 Spec
`<.claude/specs/<slug>.md>` — Status: <draft → implemented>.

## ✅ What <will land / landed>
<!-- One item per acceptance criterion. Unchecked at draft; tick each as its
     section goes green. Mention the key file(s) the reviewer should look at. -->
- [ ] <criterion> — <where it lives / what it does>
- [ ] <criterion> — <…>

## 🔑 Key decisions
<!-- Lifted from the spec's "Key decisions"; refine in place if the build
     changes one, noting it was refined during build. -->
- **<decision>**: <choice> — <reasoning / trade-off>

## 🔎 Scope
<What this PR covers, and explicitly what it does NOT — deferred sub-behaviours
move here from "what will land" with the reason and the follow-up PR.>

## Relationship to other PRs
<Dependencies, what's deferred to a follow-up, board references.>

---

## 🧪 Manual test — verify in the UI
<!-- Add at close-out ONLY when the change has user-observable behaviour a
     reviewer should confirm by hand. Skip entirely for purely internal changes
     (refactors, libs with full test coverage). Write as a checklist a human
     ticks as they go. -->

**What this proves:** <the one behaviour the steps are demonstrating.>
**Where it works:** <local / remote / both; any env caveat, e.g. "only after #<n> lands">.

### Setup
- [ ] <how to run the stack / open the app / where to look>

### Steps
- [ ] <action> → <what you should observe>
- [ ] <cross-check the observation against a second source — DevTools, logs, a quoted id>
- [ ] <action> → <what should change>

<!-- Authorship credit per repo convention. If the repo follows the
     coderabbit-resolve style: -->
Author: Claude <model>, <effort>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```
