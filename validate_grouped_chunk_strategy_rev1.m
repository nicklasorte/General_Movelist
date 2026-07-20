function report = validate_grouped_chunk_strategy_rev1(app,chunk_plan,varargin)
%VALIDATE_GROUPED_CHUNK_STRATEGY_REV1 Validation checks for rev2 + rev9 design.
%   This helper validates chunk-plan integrity and can optionally run a
%   numerical A/B comparison between direct per-compute assembly and grouped
%   save-chunk assembly using subchunk_agg_check_rev8.
%
%   Required:
%     app, chunk_plan
%
%   Optional name/value:
%     'RunNumericalCheck'    (default false)
%     'NumericalInputs'      struct with fields needed by subchunk_agg_check_rev8
%     'UseRandomSaveOrder'   (default true)

p = inputParser;
p.addParameter('RunNumericalCheck',false,@(x)islogical(x)&&isscalar(x));
p.addParameter('NumericalInputs',struct(),@isstruct);
p.addParameter('UseRandomSaveOrder',true,@(x)islogical(x)&&isscalar(x));
p.parse(varargin{:});
opts = p.Results;

report = struct();

%% 1) Planner coverage, no gaps, no duplicates
all_idx = horzcat(chunk_plan.cell_compute_chunk_idx{:});
report.coverage_exact_once = (numel(all_idx)==chunk_plan.mc_size) && isequal(sort(all_idx),1:chunk_plan.mc_size);
report.no_gaps = isequal(unique(all_idx),1:chunk_plan.mc_size);
report.no_duplicates = (numel(unique(all_idx))==chunk_plan.mc_size);

%% 2) Save chunks nested correctly
nested_ok = true;
save_idx_union = [];
for save_chunk_idx = 1:chunk_plan.num_save_chunks
    subchunks = chunk_plan.save_chunk_to_compute_subchunks{save_chunk_idx};
    from_subchunks = [];
    for k = 1:length(subchunks)
        from_subchunks = [from_subchunks, chunk_plan.cell_compute_chunk_idx{subchunks(k)}]; %#ok<AGROW>
    end
    range_idx = chunk_plan.save_chunk_idx_ranges(save_chunk_idx,1):chunk_plan.save_chunk_idx_ranges(save_chunk_idx,2);
    if ~isequal(from_subchunks,range_idx)
        nested_ok = false;
        break
    end
    save_idx_union = [save_idx_union, range_idx]; %#ok<AGROW>
end
report.save_nested_correct = nested_ok;
report.save_union_exact_once = (numel(save_idx_union)==chunk_plan.mc_size) && isequal(sort(save_idx_union),1:chunk_plan.mc_size);

%% 3) Basic operational summary values
report.num_save_chunks = chunk_plan.num_save_chunks;
report.compute_chunk_size = chunk_plan.compute_chunk_size;
report.worker_budget_mb = chunk_plan.worker_budget_mb;
report.saved_chunk_cap_respected = chunk_plan.saved_chunk_cap_respected;
report.saved_chunk_preference_respected = chunk_plan.saved_chunk_preference_respected;

%% 4) Optional numerical and randomized-order invariance checks
report.size_equal = NaN;
report.max_abs_diff = NaN;
report.nan_pattern_equal = NaN;
report.randomized_order_invariant = NaN;
report.restart_skip_detected = NaN;

