---
name: readable-prose
description: Write or revise prose so a human can skim it — reader-first structure, old-before-new sentences, signposts kept, no flat wall of claim+number+citation sentences. Use when writing any paragraph a person will read closely (paper sections, reports, PR descriptions, explanations), when revising AI-drafted text, or when the user says a passage is "clunky", "hard to read", "not skimmable", "reads like AI", or invokes /readable-prose. Can also diagnose a passage and name exactly what's wrong.
---

# Readable Prose

AI-drafted text is often correct sentence by sentence but hard to read as a whole. It is written from the writer's side: each sentence is checked for truth, but nobody checks how a reader moves through it. The fix is to **write for a named reader, then revise as that reader**.

Grounding: Gopen & Swan, "The Science of Scientific Writing" (American Scientist, 1990), and Joseph Williams, *Style: Lessons in Clarity and Grace*.

## Modes

- **Write**: draft, then always run the revision pass below before showing anything.
- **Revise**: the user gives a passage. Diagnose it with the checklist, then rewrite.
- **Diagnose**: the user asks *what's wrong*. Name the failures using the vocabulary below, quoting the offending phrase for each. Don't rewrite unless asked.

## Step 1: Name the reader

Before writing, state in one line (to yourself, or in output when revising) who reads this and what they already know. Example: "a reviewer skimming the discussion who hasn't read §4". Every later check is judged against this reader.

## Step 2: Draft with the right structure

- **Point first.** Paragraph order: claim → why (the mechanism) → evidence → contrast/limits → takeaway. Never put numbers before the reader knows why they matter.
- **One job per sentence.** Vary the weight. Some sentences should be short and plain, just there to orient the reader. Not every sentence needs a number and a citation.
- **Actors as subjects, actions as verbs.** "Chaos Seeding erases the differences", not "the attack left every detector with similar evidence".

## Step 3: Revision pass (mandatory, as the named reader)

Go sentence by sentence and fix each failure:

| Failure | Check | Fix |
|---|---|---|
| **Old-before-new** violated | Does the sentence open with something the reader already knows? | Move the familiar thing to the front, new info to the end |
| **Stress position** wasted | Does the sentence end on a citation, hedge, or minor detail? | Move citations mid-sentence; end on the key new point |
| **Evidence before mechanism** | Are numbers given before the reader knows why they matter? | Reorder: why, then numbers |
| **Missing signposts** | Is a contrast, consequence, or restatement unmarked? | Add "so", "by contrast", "that is", "the spread shows it" |
| **Flat hierarchy** | Do 3+ consecutive sentences carry equal weight (claim+number+cite)? | Add a plain orienting sentence; push details into a subordinate clause or parenthesis |
| **Nominalization** | Abstract noun subjects ("the removal of X led to")? | Turn the noun back into a verb with a real actor |
| **Repeated full noun phrases** | Same long phrase twice in a paragraph? | Use shorthand after the first mention ("those differences", "the edge") |
| **Indirect inference** | Does the reader have to make a two-step leap the writer could state ("spread shrank" ⇒ "the strong ones fell")? | State the plain consequence directly |
| **AI tics** | "not X, but Y" / "removed mainly X, not Y", "therefore only as robust as", "It's worth noting" | Rewrite plainly |

**Concise ≠ readable.** Cut words, never connectives. Signposts look like filler but they are what makes skimming possible.

## Step 4: Acceptance tests

- **Skim test:** read only the first sentence of each paragraph. Does that alone tell the story?
- **Cold-read test:** could the named reader follow each number the moment they hit it?
- **Stress test:** read only the last few words of each sentence. Are those the points that matter?

If any test fails, revise again.

## Output (revise/diagnose modes)

Keep it short. List the failures found as one line each (term + quoted phrase), then give the rewrite. No preamble.
