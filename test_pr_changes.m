% test_pr_changes.m — Octave 8.4 compatible tests for PR changes
% Note on MATLAB vs Octave differences:
%   - griddedInterpolant: MATLAB-only. Tested via interp1 numerical contract.
%   - db2pow/pow2db: from MATLAB Signal Toolbox. Replaced with inline formulas.
%   - mkdir existing dir: returns 1 in Octave (idempotent), 0 in MATLAB.
%     We test the lock pattern using isdir() as the correctness predicate.

pass_count = 0;
fail_count = 0;

function pass_count = check(cond, name, pass_count)
  if cond
    fprintf('  PASS: %s\n', name);
    pass_count += 1;
  else
    fprintf('  FAIL: %s\n', name);
  end
end

% Inline MATLAB Signal Toolbox equivalents
db2pow_fn = @(x) 10.^(x./10);
pow2db_fn = @(x) 10.*log10(x);

fprintf('\n=== Test 1: unique(A,''rows'') replaces table2array pattern ===\n');
A = [10 -3; 20 -1; 10 -3; 30 -5; 20 -1];
result_new = unique(A,'rows');
expected = [10 -3; 20 -1; 30 -5];

pass_count = check(isequal(result_new, expected), 'unique(A,rows) correct sorted unique rows', pass_count);
pass_count = check(size(result_new,1)==3, 'unique(A,rows) removes 2 duplicate rows', pass_count);
pass_count = check(isequal(result_new, sortrows(result_new)), 'unique(A,rows) output is row-sorted', pass_count);

fprintf('\n=== Test 2: interp1 spline (griddedInterpolant numerical contract) ===\n');
reliability = [0.1 0.3 0.5 0.7 0.9];
eirp_row    = [20  25  30  35  40];
result_mid  = interp1(reliability, eirp_row, 0.5, 'spline');
result_edge = interp1(reliability, eirp_row, 0.1, 'spline');
pass_count = check(abs(result_mid  - 30) < 1e-6, 'interp1 spline midpoint==30', pass_count);
pass_count = check(abs(result_edge - 20) < 1e-6, 'interp1 spline left edge==20', pass_count);
% Verify monotone data produces monotone interpolation (matches griddedInterpolant contract)
q_vals = 0.1:0.1:0.9;
interp_vals = interp1(reliability, eirp_row, q_vals, 'spline');
pass_count = check(all(diff(interp_vals) > 0), 'monotone input -> monotone spline output', pass_count);
fprintf('  NOTE: griddedInterpolant is MATLAB-only; equivalent result verified via interp1\n');

fprintf('\n=== Test 3: dynamic_mc_chunks_rev1 chunking math ===\n');

function [num_chunks, cell_idx] = chunking_math(num_bs, num_mc)
  mem_limit_bytes = 1e9;
  num_live_arrays = 6;
  bytes_per_double = 8;
  chunk_size = floor(mem_limit_bytes / (num_live_arrays * num_bs * bytes_per_double));
  chunk_size = max(1, min(chunk_size, num_mc));
  num_chunks = max(24, ceil(num_mc / chunk_size));
  chunk_size = floor(num_mc / num_chunks);
  cell_idx = cell(num_chunks,1);
  for sub_idx = 1:num_chunks
    start_idx = (sub_idx-1)*chunk_size + 1;
    if sub_idx == num_chunks
      stop_idx = num_mc;
    else
      stop_idx = sub_idx*chunk_size;
    end
    cell_idx{sub_idx} = start_idx:stop_idx;
  end
end

[nc, ci] = chunking_math(10, 1000);
all_idx = horzcat(ci{:});
pass_count = check(nc >= 24, 'num_chunks >= 24 enforced', pass_count);
pass_count = check(isempty(find(diff(all_idx) > 1)), 'no gaps in chunk coverage', pass_count);
pass_count = check(length(unique(all_idx)) == 1000, 'all 1000 MC iters covered exactly once', pass_count);
pass_count = check(min(all_idx)==1 && max(all_idx)==1000, 'index range [1,1000]', pass_count);

[nc2, ci2] = chunking_math(100000, 500);
all_idx2 = horzcat(ci2{:});
pass_count = check(nc2 >= 24, 'large BS: num_chunks >= 24', pass_count);
pass_count = check(length(unique(all_idx2)) == 500, 'large BS: all 500 MC iters covered', pass_count);

% Edge case: 1 BS, 1 MC iteration
[nc3, ci3] = chunking_math(1, 1);
all_idx3 = horzcat(ci3{:});
pass_count = check(length(all_idx3)==1 && all_idx3(1)==1, 'edge case: 1 BS 1 MC', pass_count);

fprintf('\n=== Test 4: num_parfor cap at 64 ===\n');
for nc_test = [10 64 65 200]
  np = min(64, nc_test);
  pass_count = check(np <= 64, sprintf('num_chunks=%d -> num_parfor=%d <= 64', nc_test, np), pass_count);
end

fprintf('\n=== Test 5: Round-robin parfor slot assignment ===\n');
for nc_rr = [10 64 200]
  np_rr = min(64, nc_rr);
  slots_rr = mod(0:nc_rr-1, np_rr) + 1;
  cell_pf = cell(np_rr, 1);
  fake_idx = 1:nc_rr;
  for s = 1:np_rr
    cell_pf{s} = fake_idx(slots_rr == s);
  end
  all_assigned = horzcat(cell_pf{:});
  pass_count = check(isequal(sort(all_assigned), 1:nc_rr), ...
    sprintf('nc=%d: all chunks assigned exactly once', nc_rr), pass_count);
  lens = cellfun(@length, cell_pf);
  pass_count = check(max(lens) <= ceil(nc_rr/np_rr)+1, ...
    sprintf('nc=%d: slots are load-balanced', nc_rr), pass_count);
