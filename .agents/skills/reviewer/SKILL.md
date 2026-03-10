# SKILL — Reviewer

## When to use this skill

Use when the task involves:
- Reviewing a diff, commit, or pull request for correctness and risk.
- Identifying hidden API changes, edge-case failures, or numerical assumptions.
- Assessing test coverage for changed code.

Do **not** make code changes — report findings only, unless explicitly asked to fix.

---

## Instructions

For every review, check the following in order:

### 1. Correctness
- Does the change produce the right result at the boundaries
  (empty input, single element, zero MC iterations)?
- Are dB/linear conversions consistent?
- Are array dimensions correct after the change?

### 2. Hidden API changes
- Does a renamed variable, function, or output argument break any caller?
- Search for all call sites of any changed function signature.

### 3. Numerical assumptions
- Are units consistent throughout (dBm vs dBW, metres vs km)?
- Are floating-point tolerances appropriate?
- Does the change affect Monte Carlo reproducibility (seed, chunk order)?

### 4. Test coverage
- Is the changed logic path covered by at least one test in `test_pr_changes.m`?
- Are edge cases (empty, NaN, Inf, single-row inputs) tested?

### 5. Complexity and readability
- Is the change simpler or more complex than what it replaces?
- Are variable names explicit and consistent with the surrounding code?
- Are inline comments updated to match new values?

### 6. Scope
- Does the change touch files unrelated to the stated goal?
- Are there opportunistic refactors mixed with functional changes?

---

## Output format

Report findings as a numbered list with severity:
- `[BLOCK]` — must be fixed before merge (correctness, security, data loss).
- `[WARN]` — should be fixed but does not block merge.
- `[NOTE]` — suggestion or observation, no action required.

End the review with a one-line summary verdict:
`APPROVE`, `REQUEST CHANGES`, or `COMMENT`.
