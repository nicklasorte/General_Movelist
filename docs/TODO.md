# TODO

---

## Active work

- [ ] Validate `part2_neigh_calc_rev14_multi_server.m` on a live multi-server run
      and record wall-time vs rev13 single-server baseline.

---

## Next up

- [ ] Run `test_pr_changes.m` against local MATLAB 2025b and record pass/fail counts
      in `docs/TESTING.md`.
- [ ] Merge `claude/remove-tf-stop-subchunk-ODzxF` into `main` (see PR discussion).
- [ ] Review CODEOWNERS placeholders and assign real GitHub usernames.

---

## Blocked

- [ ] Full end-to-end integration test — blocked on access to deployment `.mat` files.

---

## Decisions needed

- [ ] Should `part2_neigh_calc_rev14_multi_server.m` replace rev13, or run in parallel?
      See `docs/DECISIONS.md` entry 2026-03-09.

---

## Done recently

- [x] `unique(A,'rows')` replaces `table2array(unique(array2table(...)))` in 21 files.
- [x] Antenna pre-computation hoisted outside MC loop in `agg_check_rev6` and `pre_sort_movelist_rev20d`.
- [x] `griddedInterpolant` replaces per-row `interp1` in `monte_carlo_super_bs_eirp_dist_rev3/4`.
- [x] Input/output validation added to all 25 touched functions.
- [x] `test_pr_changes.m` added — 39 tests, all pass in Octave 8.4.
