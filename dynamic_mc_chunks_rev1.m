function [num_chunks,cell_sim_chuck_idx,array_rand_chunk_idx,num_parfor,cell_parfor_chunk_idx]=dynamic_mc_chunks_rev1(app,num_bs,num_mc)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Chunk mc iterations so the [num_bs x chunk_size] working arrays in the
% vectorized azimuth loop stay under 1 GB total.
%
% Peak simultaneous double arrays of size [num_bs x chunk_size]:
%   all_Pr_dBm, all_eirp, all_clutter, all_sort_mc_dBm  (batch outputs)
%   sort_temp, mc_watts                                  (azimuth loop temps)
% = 6 arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mem_limit_bytes = 1e9;
num_live_arrays = 6;
bytes_per_double = 8;

chunk_size = floor(mem_limit_bytes / (num_live_arrays * num_bs * bytes_per_double));
chunk_size = max(1, min(chunk_size, num_mc));  %%%%Clamp to [1, num_mc]

num_chunks = max(24, ceil(num_mc / chunk_size));  %%%%Minimum 24 chunks
chunk_size = floor(num_mc / num_chunks);          %%%%Recompute to match enforced num_chunks
cell_sim_chuck_idx = cell(num_chunks,1);

for sub_idx = 1:1:num_chunks
    start_idx = (sub_idx-1)*chunk_size + 1;
    if sub_idx == num_chunks
        stop_idx = num_mc;
    else
        stop_idx = sub_idx*chunk_size;
    end
    cell_sim_chuck_idx{sub_idx} = start_idx:stop_idx;
end

%%%%%Check
missing_idx = find(diff(horzcat(cell_sim_chuck_idx{:})) > 1);
num_idx = length(unique(horzcat(cell_sim_chuck_idx{:})));
if ~isempty(missing_idx) || num_idx ~= num_mc
    disp('Error: Check Chunk IDX')
    pause;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Randomize the chunk order for
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%when we have more than 1 server running
[tf_ml_toolbox] = check_ml_toolbox(app);
if tf_ml_toolbox == 1
    array_rand_chunk_idx = randsample(num_chunks,num_chunks,false);
else
    array_rand_chunk_idx = randperm(num_chunks);
end
array_rand_chunk_idx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Group randomized chunks into <= 64 parfor slots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Round-robin assignment preserves random ordering
num_parfor = min(64, num_chunks);
slots = mod(0:num_chunks-1, num_parfor) + 1;  %%%%[1 x num_chunks] round-robin slot assignment
cell_parfor_chunk_idx = cell(num_parfor, 1);
for s = 1:num_parfor
    cell_parfor_chunk_idx{s} = array_rand_chunk_idx(slots == s);
end

end