if opts.RunNumericalCheck
    req = {'cell_aas_dist_data','array_bs_azi_data','radar_beamwidth','min_azimuth', ...
        'max_azimuth','base_protection_pts','point_idx','on_list_bs','rand_seed1', ...
        'agg_check_reliability','on_full_Pr_dBm','clutter_loss','custom_antenna_pattern'};
    for i = 1:length(req)
        if ~isfield(opts.NumericalInputs,req{i})
            error('validate_grouped_chunk_strategy_rev1:MissingInput', ...
                'Missing NumericalInputs.%s', req{i});
        end
    end

    ni = opts.NumericalInputs;

    % Baseline assembly: compute chunks in numeric order
    baseline_cells = cell(chunk_plan.num_compute_chunks,1);
    for compute_subchunk_idx = 1:chunk_plan.num_compute_chunks
        baseline_cells{compute_subchunk_idx} = subchunk_agg_check_rev8( ...
            app,ni.cell_aas_dist_data,ni.array_bs_azi_data,ni.radar_beamwidth, ...
            ni.min_azimuth,ni.max_azimuth,ni.base_protection_pts,ni.point_idx, ...
            ni.on_list_bs,chunk_plan.cell_compute_chunk_idx,ni.rand_seed1, ...
            ni.agg_check_reliability,ni.on_full_Pr_dBm,ni.clutter_loss, ...
            ni.custom_antenna_pattern,compute_subchunk_idx);
    end
    baseline = vertcat(baseline_cells{:});

    % Grouped assembly: save chunk order can be randomized and should match.
    grouped = NaN(size(baseline));
    if opts.UseRandomSaveOrder
        save_order = chunk_plan.save_chunk_rand_order;
    else
        save_order = 1:chunk_plan.num_save_chunks;
    end

    for t = 1:length(save_order)
        save_chunk_idx = save_order(t);
        compute_subchunks = chunk_plan.save_chunk_to_compute_subchunks{save_chunk_idx};
        local_cells = cell(length(compute_subchunks),1);
        for k = 1:length(compute_subchunks)
            cidx = compute_subchunks(k);
            local_cells{k} = subchunk_agg_check_rev8( ...
                app,ni.cell_aas_dist_data,ni.array_bs_azi_data,ni.radar_beamwidth, ...
                ni.min_azimuth,ni.max_azimuth,ni.base_protection_pts,ni.point_idx, ...
                ni.on_list_bs,chunk_plan.cell_compute_chunk_idx,ni.rand_seed1, ...
                ni.agg_check_reliability,ni.on_full_Pr_dBm,ni.clutter_loss, ...
                ni.custom_antenna_pattern,cidx);
        end
        grouped_chunk = vertcat(local_cells{:});
        rng_idx = chunk_plan.save_chunk_idx_ranges(save_chunk_idx,1):chunk_plan.save_chunk_idx_ranges(save_chunk_idx,2);
        grouped(rng_idx,:) = grouped_chunk;
    end

    report.size_equal = isequal(size(baseline),size(grouped));
    report.nan_pattern_equal = isequal(isnan(baseline),isnan(grouped));

    valid_mask = ~isnan(baseline) & ~isnan(grouped);
    if any(valid_mask,'all')
        report.max_abs_diff = max(abs(baseline(valid_mask)-grouped(valid_mask)),[],'all');
    else
        report.max_abs_diff = NaN;
    end

    % Compare randomized order vs deterministic order reconstruction.
    grouped_det = NaN(size(baseline));
    for save_chunk_idx = 1:chunk_plan.num_save_chunks
        compute_subchunks = chunk_plan.save_chunk_to_compute_subchunks{save_chunk_idx};
        local_cells = cell(length(compute_subchunks),1);
        for k = 1:length(compute_subchunks)
            cidx = compute_subchunks(k);
            local_cells{k} = subchunk_agg_check_rev8( ...
                app,ni.cell_aas_dist_data,ni.array_bs_azi_data,ni.radar_beamwidth, ...
                ni.min_azimuth,ni.max_azimuth,ni.base_protection_pts,ni.point_idx, ...
                ni.on_list_bs,chunk_plan.cell_compute_chunk_idx,ni.rand_seed1, ...
                ni.agg_check_reliability,ni.on_full_Pr_dBm,ni.clutter_loss, ...
                ni.custom_antenna_pattern,cidx);
        end
        grouped_det(chunk_plan.save_chunk_idx_ranges(save_chunk_idx,1):chunk_plan.save_chunk_idx_ranges(save_chunk_idx,2),:) = vertcat(local_cells{:});
    end
    report.randomized_order_invariant = isequaln(grouped,grouped_det);

    % Restart skip behavior check (exists -> skip).
    tmp_dir = tempname;
    mkdir(tmp_dir);
    orig_dir = pwd;
    cleanup_obj = onCleanup(@() cd(orig_dir)); %#ok<NASGU>
    cd(tmp_dir);

    agg_check_file_name = "final_dummy_agg_check.mat";
    agg_dist_file_name = "final_dummy_agg_dist.mat";
    save(agg_check_file_name,'grouped');
    save(agg_dist_file_name,'grouped_det');

    out = parfor_randchunk_aggcheck_rev9_claude(app,agg_check_file_name,agg_dist_file_name,chunk_plan,1, ...
        ni.point_idx,1,'validation',ni.cell_aas_dist_data,ni.array_bs_azi_data, ...
        ni.radar_beamwidth,ni.min_azimuth,ni.max_azimuth,ni.base_protection_pts, ...
        ni.on_list_bs,ni.rand_seed1,ni.agg_check_reliability,ni.on_full_Pr_dBm, ...
        ni.clutter_loss,ni.custom_antenna_pattern,0,1);

    report.restart_skip_detected = isequaln(out,NaN(1,1));
end
end