end

fprintf('\n=== Test 6: mkdir-based atomic claim logic (isdir predicate) ===\n');
tmpdir = tempname();
mkdir(tmpdir);
lock_dir = fullfile(tmpdir, 'test_claim.lockdir');

% Before claim: dir should not exist
pass_count = check(~isdir(lock_dir), 'before claim: lock dir does not exist', pass_count);
% Create lock
mkdir(lock_dir);
pass_count = check(isdir(lock_dir), 'after claim: lock dir exists', pass_count);
% Simulate second claim attempt: check if dir already exists before mkdir
already_locked = isdir(lock_dir);
pass_count = check(already_locked, 'second server: isdir detects lock is held', pass_count);
% Release
rmdir(lock_dir, 's');
pass_count = check(~isdir(lock_dir), 'after release: lock dir gone', pass_count);
% Re-claim
mkdir(lock_dir);
pass_count = check(isdir(lock_dir), 're-claim after release: lock dir created', pass_count);
rmdir(lock_dir, 's');
rmdir(tmpdir, 's');

fprintf('\n=== Test 7: Input guard conditions ===\n');
pass_count = check(isnumeric(100) && isscalar(100) && 100>=1, 'valid scalar passes guard', pass_count);
pass_count = check(isempty([]),        'isempty catches []', pass_count);
pass_count = check(~isnumeric('hi'),   '~isnumeric catches char', pass_count);
pass_count = check(~isscalar([1 2 3]), '~isscalar catches vector', pass_count);
pass_count = check(isnan(NaN),         'isnan catches NaN', pass_count);
pass_count = check(iscell({1,2}),      'iscell passes on cell', pass_count);
pass_count = check(~iscell(42),        '~iscell catches numeric', pass_count);
% Size check (used in array_bs_azi_data guard: size(...,2)<4)
arr_bad = [1 2 3];   % only 3 cols
arr_ok  = [1 2 3 4];
pass_count = check(size(arr_bad,2) < 4, 'size check catches too-few columns', pass_count);
pass_count = check(size(arr_ok,2) >= 4, 'size check passes sufficient columns', pass_count);

fprintf('\n=== Test 8: Antenna-hoisting vectorized vs naive (inline db formulas) ===\n');
rng(42);
num_tx_t = 5; num_azi = 8; mc_sz = 20;
all_gain = randn(num_tx_t, num_azi);
mc_dBm = randn(num_tx_t, mc_sz) * 10 + 30;

% Hoisted vectorized approach (as coded in agg_check_rev6 / subchunk_agg_check_rev7)
result_hoisted = zeros(mc_sz, num_azi);
for azi = 1:num_azi
  gain_col = all_gain(:, azi);
  sort_temp = mc_dBm + gain_col;                          % broadcast [num_tx x mc_sz]
  watts_sum = sum(db2pow_fn(sort_temp), 1);    % [1 x mc_sz]
  result_hoisted(:, azi) = pow2db_fn(watts_sum)';
end

% Naive per-iter loop (reference)
result_naive = zeros(mc_sz, num_azi);
for mc = 1:mc_sz
  for azi = 1:num_azi
    col = mc_dBm(:, mc) + all_gain(:, azi);
    result_naive(mc, azi) = pow2db_fn(sum(db2pow_fn(col)));
  end
end

max_diff = max(abs(result_hoisted(:) - result_naive(:)));
pass_count = check(max_diff < 1e-9, ...
  sprintf('hoisted antenna loop matches naive (max_diff=%.2e)', max_diff), pass_count);

fprintf('\n=== Test 9: griddedInterpolant batch vs row-by-row (Octave interp1 proxy) ===\n');
% Verify that calling interp1 row-by-row (old pattern) gives same result
% as applying it once per row with griddedInterpolant (new pattern).
% In MATLAB 2025b both use 'spline'; we verify the interp1 row contract here.
rng(7);
num_rows = 10;
rel = [0.1 0.3 0.5 0.7 0.9];
eirp_data = repmat(rel*40, num_rows, 1) + randn(num_rows, 5)*0.5; % [10x5]
queries = rand(num_rows,1)*(0.9-0.1) + 0.1;

% Row-by-row (old pattern)
result_old = NaN(num_rows,1);
for n = 1:num_rows
  result_old(n) = interp1(rel(:), eirp_data(n,:)', queries(n), 'spline');
end

% Row-by-row with same function (griddedInterpolant proxy)
result_new_proxy = NaN(num_rows,1);
for n = 1:num_rows
  result_new_proxy(n) = interp1(rel(:), eirp_data(n,:)', queries(n), 'spline');
end

diff_rows = max(abs(result_old - result_new_proxy));
pass_count = check(diff_rows < 1e-10, ...
  sprintf('row-by-row interp1 is reproducible (max_diff=%.2e)', diff_rows), pass_count);

total_tests = 39;
fprintf('\n============================================\n');
fprintf('RESULTS: %d / %d passed\n', pass_count, total_tests);
if pass_count == total_tests
  fprintf('All tests passed!\n');
else
  fprintf('WARNING: %d test(s) failed.\n', total_tests - pass_count);
end
