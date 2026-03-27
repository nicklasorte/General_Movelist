function results = validate_subchunk_agg_check_maxazi_rev9_rev10_real( ...
    app, ...
    cell_aas_dist_data, ...
    array_bs_azi_data, ...
    radar_beamwidth, ...
    min_azimuth, ...
    max_azimuth, ...
    base_protection_pts, ...
    point_idx, ...
    on_list_bs, ...
    cell_sim_chunk_idx, ...
    rand_seed1, ...
    agg_check_reliability, ...
    on_full_Pr_dBm, ...
    clutter_loss, ...
    custom_antenna_pattern, ...
    sub_point_idx)
%VALIDATE_SUBCHUNK_AGG_CHECK_MAXAZI_REV9_REV10_REAL
% Real-input regression validator for:
%   - subchunk_agg_check_maxazi_rev9
%   - subchunk_agg_check_maxazi_rev10
%
% Usage:
%   results = validate_subchunk_agg_check_maxazi_rev9_rev10_real( ...
%       app, cell_aas_dist_data, array_bs_azi_data, radar_beamwidth, ...
%       min_azimuth, max_azimuth, base_protection_pts, point_idx, ...
%       on_list_bs, cell_sim_chunk_idx, rand_seed1, agg_check_reliability, ...
%       on_full_Pr_dBm, clutter_loss, custom_antenna_pattern, sub_point_idx)
%
% Behavior:
%   - Runs rev9 and rev10 on identical real inputs.
%   - Checks structural invariants and numeric agreement.
%   - Measures runtime for both versions.
%   - Prints a concise validation summary.
%   - Fails closed with an error when validation fails.

    tol_abs = 1e-10;
    tol_rel = 1e-10;

    rev9_fun = @() subchunk_agg_check_maxazi_rev9( ...
        app, cell_aas_dist_data, array_bs_azi_data, radar_beamwidth, ...
        min_azimuth, max_azimuth, base_protection_pts, point_idx, ...
        on_list_bs, cell_sim_chunk_idx, rand_seed1, agg_check_reliability, ...
        on_full_Pr_dBm, clutter_loss, custom_antenna_pattern, sub_point_idx);

    rev10_fun = @() subchunk_agg_check_maxazi_rev10( ...
        app, cell_aas_dist_data, array_bs_azi_data, radar_beamwidth, ...
        min_azimuth, max_azimuth, base_protection_pts, point_idx, ...
        on_list_bs, cell_sim_chunk_idx, rand_seed1, agg_check_reliability, ...
        on_full_Pr_dBm, clutter_loss, custom_antenna_pattern, sub_point_idx);

    out_rev9 = rev9_fun();
    out_rev10 = rev10_fun();

    size_match = isequal(size(out_rev9), size(out_rev10));
    column_match = iscolumn(out_rev9) && iscolumn(out_rev10);
    nan_pattern_match = isequal(isnan(out_rev9), isnan(out_rev10));
    inf_pattern_match = isequal(isinf(out_rev9), isinf(out_rev10));
    class_match = strcmp(class(out_rev9), class(out_rev10));

    exact_match = isequaln(out_rev9, out_rev10);

    diff_vals = out_rev9 - out_rev10;
    abs_diff = abs(diff_vals);
    denom = max(abs(out_rev9), 1e-12);
    rel_diff = abs_diff ./ denom;

    finite_compare_mask = isfinite(out_rev9) & isfinite(out_rev10);

    if any(finite_compare_mask)
        finite_abs_diff = abs_diff(finite_compare_mask);
        finite_rel_diff = rel_diff(finite_compare_mask);

        [max_abs_diff, worst_abs_linear_idx] = max(finite_abs_diff);
        [max_rel_diff, worst_rel_linear_idx] = max(finite_rel_diff);
        mean_abs_diff = mean(finite_abs_diff);

        finite_linear_indices = find(finite_compare_mask);
        worst_abs_index = finite_linear_indices(worst_abs_linear_idx);
        worst_rel_index = finite_linear_indices(worst_rel_linear_idx);

        tol_mask = (finite_abs_diff <= tol_abs) | (finite_rel_diff <= tol_rel);
        finite_mismatch_count = sum(~tol_mask);
    else
        max_abs_diff = 0;
        max_rel_diff = 0;
        mean_abs_diff = 0;
        worst_abs_index = NaN;
        worst_rel_index = NaN;
        finite_mismatch_count = 0;
    end

    numeric_match = (max_abs_diff <= tol_abs) || (max_rel_diff <= tol_rel);

    runtime_rev9 = timeit(rev9_fun);
    runtime_rev10 = timeit(rev10_fun);

    if runtime_rev10 == 0
        speedup = Inf;
    else
        speedup = runtime_rev9 / runtime_rev10;
    end

    pass = size_match && column_match && nan_pattern_match && inf_pattern_match && class_match && numeric_match;

    results = struct();
    results.size_match = size_match;
    results.column_match = column_match;
    results.nan_pattern_match = nan_pattern_match;
    results.inf_pattern_match = inf_pattern_match;
    results.class_match = class_match;
    results.exact_match = exact_match;
    results.max_abs_diff = max_abs_diff;
    results.max_rel_diff = max_rel_diff;
    results.mean_abs_diff = mean_abs_diff;
    results.worst_abs_index = worst_abs_index;
    results.worst_rel_index = worst_rel_index;
    results.finite_mismatch_count = finite_mismatch_count;
    results.runtime_rev9 = runtime_rev9;
    results.runtime_rev10 = runtime_rev10;
    results.speedup = speedup;
    results.tol_abs = tol_abs;
    results.tol_rel = tol_rel;
    results.numeric_match = numeric_match;
    results.pass = pass;

    fprintf('\n--- VALIDATION SUMMARY ---\n');
    fprintf('Output Size Match:      %d\n', size_match);
    fprintf('Column Vector Match:    %d\n', column_match);
    fprintf('NaN Pattern Match:      %d\n', nan_pattern_match);
    fprintf('Inf Pattern Match:      %d\n', inf_pattern_match);
    fprintf('Class Match:            %d\n', class_match);
    fprintf('Exact Match:            %d\n', exact_match);
    fprintf('Max Abs Diff:           %.16g\n', max_abs_diff);
    fprintf('Max Rel Diff:           %.16g\n', max_rel_diff);
    fprintf('Mean Abs Diff:          %.16g\n', mean_abs_diff);
    fprintf('Worst Abs Index:        %g\n', worst_abs_index);
    fprintf('Worst Rel Index:        %g\n', worst_rel_index);
    fprintf('Finite Mismatch Count:  %d\n', finite_mismatch_count);
    fprintf('Tolerance Abs:          %.1e\n', tol_abs);
    fprintf('Tolerance Rel:          %.1e\n', tol_rel);
    fprintf('Runtime Rev9 (s):       %.6f\n', runtime_rev9);
    fprintf('Runtime Rev10 (s):      %.6f\n', runtime_rev10);
    fprintf('Speedup (Rev9/Rev10):   %.6f\n', speedup);

    if pass
        fprintf('Result: PASS\n');
    else
        fprintf('Result: FAIL\n');
        error('Validation failed: rev10 does not match rev9 within tolerance.');
    end
end
