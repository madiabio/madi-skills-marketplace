---
name: step-back
description: Step out of the implementation weeds and refocus on the bigger picture — restate the original goal, locate where we are against it, surface what's left, and detect whether the work has drifted. If it has drifted, propose concrete corrective steps. This is about the WORK and its PURPOSE, not code structure (for mapping modules/callers, use /zoom-out). Use when you've lost the thread mid-task, when a session has sprawled across many edits, when scope feels like it's creeping, or when the user says "step back" / "are we still on track" / "have we drifted" / "remind me what we're actually trying to do" / "refocus".
---

# Step Back

We have been deep in the weeds. The job of this skill is to **climb back up a layer of abstraction**, re-establish what we are actually trying to accomplish and how the current work fits into it, and — critically — catch drift before it costs more. This is about the **work and its purpose**, not just code structure. End with an honest verdict and, if we've wandered, concrete steps to get back on track.

## Instructions

1. **Restate the original goal in one sentence.** Strip the accumulated detail. What did this task/session actually set out to achieve? Pull it from the earliest framing in the conversation, the spec/plan/issue if one exists, or the user's first request — not from whatever we happen to be doing right now. If the goal was never explicit, say so.

2. **Reconstruct where we are against that goal — briefly.** Take only the context needed to orient:
   - **Session trajectory:** what has actually been done so far (decisions made, files changed, things tried/abandoned). Summarise, don't relist every edit.
   - **Artifacts:** if a spec, plan, ADR, issue, or PRD exists, read it and locate our current position within it. Reference by path — don't restate its contents.
   - **Code fit (only if it matters):** if understanding the bigger picture genuinely requires it, map how the area we're touching connects to the rest — key modules, callers, blast radius — using the project's domain glossary (`CONTEXT.md`) for vocabulary. Skip this if the disorientation is about *purpose*, not *structure*.

3. **Lay out what's left.** The shortest honest path from here to the original goal. Distinguish what's essential to the goal from what's become incidental.

4. **Detect drift — this is the point of the skill.** Explicitly ask:
   - Is what we're doing right now still in service of the original goal, or have we followed a tangent?
   - Have we expanded scope beyond what was asked, or solved a problem we invented?
   - Are we polishing/over-engineering a thing that doesn't need it?
   - Has a better path opened up that makes the current approach obsolete?
   Name any drift specifically, with evidence from the session.

5. **Give a verdict.** One of:
   - **On track** — current work serves the goal; continue. Note the next concrete step.
   - **Drifted, recoverable** — we've wandered, but the original goal is still right. State exactly what to drop, what to resume, and the corrective steps to get back on the main thread.
   - **Goal itself has moved** — what we learned has changed what we *should* be aiming at. State the revised goal and why, and the steps to pursue it.

6. **If you propose a course-correction, make it concrete and stop.** Lay out the specific corrective steps (what to abandon, what to do next, in what order) but do **not** execute them without the user — this skill re-orients and recommends; it doesn't act. The user decides whether to take the correction.

## Format

Lead with the **one-sentence restated goal** and the **verdict** up top — that's the orientation the user wants first. Then the supporting detail (trajectory, what's left, drift evidence) below, kept tight. If proposing a correction, end with a short ordered list of the concrete steps. Follow the user's progressive-disclosure preference: orient briefly first, offer depth rather than dumping it.
