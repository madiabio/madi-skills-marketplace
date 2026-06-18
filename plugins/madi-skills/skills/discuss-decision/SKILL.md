---
name: discuss-decision
description: Discuss the outcomes of a /research-decision report — pressure-test its premises against the codebase FIRST, walk the trade-offs without anchoring on its recommendation, converge on a decision, and capture the verdict as an ADR (or ADR-bound notes). Use after /research-decision produces a report (`.claude/research/<slug>-DECISION.md`), or when the user says "discuss the trade-offs", "talk through that decision", "what should we actually pick", "turn this research into an ADR", or "/discuss-decision". For surfacing already-recorded open ADRs use /surface-deferred-decisions; to do the research itself use /research-decision.
---

# Discuss a decision

Turn a finished `/research-decision` report into an actual decision and a durable ADR record. The report is ordered key-findings → approaches → trade-off table → risks → **recommendation LAST** (deliberately, to avoid anchoring the reader). Your job is the discussion that earns or overturns that recommendation: **verify its premises, walk the trade-offs even-handedly, converge with the user, capture the verdict.**

The core value — and the reason this skill exists — is **catching wrong premises that flip the recommendation.** (Motivating case: a DataStack-persistence report recommended X; discussion found two false premises — an ADR mis-marked `accepted`, and "UAT gets torn down" which was false — and correcting them flipped the answer to Y.) Do not rubber-stamp the report.

## Process

### 0. Acquire and read the report
Resolve the input, in order: (1) explicit path in the invocation; (2) a `*-DECISION.md` already in conversation context; (3) auto-find `ls -t .claude/research/*-DECISION.md`. **If more than one exists or it's ambiguous, present the candidates and ASK** — read each one's Status/Supersedes header first, because superseded and stale reports coexist and newest isn't always right.

Read the whole report. State up front: *"I'll check this report's premises before we weigh its recommendation — premises are where these reports go wrong."* Treat the recommendation as a hypothesis to earn, not a default.

### 1. Extract and VERIFY PREMISES first (the anti-anchoring core)
Enumerate the factual claims the recommendation rests on (from the framing/key-findings sections and any Status header). Classify and act on each:

- **Codebase-checkable** (e.g. "UAT is never torn down", "Aurora has no deletionProtection today") → **verify NOW** with Grep/Read/Bash, read-only. Do **not** trust the report — the motivating flip came from grep-confirming "no UAT teardown workflow exists."
- **User-knowledge** (e.g. "UAT data is precious vs re-seedable") → ask via `AskUserQuestion`, one premise per question, with the report's stated assumption as one option and "actually, it's X" as another.
- **External / needs-research** → flag as a risk; spawn ONE narrow `topic-researcher` only if the premise is pivotal and cheaply closable. Do not re-run the whole research.

Produce a **premise ledger**: each premise marked ✓verified / ✗false (+ correction) / ?open. **If any pivotal premise is false, say so explicitly and re-derive the recommendation from the corrected premises before continuing.** This is the rubber-stamp guard.

### 2. Walk the trade-offs — evidence before verdict
Using the report's Approaches + Trade-off table (re-read through the corrected premises), discuss the live options **one sub-decision at a time** (a report often has several — e.g. memory placement / checkpointer durability / cutover). For each: present the options even-handedly, surface where sources disagreed, and explicitly invite the user to reach a *different* conclusion than the report. Cross-reference the codebase when a claim is checkable. **Reveal the report's recommendation only AFTER the user has weighed the options**, then ask whether it still holds given the corrected premises. (This is the `grill-with-docs` "challenge against the code" posture, scoped to the report.)

### 3. Converge
Drive each sub-decision to one of: **decided** (chosen option + rationale), **deferred** (real concern consciously parked, with a `reactivate_when` trigger), or **still-open** (name the spike/research needed). Deferral is a first-class outcome — don't force closure on something genuinely unresolved.

### 4. Capture as an ADR — incrementally
Write/update the ADR file **as each sub-decision crystallises**, not all at the end (survives session crashes; matches how `grill-with-docs` updates docs inline).

**Detect the repo's ADR convention — do not assume it.** Look for `docs/adr/` (and per-area registers like `infrastructure/docs/adr/`, `apps/*/docs/adr/`), a `_TEMPLATE.md`, and a `README.md` describing the format and filename/frontmatter convention. Conform to whatever is found. If **no** ADR convention exists, fall back to writing ADR-bound notes to a sensible location (`docs/adr/` or `.claude/`) and tell the user.

