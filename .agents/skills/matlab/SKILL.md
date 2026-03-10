# SKILL — MATLAB

## When to use this skill

Use when the task involves:
- Creating or modifying `.m` files (functions, scripts, or classes).
- Refactoring MATLAB code for performance, readability, or correctness.
- Reviewing MATLAB diffs or PRs.
- Writing MATLAB tests in `test_pr_changes.m` or a new `test_*.m` file.
- Enforcing coding-style rules from `AGENTS.md`.

Do **not** use for documentation-only tasks — use the `doc-writer` skill instead.

---

## Instructions

1. Read `AGENTS.md` and `docs/ARCHITECTURE.md` before making any change.
2. Follow the [MathWorks MATLAB Coding Guidelines](https://mathworks.com/matlabcentral/fileexchange/46056).
3. **Input/output validation** — every function must have a guard block at the
   top and an output check before returning (see `AGENTS.md` for pattern).
4. **Toolbox guard** — wrap toolbox-dependent calls with `check_ml_toolbox` or
   `check_parallel_toolbox`.
5. **Naming** — use explicit, descriptive variable names (`num_base_stations`,
   not `n`).
6. **Revision files** — create a new `_revN.m` file; never rename an existing
   revision.
7. **Tests** — add or update a test in `test_pr_changes.m` for every logic path
   you change.
8. **Performance** — only optimise when a bottleneck is confirmed. Document the
   before/after with a measured speedup or a numerical equivalence check.
9. **No magic numbers** — name constants or explain them in inline comments.
10. **Separate compute / I/O / plotting** — do not mix these in one function.

---

## Hard stops

- Do not add toolbox dependencies without explicit approval.
- Do not rename existing `.m` files.
- Do not commit `.mat` data files unless they are small test fixtures.

---

## Output format

When reporting code changes, provide:
1. The file(s) changed and a one-line summary of the change.
2. The test(s) that validate the change.
3. Any assumptions made about inputs or caller context.
