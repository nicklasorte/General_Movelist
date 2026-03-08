# CLAUDE.md — General_Movelist

This file tracks project context and lessons learned for AI-assisted development sessions.

## Project Overview

MATLAB codebase for spectrum sharing / move-list analysis. Computes interference aggregation, neighborhood analysis, and Monte Carlo simulations to determine which base stations (BS) must move or reduce power (EIRP) to protect federal incumbents.

Key workflows:
- **Part 0** — deployment point setup (`part0_deployment_pts_folders_*.m`)
- **Part 2** — movelist calculation (`part2_movelist_calculation_*.m`, `part2_neigh_calc_*.m`)
- **Part 3** — full aggregate check + mitigation movelist (`part3_*.m`)
- **Part 4** — Excel output (`part4_movelist_miti_EXCEL_rev4.m`)

Core utilities: `dynamic_mc_chunks_rev1.m`, `monte_carlo_*.m`, `neighborhood_wrapper_*.m`, `pre_sort_movelist_*.m`, `near_opt_sort_idx_*.m`

## Development Branch

Active branch: `claude/remove-tf-stop-subchunk-ODzxF`

Always commit and push to this branch. Never push to main/master without explicit permission.

## Lessons Learned

### 2026-03-08 — Memory limit in `dynamic_mc_chunks_rev1.m`
- `mem_limit_bytes` controls how large the working arrays `[num_bs x chunk_size]` can grow across 6 simultaneous double arrays.
- Changed from **2 GB → 1 GB** to reduce per-chunk memory pressure.
- Formula: `chunk_size = floor(mem_limit_bytes / (num_live_arrays * num_bs * bytes_per_double))`
- Halving the limit roughly doubles the number of chunks, which increases chunking overhead but reduces peak RAM usage.
- When editing this value, update **both** `mem_limit_bytes` and the matching comment above it.
