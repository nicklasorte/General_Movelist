function results = validate_subchunk_agg_check_maxazi_rev10()
%VALIDATE_SUBCHUNK_AGG_CHECK_MAXAZI_REV10 Deterministic regression harness for rev9 vs rev10.
% This harness validates output equivalence, structural invariants, and runtime.
% NOTE: Intermediate checkpoint comparison inside target functions is not added here,
% because exposing internal arrays (e.g., off_axis_gain_matrix and MC terms) would
% require invasive API/debug-surface changes. This harness stays non-invasive.

rng(20260327,'twister'); % fixed harness seed

cases = { ...
    make_case('small',  16,  9,  45,  1, 6), ...
    make_case('medium', 64, 41,  10,  1, 9), ...
    make_case('large',  96, 73,   5,  1, 12) ...
    };

tol = 1e-10;
results = struct('case_name',{},'size_match',{},'column_shape_match',{}, ...
    'nan_pattern_match',{},'inf_pattern_match',{},'max_abs_diff',{}, ...
    'max_rel_diff',{},'runtime_rev9_s',{},'runtime_rev10_s',{},'speedup',{}, ...
    'rev9_reproducible',{},'rev10_reproducible',{},'pass',{});

for k = 1:numel(cases)
    c = cases{k};
    args = c.args;

    out_rev9_a = subchunk_agg_check_maxazi_rev9(args{:});
    out_rev10_a = subchunk_agg_check_maxazi_rev10(args{:});

    % deterministic reproducibility checks
    out_rev9_b = subchunk_agg_check_maxazi_rev9(args{:});
    out_rev10_b = subchunk_agg_check_maxazi_rev10(args{:});

    size_match = isequal(size(out_rev9_a), size(out_rev10_a));
    expected_shape = [numel(c.sub_mc_idx), 1];
    column_shape_match = isequal(size(out_rev9_a), expected_shape) && isequal(size(out_rev10_a), expected_shape);
    nan_pattern_match = isequal(isnan(out_rev9_a), isnan(out_rev10_a));
    inf_pattern_match = isequal(isinf(out_rev9_a), isinf(out_rev10_a));

    denom = max(abs(out_rev9_a), 1e-12);
    abs_diff = abs(out_rev9_a - out_rev10_a);
    rel_diff = abs_diff ./ denom;
    max_abs_diff = max(abs_diff,[],'all');
    max_rel_diff = max(rel_diff,[],'all');

    rev9_reproducible = isequaln(out_rev9_a, out_rev9_b);
    rev10_reproducible = isequaln(out_rev10_a, out_rev10_b);

    % runtime via timeit when available
    runtime_rev9_s = NaN;
    runtime_rev10_s = NaN;
    speedup = NaN;
    if exist('timeit','file') == 2
        runtime_rev9_s = timeit(@() subchunk_agg_check_maxazi_rev9(args{:}));
        runtime_rev10_s = timeit(@() subchunk_agg_check_maxazi_rev10(args{:}));
        speedup = runtime_rev9_s / runtime_rev10_s;
    else
        t = tic; subchunk_agg_check_maxazi_rev9(args{:}); runtime_rev9_s = toc(t);
        t = tic; subchunk_agg_check_maxazi_rev10(args{:}); runtime_rev10_s = toc(t);
        speedup = runtime_rev9_s / runtime_rev10_s;
    end

    pass = size_match && column_shape_match && nan_pattern_match && inf_pattern_match && ...
           rev9_reproducible && rev10_reproducible && ...
           (max_abs_diff <= tol) && (max_rel_diff <= tol);

    fprintf('\n--- VALIDATION SUMMARY ---\n');
    fprintf('Case: %s\n', c.name);
    fprintf('Output Size Match: %d\n', size_match);
    fprintf('Column Shape Match: %d\n', column_shape_match);
    fprintf('NaN Pattern Match: %d\n', nan_pattern_match);
    fprintf('Inf Pattern Match: %d\n', inf_pattern_match);
    fprintf('Rev9 Reproducible: %d\n', rev9_reproducible);
    fprintf('Rev10 Reproducible: %d\n', rev10_reproducible);
    fprintf('Max Abs Diff: %.12g\n', max_abs_diff);
    fprintf('Max Rel Diff: %.12g\n', max_rel_diff);
    fprintf('Tolerance: %.3e\n', tol);
    fprintf('Runtime Rev9: %.6f s\n', runtime_rev9_s);
    fprintf('Runtime Rev10: %.6f s\n', runtime_rev10_s);
    fprintf('Speedup: %.4fx\n', speedup);
    fprintf('Result: %s\n', ternary(pass,'PASS','FAIL'));

    if ~pass
        error('Validation failed: rev10 does not match rev9 within tolerance (case: %s).', c.name);
    end

    results(k).case_name = c.name;
    results(k).size_match = size_match;
    results(k).column_shape_match = column_shape_match;
    results(k).nan_pattern_match = nan_pattern_match;
    results(k).inf_pattern_match = inf_pattern_match;
    results(k).max_abs_diff = max_abs_diff;
    results(k).max_rel_diff = max_rel_diff;
    results(k).runtime_rev9_s = runtime_rev9_s;
    results(k).runtime_rev10_s = runtime_rev10_s;
    results(k).speedup = speedup;
    results(k).rev9_reproducible = rev9_reproducible;
    results(k).rev10_reproducible = rev10_reproducible;
    results(k).pass = pass;
end

end

function c = make_case(name, num_bs, num_mc, radar_beamwidth, point_idx, seed_offset)
% Build deterministic synthetic inputs representative of production dimensions.

rng(1000 + seed_offset,'twister');

app = []; %#ok<NASGU>

% reliability grid and distributions (strictly monotonic reliability).
agg_check_reliability = [0.1 0.5 0.9 0.99];
num_rel = numel(agg_check_reliability);

aas_dist_azimuth = (0:5:355).';
array_aas_dist_data = -30 + 10*rand(numel(aas_dist_azimuth), num_rel);
cell_aas_dist_data = {aas_dist_azimuth, array_aas_dist_data};

array_bs_azi_data = zeros(num_bs, 4);
array_bs_azi_data(:,4) = mod(360*rand(num_bs,1), 360);

min_azimuth = 0;
max_azimuth = 355;

base_protection_pts = [37.2 -76.5; 38.9 -77.0; 34.1 -118.2];
on_list_bs = [ ...
    25 + 20*rand(num_bs,1), ...
   -125 + 55*rand(num_bs,1) ...
];

cell_sim_chunk_idx = {1:num_mc};
rand_seed1 = 12345 + seed_offset;

on_full_Pr_dBm = -140 + 60*rand(num_bs, num_rel);
clutter_loss = 5 + 25*rand(num_bs, num_rel);

pat_az = (0:359).';
pat_gain = -min(abs(pat_az), abs(pat_az-360))/3; % smooth deterministic pattern
custom_antenna_pattern = [pat_az, pat_gain];

sub_point_idx = 1;

args = {[],cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth, ...
    base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability, ...
    on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx};

c = struct();
c.name = name;
c.args = args;
c.sub_mc_idx = cell_sim_chunk_idx{sub_point_idx};
end

function out = ternary(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end