function [num_chunks,cell_sim_chunk_idx,array_rand_chunk_idx]=dynamic_mc_chunks_rev1(app,mc_size)

% Validate input to avoid creating invalid chunk definitions.
if ~isscalar(mc_size) || ~isfinite(mc_size) || mc_size < 1 || mc_size ~= floor(mc_size)
    error('mc_size must be a positive integer scalar.');
end

dyn_chunks=ceil(mc_size/1000)
if dyn_chunks<24
    num_chunks=24;
elseif dyn_chunks>64
    num_chunks=64;
else
    num_chunks=dyn_chunks;
end

chuck_size=floor(mc_size/num_chunks);
cell_sim_chunk_idx=cell(num_chunks,1);

% for sub_idx=1:1:num_chunks  %%%%%%Define the sim idxs
%     if sub_idx==num_chunks
%         start_idx=(sub_idx-1).*chuck_size+1;
%         stop_idx=mc_size;
%         temp_sim_idx=start_idx:1:stop_idx;
%     else
%         start_idx=(sub_idx-1).*chuck_size+1;
%         stop_idx=sub_idx.*chuck_size;
%         temp_sim_idx=start_idx:1:stop_idx;
%     end
%     cell_sim_chunk_idx{sub_idx}=temp_sim_idx;
% end
for sub_idx=1:num_chunks  %%%%%%Define the sim idxs
    start_idx=(sub_idx-1).*chuck_size+1;
    if sub_idx==num_chunks
        stop_idx=mc_size;
    else
        stop_idx=sub_idx.*chuck_size;
    end
    temp_sim_idx=start_idx:1:stop_idx;
    cell_sim_chunk_idx{sub_idx}=temp_sim_idx;
end

% % % cell_sim_chunk_idx
% % % 'Need to remove empty'
% % % cell_sim_chunk_idx
cell_sim_chunk_idx=cell_sim_chunk_idx(~cellfun('isempty',cell_sim_chunk_idx));
num_chunks=length(cell_sim_chunk_idx);

% % 'check for empty cell_sim_chunk_idx'
% % pause;

% %%%%%Check
% missing_idx=find(diff(horzcat(cell_sim_chunk_idx{:}))>1);
% num_idx=length(unique(horzcat(cell_sim_chunk_idx{:})));
% if ~isempty(missing_idx) || num_idx~=mc_size
%     'Error:Check Chunk IDX'
%     pause;
% end


%%%%%Check
all_idx=horzcat(cell_sim_chunk_idx{:});
missing_idx=find(diff(all_idx)>1);
num_idx=length(unique(all_idx));
if ~isempty(missing_idx) || num_idx~=mc_size
    error('Error:Check Chunk IDX');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Randomize the Point Order for
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%when we have more than 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%server running
[tf_ml_toolbox]=check_ml_toolbox(app);
if tf_ml_toolbox==1
    array_rand_chunk_idx=randsample(num_chunks,num_chunks,false);
else
    array_rand_chunk_idx=randperm(num_chunks);
end
array_rand_chunk_idx


end
