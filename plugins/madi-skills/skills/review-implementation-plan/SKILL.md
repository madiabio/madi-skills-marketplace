---
name: review-implementation-plan
description: Systematically evaluate a colleague-authored implementation plan document. Runs four parallel tracks — codebase claim verification, compliance/domain audit, internal consistency + gap analysis, and sequencing review — then produces a structured PLAN-REVIEW.md with BLOCKER / WARNING / INFO findings.
argument-hint: "<path-to-plan> [--domain <pbs|fhir|au-health|general>] [--output <path>]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
---

<objective>
Given a free-form implementation plan document (not a GSD-generated PLAN.md), run a systematic
four-track evaluation and produce a structured review document with actionable findings.

This skill is for plans received from colleagues — not for GSD-managed phase plans (use
/gsd-plan-review-convergence for those).
</objective>

<context>
Plan path: extracted from $ARGUMENTS (required — first positional arg)
Domain hint: extracted from --domain flag (optional — helps pick the right compliance agent)
Output path: extracted from --output flag (default: same directory as plan, named PLAN-REVIEW.md)

Available domain hints and their compliance agents:
- pbs: pbs-scripting-expert
- fhir: fhir-au-terminology-expert
- au-health: au-health-integrations-expert
- general: no compliance agent (skip Track B or use topic-researcher)
</context>

<process>

## Step 0: Pre-flight

1. Verify the plan file exists at the given path. If not, ask the user to correct it.
2. Read the first 200 lines of the plan to determine:
   - The feature domain (to pick the right compliance agent)
   - Approximate size and structure
   - Whether a domain hint was given; if not, infer from the plan content
3. Set the output path. Default: `<plan-directory>/PLAN-REVIEW.md`.

## Step 1: Announce and dispatch

Tell the user: "Running four-track plan review for [plan name]. Dispatching agents in parallel."

Dispatch ALL FOUR tracks as background agents simultaneously. Do not wait for one before starting another.

### Track A — Codebase claim verification

Spawn a `gsd-assumptions-analyzer` agent with a prompt that:
- Lists every codebase fact stated in the plan (file paths, table/column names, procedure names,
  migration numbers, constants, feature flags, CASL subjects)
- Asks it to verify each against the actual repo using Read/Grep/Glob
- Groups results as PASS / FAIL / UNKNOWN
- Asks it to note any "surprises" — things it found that the plan didn't mention but are relevant

Build this prompt by scanning the plan for patterns like:
- "EXISTS", "confirmed", "✅" (claimed present)
- "ABSENT", "not present", "❌" (claimed absent)
- File paths (`apps/api/src/...`, `apps/web/src/...`)
- Column names in schema tables
- Migration journal claims (last idx, next number)
- Constant/enum values

### Track B — Compliance / domain audit

Spawn the appropriate domain-expert agent (based on domain hint or inference) with a prompt that:
- Lists every compliance rule stated in the plan (regulatory dates, phone numbers, authority
  requirements, mandatory fields, legal obligations)
- Asks it to evaluate each as ACCURATE / INACCURATE / PARTIALLY ACCURATE / NEEDS VERIFICATION
- Asks for an overall compliance risk per finding: LOW / MEDIUM / HIGH / CRITICAL
- Asks for top 3 compliance risks in the plan

If domain is "general" or no expert agent exists, spawn a `topic-researcher` agent instead.

### Track C — Internal consistency and gap analysis

Spawn a general-purpose agent with a prompt that:
- Reads the ENTIRE plan (paginating with offset as needed)
- Looks for: internal contradictions, code snippet bugs, missing specifications,
  dependency/sequencing issues, overengineering vs MVP scope, testing gaps
- Evaluates all TypeScript/SQL snippets for correctness against the codebase conventions:
  - Drizzle ORM patterns (never raw pg/Pool, never SET LOCAL search_path outside TenantScopedRepository)
  - oRPC error types (ORPCError not standard Error)
  - BetterAuth/CASL patterns
  - TDD requirement (tests before code)
- Produces a structured report with a "Top 5 most critical issues" summary

### Track D — Architecture and integration review

Spawn a `Plan` agent with a prompt that:
- Reads the plan and evaluates the proposed architecture against the codebase's established patterns
- Specifically checks: Does the proposed service/repository structure match existing patterns?
  Are new oRPC procedures registered correctly? Does the migration strategy respect existing
  tenant/public schema split? Are feature flags consistent with how others are defined?
- Flags deviations from codebase norms as WARNING or INFO

## Step 2: Collect results

Wait for all four agents to complete. Summarise any agent that returned an error.

## Step 3: Synthesise into PLAN-REVIEW.md

Write `PLAN-REVIEW.md` to the output path with this structure:

```markdown
# Plan Review: [Plan Name]

**Plan**: [path]
**Reviewed**: [date]
**Review session**: [session identifier if provided]
**Tracks run**: Codebase Verification, Compliance Audit, Internal Consistency, Architecture Review

---

## Executive Summary

[2-3 sentences: overall verdict, count of BLOCKERs, top risk]

## BLOCKER findings

[Findings that must be resolved before implementation starts]
Each entry:
### B-NNN: [Title]
**Track**: [A/B/C/D]
**Details**: [What the problem is]
**Evidence**: [File:line or source citation]
**Required action**: [What must be done]

## WARNING findings

[Findings that should be addressed but don't block Slice 1]

## INFO findings

[Minor gaps, suggestions, things to document]

## Open questions requiring author response

[Questions surfaced during review that only the plan author can answer]

## Track summaries

### Track A — Codebase claims
[PASS/FAIL table]

### Track B — Compliance
[Per-claim verdict table]

### Track C — Internal consistency
[Top 5 issues summary]

### Track D — Architecture
[Summary of pattern deviations]
```

## Step 4: Report to user

Tell the user:
- Where the review file was written
- Count of BLOCKER / WARNING / INFO findings
- The top 3 blockers by name
- Whether any new agents or skills were recommended

</process>
