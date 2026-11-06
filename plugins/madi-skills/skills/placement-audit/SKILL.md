---
name: placement-audit
description: Read-only audit of whether code in a branch/stack/diff lives in the right file and
  layer — separation-of-concerns leaks between repository / service / procedure (or handler,
  router, component), imports that point the wrong way, helpers parked in a file that owns
  something else, and duplicated types that should have one home. Use when the user says
  "audit the layering", "separation of concerns check", "is this in the right place", or
  "/placement-audit". Also run as one of the checks inside /audit.
---

# Placement audit

Follow `~/.claude/skills/audit/shared.md` for read-only rules, scope, ground truth, calibration
and finding format.

The test: **if a reader went looking for this code, is this where they'd look?** Each layer and
each file should own one concern, and the code in it should be about that concern.

## First: write down the repo's layer model
Derive it from ADRs, CONTEXT.md, docs, lint import rules, and above all from how code that
PREDATES the scope divides the work. State it in a few lines before judging anything. A common
shape, to check against rather than impose:
- **Repository**: data access only. Queries and persistence; no business rules, no auth
  decisions, no transport types.
- **Service**: business rules and orchestration. No raw queries or query builders, no request
  objects, HTTP status codes or transport errors (e.g. `TRPCError`).
- **Procedure / handler / router**: transport. Input validation, auth context, calling the
  service, mapping errors to responses. No queries, no business rules.
- **UI components**: rendering and interaction; data access only through the repo's usual hooks.
If the repo's model differs, use the repo's.

## Look for (each with file:line, where it belongs, and why)
1. Layer leaks: a query in a procedure; a business rule (e.g. "only active plans count") inside
   a repository query; a service throwing a transport error or reading a request; an auth check
   deep in a repository.
2. Imports pointing the wrong way: a repository importing a service, domain code importing a
   framework or transport module, a shared package importing from a feature.
3. Code in a file that owns something else: a date helper inside the billing service;
   feature-specific logic in `shared/` or `utils/`; a general helper buried in one feature that
   other features now need.
4. One concern, many homes: the same type, constant or validation schema defined in more than
   one layer. Name the single home it should have.
5. A file that owns two unrelated concerns, where the module docstring (or the file name) only
   describes one of them.

For each finding, name the target file or layer, and the cost of moving it (callers and imports
that change). Deliberate exceptions recorded in an ADR or a comment go in the leave-alone list.

## Output (standalone run, ≤600 words)
- The layer model you derived, in a few lines.
- One-paragraph diagnosis: which boundary leaks most.
- Ranked findings in the shared finding format, each as "move X from A to B".
- Leave-alone list with the decision or convention each one follows.
