# Decisions

Lightweight ADR (Architecture Decision Record) log.
Format: date · decision · rationale · alternatives considered · impact.

---

## 2026-03-09 — Multi-server distribution via file-based claim/poll/collect

**Decision**: Replace `parfor point_idx` in Part 2 neighbourhood analysis with
a 6-phase file-based claim/poll/collect pipeline
(`part2_neigh_calc_rev14_multi_server.m`).

**Rationale**: Multiple uncoordinated servers sharing the same `rev_folder` had
no mechanism to distribute binary-search work — each server ran the full `parfor`
loop independently, duplicating computation. A file-system lock (`mkdir`) is
atomic on NFS/SMB shares used in this deployment context and requires no
additional infrastructure.

**Alternatives considered**:
- Centralised job queue (Redis, database) — adds infrastructure dependency.
- Shared memory / MPI — not available in MATLAB App Designer context.
- Single-server with more workers — does not scale across machines.

**Impact**: Rev14 is additive; rev13 still exists and is unmodified. Callers
must opt in by choosing rev14.

---

## 2026-03-09 — `unique(A,'rows')` replaces `table2array(unique(array2table(...)))`

**Decision**: Use native `unique(A,'rows')` throughout.

**Rationale**: The `array2table` / `table2array` round-trip was 5–10× slower
than the native call and produced identical results. The native form is also
more readable.

**Alternatives considered**: None — this is a direct drop-in replacement.

**Impact**: Applied to 21 files. No numerical change.

---

## 2026-03-09 — Antenna pre-computation hoisted outside MC loop

**Decision**: Pre-compute `all_off_axis_gain [num_tx × num_sim_azi]` once
before the Monte Carlo loop in `agg_check_rev6_clutter_app.m` and
`pre_sort_movelist_rev20d_clutter_app.m`.

**Rationale**: The `circshift`/`nearestpoint_app` antenna block was executing
`mc_size × num_sim_azi` times (up to 360 000×) per call. Moving it outside
the loop reduces antenna ops by ~1000×.

**Alternatives considered**: Cache inside loop with a key — more complex and
fragile than a single pre-compute.

**Impact**: ~1000× fewer antenna operations per call. Numerically identical
(verified: max diff = 0).

---

## 2026-03-09 — `griddedInterpolant` replaces per-row `interp1`

**Decision**: Use `griddedInterpolant` (pre-processed knots, then fast
evaluation) instead of calling `interp1` per row in
`monte_carlo_super_bs_eirp_dist_rev3/4.m`.

**Rationale**: `interp1` recomputes spline knots on every call. Calling it
`num_rows` times in a loop is O(n²) in knot setup. `griddedInterpolant` moves
the knot computation outside the loop.

**Alternatives considered**: Vectorised `interp1` — not available for
row-independent interpolation tables.

**Impact**: 2–5× speedup on EIRP distribution sampling for large `num_rows`.
Numerically identical (verified: max diff = 0).

---

## 2026-03-09 — Memory limit set to 1 GB in `dynamic_mc_chunks_rev1.m`

**Decision**: `mem_limit_bytes = 1e9` (1 GB).

**Rationale**: Previous value of 2 GB caused OOM on servers with other
processes co-resident. Halving the limit roughly doubles chunk count and
halves peak RAM per chunk.

**Alternatives considered**: Dynamic detection of free RAM — fragile across
OS/MATLAB versions.

**Impact**: More chunks → marginally more file I/O overhead; acceptable
trade-off for memory safety.

---

*Add new entries at the top of this file.*
