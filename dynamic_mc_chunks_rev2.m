function [chunk_plan]=dynamic_mc_chunks_rev2(app,mc_size,num_bs,num_sim_azi,worker_memory_mb,target_memory_utilization,max_saved_chunks)
%DYNAMIC_MC_CHUNKS_REV2 Two-level Monte Carlo chunk planner.
%   This revision separates compute chunking (memory safety) from save
%   chunking (file-count control).
%
%   chunk_plan fields (primary):
%     - num_save_chunks
%     - save_chunk_idx_ranges            [num_save_chunks x 2]
%     - save_chunk_to_compute_subchunks  {num_save_chunks x 1}
%     - save_chunk_rand_order            randomized save-chunk order
%     - compute_chunk_size
%     - save_chunk_size_mc
%     - cell_compute_chunk_idx           per-compute-chunk MC indices
%
%   Inputs:
%     mc_size                  total Monte Carlo iterations
%     num_bs                   number of BS rows in hot path
%     num_sim_azi              number of simulated azimuths
%     worker_memory_mb         memory per worker (default 2048)
%     target_memory_utilization fraction of worker memory for chunk working
%                              set (default 0.55)
%     max_saved_chunks         hard cap on grouped save files (default 128)

if nargin < 4
    error('dynamic_mc_chunks_rev2:NotEnoughInputs', ...
        'Need at least app, mc_size, num_bs, num_sim_azi.');
end

if nargin < 5 || isempty(worker_memory_mb)
    worker_memory_mb = 2048;
end
if nargin < 6 || isempty(target_memory_utilization)
    target_memory_utilization = 0.55;
end
if nargin < 7 || isempty(max_saved_chunks)
    max_saved_chunks = 128;
end

worker_memory_mb = max(1, worker_memory_mb);
target_memory_utilization = min(max(target_memory_utilization,0.10),0.90);
max_saved_chunks = max(1, floor(max_saved_chunks));

if mc_size <= 0
    error('dynamic_mc_chunks_rev2:InvalidMcSize','mc_size must be positive.');
end
if num_bs <= 0 || num_sim_azi <= 0
    error('dynamic_mc_chunks_rev2:InvalidDimensions','num_bs and num_sim_azi must be positive.');
end

% Conservative memory model:
%  - per-MC raw arrays include [num_bs x 1] PR/EIRP/clutter and one
%    [num_bs x num_sim_azi] style intermediate footprint.
%  - multiply by a safety factor for MATLAB temporaries / conversion buffers.
bytes_per_double = 8;
raw_bytes_per_mc = double(num_bs) * double(num_sim_azi + 3) * bytes_per_double;
memory_safety_multiplier = 4.0; % conservative practical mid-point (3x to 6x)
estimated_bytes_per_mc = raw_bytes_per_mc * memory_safety_multiplier;

worker_budget_bytes = double(worker_memory_mb) * 1024 * 1024 * target_memory_utilization;
compute_chunk_size = floor(worker_budget_bytes / max(1, estimated_bytes_per_mc));
compute_chunk_size = max(1, min(mc_size, compute_chunk_size));

num_compute_chunks = ceil(mc_size / compute_chunk_size);
cell_compute_chunk_idx = cell(num_compute_chunks,1);
compute_chunk_idx_ranges = zeros(num_compute_chunks,2);

for compute_subchunk_idx = 1:num_compute_chunks
    start_idx = (compute_subchunk_idx-1) * compute_chunk_size + 1;
    stop_idx = min(compute_subchunk_idx * compute_chunk_size, mc_size);
    idx = start_idx:stop_idx;
    cell_compute_chunk_idx{compute_subchunk_idx} = idx;
    compute_chunk_idx_ranges(compute_subchunk_idx,:) = [start_idx, stop_idx];
end

preferred_saved_chunks = min(max_saved_chunks, 128);
num_save_chunks = min(num_compute_chunks, preferred_saved_chunks);
compute_chunks_per_save = ceil(num_compute_chunks / num_save_chunks);

save_chunk_to_compute_subchunks = cell(num_save_chunks,1);
save_chunk_idx_ranges = zeros(num_save_chunks,2);

for save_chunk_idx = 1:num_save_chunks
    comp_start = (save_chunk_idx-1) * compute_chunks_per_save + 1;
    comp_stop = min(save_chunk_idx * compute_chunks_per_save, num_compute_chunks);
    subchunks = comp_start:comp_stop;
    save_chunk_to_compute_subchunks{save_chunk_idx} = subchunks;

    mc_start = compute_chunk_idx_ranges(comp_start,1);
    mc_stop = compute_chunk_idx_ranges(comp_stop,2);
    save_chunk_idx_ranges(save_chunk_idx,:) = [mc_start, mc_stop];
end

save_chunk_size_mc = ceil(mc_size / num_save_chunks);

[tf_ml_toolbox]=check_ml_toolbox(app);
if tf_ml_toolbox==1
    save_chunk_rand_order = randsample(num_save_chunks,num_save_chunks,false);
else
    save_chunk_rand_order = randperm(num_save_chunks);
end

all_compute_idx = horzcat(cell_compute_chunk_idx{:});
if length(all_compute_idx) ~= mc_size || ~isequal(sort(all_compute_idx),1:mc_size)
    error('dynamic_mc_chunks_rev2:CoverageError', ...
        'Compute chunks do not cover MC indices exactly once.');
end

chunk_plan = struct();
chunk_plan.mc_size = mc_size;
chunk_plan.num_bs = num_bs;
chunk_plan.num_sim_azi = num_sim_azi;
chunk_plan.worker_memory_mb = worker_memory_mb;
chunk_plan.target_memory_utilization = target_memory_utilization;
chunk_plan.worker_budget_mb = worker_budget_bytes/(1024*1024);
chunk_plan.max_saved_chunks = max_saved_chunks;
chunk_plan.memory_safety_multiplier = memory_safety_multiplier;
chunk_plan.estimated_bytes_per_mc = estimated_bytes_per_mc;
chunk_plan.estimated_mb_per_mc = estimated_bytes_per_mc/(1024*1024);
chunk_plan.compute_chunk_size = compute_chunk_size;
chunk_plan.num_compute_chunks = num_compute_chunks;
chunk_plan.compute_chunk_idx_ranges = compute_chunk_idx_ranges;
chunk_plan.cell_compute_chunk_idx = cell_compute_chunk_idx;
chunk_plan.num_save_chunks = num_save_chunks;
chunk_plan.save_chunk_size_mc = save_chunk_size_mc;
chunk_plan.compute_chunks_per_save = compute_chunks_per_save;
chunk_plan.save_chunk_idx_ranges = save_chunk_idx_ranges;
chunk_plan.save_chunk_to_compute_subchunks = save_chunk_to_compute_subchunks;
chunk_plan.save_chunk_rand_order = save_chunk_rand_order;

chunk_plan.saved_chunk_cap_respected = (num_save_chunks <= max_saved_chunks);
chunk_plan.saved_chunk_preference_respected = (num_save_chunks <= 128);
end
