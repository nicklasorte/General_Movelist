# Architecture

---

## System overview

General_Movelist is a MATLAB analysis toolbox for spectrum-sharing move-list
computation. It determines which commercial base stations (BS) must move or
reduce EIRP to protect federal incumbent receivers (e.g. radar, DPA zones).

---

## Main directories

```
/                        Root — all MATLAB source files live here (flat layout)
docs/                    Design documents, decisions, TODO, testing notes
.github/                 PR templates and issue templates
.agents/                 Agent skill files (AI assistant instructions)
codex/rules/             Codex execution rules
```

> **No subdirectory structure for MATLAB source files.** All `.m` files are in
> the repo root. This is intentional — MATLAB's `addpath` is not used; callers
> rely on the working directory.

---

## Pipeline stages

| Stage | Entry-point files | Purpose |
|-------|-------------------|---------|
| Part 0 | `part0_deployment_pts_folders_*.m` | Set up deployment points and folder structure |
| Part 2 | `part2_movelist_calculation_*.m`, `part2_neigh_calc_*.m` | Binary-search neighbourhood analysis; produce per-point pre-sort data |
| Part 3 | `part3_*.m` | Full aggregate interference check; compute mitigation move-list |
| Part 4 | `part4_movelist_miti_EXCEL_rev4.m` | Export final move-list to Excel |

---

## Data flow

```
Deployment .mat files
        │
        ▼
Part 0 — point/folder setup
        │
        ▼
Part 2 — neighbourhood binary search
   ├── pre_sort_movelist_rev*.m        (per-point MC pre-sort)
   ├── agg_check_rev*.m                (aggregate interference check)
   ├── dynamic_mc_chunks_rev1.m        (chunk MC iterations)
   └── parfor_randchunk_aggcheck_rev8.m (parallel chunk runner)
        │
        ▼
Part 3 — mitigation move-list
   └── monte_carlo_super_bs_eirp_dist_rev*.m
        │
        ▼
Part 4 — Excel output
```

---

## Key shared utilities

| File | Purpose |
|------|---------|
| `checkout_cell_status_GPT_rev2.m` | Atomic directory-lock for cell status |
| `dynamic_mc_chunks_rev1.m` | Chunk MC iterations to stay under 1 GB RAM limit |
| `disp_progress` | Progress/error display (called throughout) |
| `check_ml_toolbox.m`, `check_parallel_toolbox.m` | Runtime toolbox guards |
| `loadWithRetry.m`, `saveWithRetry.m` | Fault-tolerant file I/O |

---

## Multi-server distribution

`part2_neigh_calc_rev14_multi_server.m` extends rev13 with a 6-phase
file-based claim/poll/collect pipeline that lets multiple uncoordinated
servers share the same `rev_folder` without duplicating work.
See `docs/DECISIONS.md` for the rationale.

---

## Conventions

- **Revision files** — new revision = new file (`_rev1`, `_rev2`, …); never rename.
- **No global state** — all state flows through function arguments or `.mat` files.
- **Toolbox guard** — any toolbox-dependent call must be guarded with
  `check_ml_toolbox` or `check_parallel_toolbox`.
- **Deterministic MC** — set `rng` seed before any random draw; document in comments.

---

## Placeholders to fill in

- [ ] Add the names of the primary DPA / incumbent receiver data files.
- [ ] Document the expected `.mat` workspace variables passed into Part 2.
- [ ] Add a diagram of the network topology if/when available.
