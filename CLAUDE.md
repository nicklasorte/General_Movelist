# CLAUDE.md — General_Movelist

Spectrum sharing / move-list analysis toolbox in MATLAB. Computes interference
aggregation, neighborhood analysis, and Monte Carlo simulations to determine
which base stations must move or reduce EIRP to protect federal incumbents.

---

## Tech Stack

- **Language**: MATLAB (no toolboxes assumed by default; check `check_ml_toolbox.m` and `check_parallel_toolbox.m` at runtime)
- **Parallel**: Parallel Computing Toolbox (parfor), when available
- **Data**: `.mat` files for inputs/outputs; `.xlsx` for final reports

---

## Project Architecture

| Stage | Files | Purpose |
|-------|-------|---------|
| Part 0 | `part0_deployment_pts_folders_*.m` | Deployment point setup |
| Part 2 | `part2_movelist_calculation_*.m`, `part2_neigh_calc_*.m` | Movelist calculation & neighborhood analysis |
| Part 3 | `part3_*.m` | Full aggregate check + mitigation movelist |
| Part 4 | `part4_movelist_miti_EXCEL_rev4.m` | Excel output |

Key utilities:
- `dynamic_mc_chunks_rev1.m` — chunks Monte Carlo iterations to stay under memory limit
- `monte_carlo_*.m` — MC simulation batch runners
- `neighborhood_wrapper_*.m` — neighborhood computation wrappers
- `pre_sort_movelist_*.m` — movelist pre-sorting logic
- `near_opt_sort_idx_*.m` — near-optimal sort index routines

---

## PR Workflow

**IMPORTANT**: Before opening any PR, always run `/simplify` on all changed files first.

```
/simplify all the PR
```

This reviews changed code for reuse, quality, and efficiency issues and fixes them before review.

---

## Development Branch

**IMPORTANT**: Always develop and push to `claude/remove-tf-stop-subchunk-ODzxF`. Never push to main/master without explicit permission.

```bash
git push -u origin claude/remove-tf-stop-subchunk-ODzxF
```

---

## Code Style Rules

- Revision history is encoded in filenames (`_rev1`, `_rev2`, etc.) — do not rename files; create a new revision
- When editing a value, update **both** the value and any matching inline comment
- Do not add toolbox-dependent calls without guarding with `check_ml_toolbox` or `check_parallel_toolbox`
- Prefer `floor`/`ceil` over rounding when computing chunk/index sizes

---

## Common Gotchas

- `dynamic_mc_chunks_rev1.m`: `mem_limit_bytes` controls peak RAM. Changing it affects chunk count and parfor slot grouping downstream. Update comment when changing value.
- Chunk index integrity is verified at runtime (gap/duplicate check); if it fires `pause`, the chunking math is wrong.
- `num_parfor` is capped at 64 — round-robin assignment preserves randomized chunk ordering.
- `array_rand_chunk_idx` is printed to console intentionally (debugging aid); do not remove.

---

## Lessons Learned

### 2026-03-08 — Memory limit reduced in `dynamic_mc_chunks_rev1.m`
- **Change**: `mem_limit_bytes` lowered from `2e9` (2 GB) to `1e9` (1 GB)
- **Effect**: Roughly doubles the number of chunks, halves peak RAM per chunk
- **Rule**: When editing this value always update the comment on line 4–5 too

### 2026-03-08 — CLAUDE.md best practices applied
- Keep file under 200 lines; longer files reduce instruction adherence
- Be specific and verifiable — avoid vague rules like "manage memory well"
- Update this file after every code change with a dated Lessons Learned entry
- Check in to git so the whole team benefits
