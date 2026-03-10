# AGENTS.md — General_Movelist

This file provides instructions for AI coding agents working in this repository.
Read this file **plus** `docs/ARCHITECTURE.md`, `docs/TODO.md`, and `docs/TESTING.md`
before starting any non-trivial task.

---

## Repository purpose

MATLAB-first engineering and analysis code for spectrum-sharing / move-list
computation. The codebase determines which base stations must move or reduce
EIRP to protect federal incumbents via aggregate interference analysis, Monte
Carlo simulation, and neighbourhood binary-search.

---

## Priorities (in order)

1. **Correctness** — wrong numbers are worse than slow code.
2. **Reproducibility** — identical inputs must produce identical outputs every run.
3. **Readability** — future contributors must understand the logic without running it.
4. **Measured performance** — optimise only when a bottleneck is confirmed.

---

## Before starting work

1. Read `AGENTS.md` (this file).
2. Read `docs/ARCHITECTURE.md` for system structure and data-flow context.
3. Read `docs/TODO.md` for active work items and blocked items.
4. Read `docs/TESTING.md` before adding or changing tests.
5. For major edits, write a brief plan in `docs/TODO.md` under **Active work**
   before touching source files.

---

## Change scope rules

- Make **minimal, scoped changes** that address the stated goal.
- Do **not** perform opportunistic refactors on code you are not asked to change.
- Do **not** rename files — revision history is encoded in filenames (`_rev1`, `_rev2`, …).
  Create a new revision file instead.
- Do **not** add dependencies, toolboxes, CI pipelines, workflow files, or
  release scripts without **explicit written approval** from the repository owner.
- When editing a value, update both the value **and** any matching inline comment.

---

## MATLAB guidelines

Follow the [MathWorks MATLAB Coding Guidelines](https://mathworks.com/matlabcentral/fileexchange/46056).
Key practices for this repo:

- **Explicit names** — `num_base_stations` not `n`; `mc_iter` not `i`.
- **Function boundaries** — separate compute, I/O, and plotting into distinct functions.
- **Deterministic behaviour** — set `rng` seeds before any random draw; document seeds.
- **Input/output validation** — every function must validate inputs at the top
  (`isempty`, `~isnumeric`, `~iscell`, `~isscalar`, `isnan`, size checks) and
  check outputs before returning. On failure: call
  `disp_progress(app, 'ERROR PAUSE: <funcname>: <reason>')` then `pause`.
- **No magic numbers** — name constants or document them with inline comments.
- **`unique(A,'rows')`** not `table2array(unique(array2table(A),'rows'))`.
- **Toolbox guard** — check `check_ml_toolbox` / `check_parallel_toolbox` before
  any call that requires a licensed toolbox.
- **Tests for changed behaviour** — add or update tests in `test_pr_changes.m`
  for every logic path you modify.

---

## Review guidelines

When reviewing a diff or PR, check for:

1. **Correctness** — does the change produce the right numbers at the boundaries?
2. **Edge cases** — empty arrays, single-element arrays, zero MC iterations.
3. **Hidden API changes** — does a renamed variable break a caller elsewhere?
4. **Numerical assumptions** — are units consistent? Are dB/linear conversions correct?
5. **Test coverage** — is the changed logic path exercised by at least one test?
6. **Unnecessary complexity** — prefer simple, readable code over clever one-liners.

---

## Hard stops — do not proceed without human approval

- Committing secrets, credentials, or API keys.
- Rewriting history on shared branches (`git rebase`, `git reset --hard` on pushed commits).
- Broad deletions of source files or test files.
- Bypassing or disabling CI checks.
- Any change to `.github/workflows/` files.

---

## File-naming convention

| Pattern | Meaning |
|---------|---------|
| `*_rev1.m`, `*_rev2.m` | Sequential revisions — create a new file, do not rename |
| `*_GPT_rev*.m` | LLM-generated or LLM-refactored variant |
| `part0_*`, `part2_*`, `part3_*`, `part4_*` | Pipeline stage prefix |
| `test_*.m` | Test scripts (Octave 8.4 / MATLAB 2025b compatible) |
