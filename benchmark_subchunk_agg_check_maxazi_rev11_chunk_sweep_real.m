function results = benchmark_subchunk_agg_check_maxazi_rev11_chunk_sweep_real( ...
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
%BENCHMARK_SUBCHUNK_AGG_CHECK_MAXAZI_REV11_CHUNK_SWEEP_REAL
% Benchmark rev11 with real inputs over a sweep of AZI_CHUNK values.

if exist('subchunk_agg_check_maxazi_rev11','file')~=2
    error('benchmark_subchunk_agg_check_maxazi_rev11_chunk_sweep_real:MissingRev11', ...
        'subchunk_agg_check_maxazi_rev11.m was not found on MATLAB path.');
end

% Required set plus optional boundary values when practical.
chunk_sizes = [32 64 128 256 512 1024];
runtimes = NaN(size(chunk_sizes));

fprintf('\n=== REV11 CHUNK SWEEP (REAL INPUTS) ===\n');

for idx = 1:numel(chunk_sizes)
    azi_chunk = chunk_sizes(idx);

    f = @() subchunk_agg_check_maxazi_rev11(app,cell_aas_dist_data,array_bs_azi_data, ...
        radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
        cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
        custom_antenna_pattern,sub_point_idx,azi_chunk);

    try
        if exist('timeit','file')==2
            runtimes(idx) = timeit(f);
        else
            t0 = tic;
            f();
            runtimes(idx) = toc(t0);
        end
    catch chunkErr
        runtimes(idx) = NaN;
        warning('benchmark_subchunk_agg_check_maxazi_rev11_chunk_sweep_real:ChunkFailed', ...
            'Chunk size %d failed (%s). Continuing with remaining chunk sizes.', ...
            azi_chunk, chunkErr.message);
    end
end

valid_mask = isfinite(runtimes);
if ~any(valid_mask)
    error('benchmark_subchunk_agg_check_maxazi_rev11_chunk_sweep_real:NoValidRuns', ...
        'No successful runtime measurements were produced.');
end

valid_chunks = chunk_sizes(valid_mask);
valid_runtimes = runtimes(valid_mask);
[best_runtime,best_idx] = min(valid_runtimes);
best_chunk = valid_chunks(best_idx);

fprintf('Chunk    Runtime (s)    Relative to Best\n');
for idx = 1:numel(chunk_sizes)
    if isfinite(runtimes(idx))
        rel = runtimes(idx) ./ best_runtime;
        fprintf('%5d    %10.6f      %8.3fx\n',chunk_sizes(idx),runtimes(idx),rel);
    else
        fprintf('%5d    %10s      %8s\n',chunk_sizes(idx),'FAILED','-');
    end
end

fprintf('Best chunk: %d\n',best_chunk);
fprintf('Best runtime: %.6f s\n',best_runtime);

results = struct();
results.chunk_sizes = chunk_sizes;
results.runtimes = runtimes;
results.best_chunk = best_chunk;
results.best_runtime = best_runtime;

idx_128 = find(chunk_sizes==128,1,'first');
if ~isempty(idx_128) && isfinite(runtimes(idx_128))
    results.speedup_vs_128 = runtimes(idx_128) ./ best_runtime;
    fprintf('Speedup vs chunk 128: %.3fx\n',results.speedup_vs_128);
else
    results.speedup_vs_128 = NaN;
    fprintf('Speedup vs chunk 128: N/A\n');
end

fprintf('Recommended chunk size for rev12 default: %d\n',best_chunk);

end
