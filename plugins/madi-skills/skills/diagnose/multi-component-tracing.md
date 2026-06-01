# Tracing bugs across component boundaries

Two techniques for when the bug lives in the *seams* between components rather than inside one function. Both belong in Phase 4 (Instrument) — they're how you turn "something downstream is wrong" into "this exact boundary drops/corrupts the value."

## Boundary instrumentation — find *which layer* breaks

When a system has multiple components in series (CI → build → signing; API → service → database; request → middleware → handler → ORM), don't guess which one is at fault. Instrument **every boundary at once**, run the loop a single time, and read off where the value changes from good to bad.

For each component boundary, log:

- what data **enters** the component,
- what data **exits** the component,
- whether config / environment / secrets actually **propagated** across the boundary.

Worked example — a code-signing pipeline where the signing identity goes missing somewhere:

```bash
# Layer 1: CI workflow — is the secret even present here?
echo "=== Layer 1 (workflow): IDENTITY=${IDENTITY:+SET}${IDENTITY:-UNSET}"

# Layer 2: build script — did it survive the shell-out?
echo "=== Layer 2 (build): ===" ; env | grep IDENTITY || echo "IDENTITY not in env"

# Layer 3: signing script — is the keychain in the state we assume?
echo "=== Layer 3 (sign): ===" ; security list-keychains ; security find-identity -v

# Layer 4: the actual operation
codesign --sign "$IDENTITY" --verbose=4 "$APP"
```

The output reads as a relay: `Layer 1 SET → Layer 2 UNSET` tells you the workflow→build boundary is where it dropped, and you stop investigating layers 3 and 4 entirely. One run replaces a morning of bisecting the wrong component.

This composes with the deterministic-loop discipline in Phase 1: the boundary logs go *inside* the feedback loop so every iteration prints the relay. Tag them `[DEBUG-xxxx]` like any other probe so Phase 6 cleanup is a single grep.

## Backward call-stack tracing — find *where the bad value originates*

When the error surfaces deep in the stack (a null far from where the null was created, a wrong number after five transformations), fixing it at the crash site just moves the symptom. Trace **backward to the source**:

1. At the failure point, note the bad value.
2. Ask: what passed this value in? Inspect the caller.
3. Was the value already bad there, or did this frame corrupt it?
4. Repeat up the stack until you reach the frame where a *good* input became a *bad* output. **That** frame is the root cause.
5. Fix at the source, not at the symptom. A guard clause at the crash site is defense-in-depth, not a fix.

The discipline is the same falsifiable-hypothesis loop from Phase 3, applied one stack frame at a time: "if this frame is where it corrupts, the input here is good and the output is bad." Verify at each frame instead of assuming.
