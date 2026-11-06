---
name: naming-audit
description: Read-only audit of the names in a branch/stack/diff — over-explaining or
  "AI-sounding" names (repeating the type, naming the mechanism, sentence-names), synonym drift
  between layers and the product's own words, and names that promise behaviour the code doesn't
  have. Use when the user says "audit the naming", "names feel AI-generated", or "/naming-audit".
  Also run as one of the checks inside /audit.
---

# Naming audit

Follow `~/.claude/skills/audit/shared.md` for read-only rules, scope, ground truth, calibration
and finding format. The glossary and the product's UI copy matter most here: they decide which
word is right.

## Look for (each with file:line and a concrete proposal)
1. Over-explaining: the name says more than the reader needs, or says the wrong thing at
   length. A good name states the purpose once; it is not a summary of the implementation.
   - Repeats the type or kind: `jsonSchemaSchema` → `jsonObjectSchema`; `userDataObjectMap`
     → `usersById`.
   - Claims a shape it doesn't have: `catalogueToolNames` for an object that isn't a list of
     names. Name what it actually holds.
   - Names the mechanism instead of the purpose: `optionValueOf` → `forValueOf`;
     `KNOWN_FORMS` (named after the lookup, not the question it answers).
   - Reads like a sentence explaining behaviour: `nameReadsButGuardWrites`. Move the
     explanation to a comment (or the test name) and give the thing a short name.
   - Stacked words or `*Of` / `*For*` / `refuse*` / `*Facts` patterns glued on until the
     name stops reading as a phrase.
   Length alone is not a finding: `findUndeclaredOperations` is long but is one clear verb
   phrase saying what it does, so leave it. Flag a long name only when it also does one of
   the above.
2. Synonym drift: one concept named differently across layers (DB vs API vs UI vs copy).
   Map concept → names used where → one recommended name per layer, consistent with the
   glossary and existing code.
3. Misleading names: a name that suggests behaviour the code doesn't have (`get*` that writes,
   `is*` that throws, `validate*` that also transforms).
4. Inconsistency with how the repo already names services, repositories, procedures, hooks and
   components. The fix follows the repo, not a new style.

Comments, code structure and file placement are out of scope here: they belong to
/comment-audit, /code-shape-audit and /placement-audit (or run /audit for all four).

## Output (standalone run, ≤700 words)
- One-paragraph diagnosis: where the "AI feel" in the names actually comes from.
- Top 10 renames ranked by reader benefit, in the shared finding format.
- Concept → names drift table, with a recommendation per layer.
- Leave-alone list with the convention each one follows.
