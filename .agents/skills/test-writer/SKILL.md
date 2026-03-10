# SKILL — Test writer

## When to use this skill

Use when the task involves:
- Adding regression tests for a bug fix.
- Adding tests for a new or changed function.
- Expanding edge-case coverage in `test_pr_changes.m`.

Do **not** use for documentation updates — use the `doc-writer` skill instead.

---

## Instructions

1. Read `docs/TESTING.md` before writing any test.
2. All tests go into `test_pr_changes.m` (or a new `test_*.m` file for a large
   independent module).
3. **Compatibility** — tests must run in both Octave 8.4 and MATLAB 2025b.
   - MATLAB-only APIs (`griddedInterpolant`, `db2pow`, `pow2db`) must have
     numerically equivalent Octave proxies with inline notes.
4. **Assertion messages** — every `assert` call must have a descriptive string:
   ```matlab
   assert(result == expected, 'test_name: description of what failed');
   ```
5. **Edge cases to always include**:
   - Empty input `[]`
   - Single-element input
   - Input containing `NaN` or `Inf`
   - Minimum and maximum valid values
6. **No production side-effects** — use `tempdir` for any required file I/O;
   never write to `rev_folder` or any production data directory.
7. **Numerical tolerance** — use `abs(a - b) < tol` with an explicit `tol`
   (e.g. `1e-10`) for floating-point comparisons; never use `==` on doubles.
8. **Test groups** — prefix related tests with a shared group name in the
   assertion message for easy filtering in output.

---

## Output format

When adding tests, report:
1. The test group name and number of new test cases added.
2. The functions or logic paths covered.
3. Any MATLAB-only tests and their Octave proxy strategy.
4. The result of running `test_pr_changes.m` after your additions.
