# Testing

---

## How to run tests

The primary test file is `test_pr_changes.m` in the repo root.
It is compatible with **Octave 8.4** and **MATLAB 2025b**.

```matlab
% From the repo root in MATLAB or Octave:
test_pr_changes
```

A passing run prints `PASS` for each of the 39 test cases and exits without
errors. Any failure prints a descriptive message and the test counter at which
it failed.

---

## When to add or update tests

- **Changed logic path** — add at least one test that exercises the new path.
- **Bug fix** — add a regression test that would have caught the bug before
  the fix.
- **Performance change** — add a numerical equivalence test showing that the
  optimised path produces values identical (or within floating-point tolerance)
  to the original.
- **New function** — add tests for the happy path, one edge case
  (empty / single-element input), and one error/validation case.

---

## Test structure conventions

- All tests live in `test_pr_changes.m` (or a new `test_*.m` file for large
  independent modules).
- Use descriptive assertion messages: `assert(result == expected, 'description of what failed')`.
- Do **not** use `error` or `try/catch` to suppress failures — let them surface.
- Tests must not write to `rev_folder` or any production data directory.
  Use `tempdir` for any required file I/O.
- MATLAB-only APIs (`griddedInterpolant`, `db2pow`, `pow2db`) must have an
  Octave-compatible numerical proxy with an inline note documenting the MATLAB
  equivalent.

---

## Test groups in `test_pr_changes.m`

| Group | Tests | What is validated |
|-------|-------|-------------------|
| `unique(A,'rows')` | 2 | Correct sorted deduplication of antenna-pattern rows |
| `interp1` spline contract | 3 | Midpoint, edge, monotonicity |
| Chunking math | 6 | No gaps, full coverage, correct range, edge cases, large BS count |
| `num_parfor` cap | 4 | Capped at 64 for 10/64/65/200 chunk counts |
| Round-robin slot assignment | 3 | All chunks assigned exactly once, load-balanced |
| `mkdir` atomic claim/release | 3 | Lock creation, double-claim detection, release and re-claim |
| Input guard conditions | 6 | `isempty`, `~isnumeric`, `~isscalar`, `isnan`, `iscell`, size checks |
| Antenna-hoisting vectorized vs naive | 3 | Max numerical difference = 0 |
| Row-by-row interpolation reproducibility | 3 | Max diff = 0 |

---

## Validation evidence

Record test results here after each significant change.

| Date | Runner | MATLAB/Octave version | Tests passed | Notes |
|------|--------|-----------------------|--------------|-------|
| 2026-03-09 | CI (Octave) | Octave 8.4 | 39 / 39 | Baseline for PR |
| <!-- PLACEHOLDER --> | Local | MATLAB 2025b | — | Run and fill in |

---

## Placeholder: MATLAB-specific testing

The following items require MATLAB 2025b and cannot be verified in Octave:

- `griddedInterpolant` knot pre-computation and evaluation.
- `db2pow` / `pow2db` conversions.
- Parallel Computing Toolbox (`parfor`) chunk assignment under a real worker pool.

> **TODO**: Run `test_pr_changes.m` on the local MATLAB 2025b installation,
> record the output, and add the result to the table above.