When a convention exists, honour it exactly. Common shape (verify against the repo):
- **Filename/id** per the repo's convention (e.g. `ADR-<slug>-<YYYY-MM-DD>-<author>.md`; date from environment context, never guessed; author from the git user).
- **Frontmatter** — a one-line `summary:` is mandatory where the repo uses it (it's what SessionStart/PreToolUse hooks display); plus `status:`, `reactivate_when:` (for deferred), `relates_to:`, and a **`research:` field back-linking to the `*-DECISION.md`** (this closes the research↔decision loop).
- **`status:`** — `accepted` if decided and being implemented, `proposed` if intended-not-committed, `deferred` if parked.
- **Body** — follow the repo's template (Context / Decision / Options considered / Consequences / Resolution Log). **Record the corrected premises in Context** — that's the "why the answer is what it is." Link the report rather than restating it.
- **Placement** — single-area decision → that area's `docs/adr/`; cross-cutting (≥2 areas) → global `docs/adr/` plus a pointer stub in each affected area.

**Updating an existing open ADR:** APPEND a dated `## Resolution Log` entry — never rewrite prior entries; flip `status:` only if the verdict changed the lifecycle. If the decision touches an **already-open** ADR, invoke `/surface-deferred-decisions` rather than reimplementing its matching logic.

**Mid-decision:** if the user wants to think more, accumulate progress under a `## Notes (pre-decision)` subsection with `status: proposed`, so the next session resumes — never block capture on a fully-formed decision.

### 5. Stale report on a flip
When discussion **flips** the recommendation, the **ADR is canonical** and the **report stays immutable** (it's ephemeral research). Record the corrected decision in the ADR with a note that the report's recommendation was superseded. Do **not** mutate the report.

### 6. Report back
Summarise: which premises were corrected, what was decided/deferred/left-open per sub-decision, and the ADR file paths written. **Commit only if the user asks** (conventional: `docs(adr): record <slug> decision from /research-decision`). Offer the next step — `/spec-driven-development` or `/gsd-plan-phase` to turn decisions into an executable plan.

## Interactive vs autonomous

- **Interactive (default, intended):** use `AskUserQuestion` for premise-correction and each sub-decision verdict, one thread at a time. The human correcting a false premise is the highest-value moment. Don't rubber-stamp; if an answer flips a premise, re-derive.
- **Autonomous (`/loop`, "go autonomous"):** don't route questions to the user. Self-grill — verify every codebase-checkable premise yourself. Record decisions gated on a user-only premise as `status: proposed` with the open premise listed under Risks and a `reactivate_when:` — **never `status: accepted` autonomously on an unverified user-only premise.** If a pivotal premise is both unverifiable and blocking, `/discord-ping [blocked]` rather than guess.

## Overlap — compose, don't duplicate

| Skill | Its job | Relationship |
|---|---|---|
| `/research-decision` | Produces the report (web/docs research, bias-aware writeup). | **Upstream.** This skill is a no-op without its output. Does NOT re-run research — only narrow gap-filling on a single pivotal premise. |
| `/grill-me`, `/grill-with-docs` | Build/sharpen a plan from scratch, one question at a time. | **Reuse the posture, not the scope.** This skill is scoped to an existing report's claims and converges fast where the report is well-founded. If discussion turns into open-ended plan design, hand off to `/grill-with-docs`. |
| `/surface-deferred-decisions` | Reads/resurfaces already-open ADRs; records keep/drop verdicts. | **Shares the write path, opposite direction.** This skill creates/updates the ADR a fresh decision warrants. For already-open ADRs, invoke `/surface-deferred-decisions` rather than reimplementing its matching logic. |

## Key rules

- **Premises before recommendation, always.** A flipped premise flips the answer.
- **Don't rubber-stamp; don't re-research.** The report is a hypothesis to earn. Narrow gap-filling only.
- **Verify codebase-checkable claims yourself** (Grep/Read) — don't trust the report.
- **Detect and conform to the repo's ADR convention**; fall back gracefully if none exists.
- **Reuse the ADR write path**; invoke `/surface-deferred-decisions` for already-open ADRs.
- **Deferral is a valid outcome** — capture it with `reactivate_when:`.
- **Capture notes even mid-decision** (`status: proposed`, `## Notes (pre-decision)`).
- **Auto-find the report carefully** — read the Status/Supersedes header; ask if ambiguous.
- **Report immutable on a flip** — the ADR is canonical.
- **Commit only when asked.**

## Definition of done

1. Premise ledger stated, false premises called out, recommendation re-derived if needed.
2. Each sub-decision resolved to decided / deferred / open.
3. ADR file(s) written/updated in the correct register — valid `summary:` frontmatter, `research:` back-link, corrected premises in Context, append-only Resolution Log for updates.
4. Report ↔ ADR cross-reference closed.
5. A future reader hitting the SessionStart/PreToolUse hook sees an accurate one-line `summary:` and can trace it back to the research. Committed only if asked.
