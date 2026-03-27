function results=benchmark_subchunk_agg_check_maxazi_rev11_chunk_sweep(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx,varargin)
%BENCHMARK_SUBCHUNK_AGG_CHECK_MAXAZI_REV11_CHUNK_SWEEP
% Runtime sweep for rev11 AZI_CHUNK tuning.
%
% Optional name/value:
%   'ChunkValues' (default [64 128 256 512])
%   'NumTrials'   (default 3)

opts=parse_inputs(varargin{:});

if exist('subchunk_agg_check_maxazi_rev11','file')~=2
    error('benchmark_subchunk_agg_check_maxazi_rev11_chunk_sweep:MissingRev11', ...
        'subchunk_agg_check_maxazi_rev11.m was not found on MATLAB path.');
end

chunk_values=opts.ChunkValues(:).';
num_chunks=numel(chunk_values);
runtime_trials=NaN(num_chunks,opts.NumTrials);

fprintf('\n=== rev11 AZI_CHUNK sweep benchmark ===\n');
fprintf('Chunk values: %s\n',mat2str(chunk_values));
fprintf('Trials per chunk: %d\n',opts.NumTrials);

for c=1:1:num_chunks
    azi_chunk=chunk_values(c);
    for t=1:1:opts.NumTrials
        run_tic=tic;
        subchunk_agg_check_maxazi_rev11(app,cell_aas_dist_data,array_bs_azi_data, ...
            radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
            cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
            custom_antenna_pattern,sub_point_idx,azi_chunk);
        runtime_trials(c,t)=toc(run_tic);
    end
end

runtime_median=median(runtime_trials,2,'omitnan');
runtime_mean=mean(runtime_trials,2,'omitnan');
runtime_min=min(runtime_trials,[],2,'omitnan');

[best_runtime,best_idx]=min(runtime_median);
best_chunk=chunk_values(best_idx);

fprintf('\nSummary table (seconds):\n');
fprintf('  AZI_CHUNK |   median |     mean |      min\n');
for c=1:1:num_chunks
    fprintf('  %9d | %8.4f | %8.4f | %8.4f\n',chunk_values(c),runtime_median(c),runtime_mean(c),runtime_min(c));
end
fprintf('\nRecommended AZI_CHUNK: %d (median runtime %.4f s)\n',best_chunk,best_runtime);

results=struct();
results.chunk_values=chunk_values;
results.runtime_trials_s=runtime_trials;
results.runtime_median_s=runtime_median;
results.runtime_mean_s=runtime_mean;
results.runtime_min_s=runtime_min;
results.best_chunk=best_chunk;
results.best_runtime_median_s=best_runtime;

end

function opts=parse_inputs(varargin)
opts=struct();
opts.ChunkValues=[64 128 256 512];
opts.NumTrials=3;

if mod(numel(varargin),2)~=0
    error('Optional arguments must be name/value pairs.');
end

for i=1:2:numel(varargin)
    name=varargin{i};
    value=varargin{i+1};
    switch lower(string(name))
        case "chunkvalues"
            opts.ChunkValues=unique(max(1,round(value(:).')),'stable');
        case "numtrials"
            opts.NumTrials=max(1,round(value));
        otherwise
            error('Unknown option: %s',name);
    end
end
end
