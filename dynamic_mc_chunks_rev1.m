function [num_chunks,cell_sim_chuck_idx,array_rand_chunk_idx]=dynamic_mc_chunks_rev1(app,mc_size)

dyn_chunks=ceil(mc_size/1000)
if dyn_chunks<24
    num_chunks=24;
elseif dyn_chunks>64
    num_chunks=64;
else
    num_chunks=dyn_chunks;
end

chuck_size=floor(mc_size/num_chunks);
cell_sim_chuck_idx=cell(num_chunks,1);

for sub_idx=1:1:num_chunks  %%%%%%Define the sim idxs
    if sub_idx==num_chunks
        start_idx=(sub_idx-1).*chuck_size+1;
        stop_idx=mc_size;
        temp_sim_idx=start_idx:1:stop_idx;
    else
        start_idx=(sub_idx-1).*chuck_size+1;
        stop_idx=sub_idx.*chuck_size;
        temp_sim_idx=start_idx:1:stop_idx;
    end
    cell_sim_chuck_idx{sub_idx}=temp_sim_idx;
end
%%%%%Check
missing_idx=find(diff(horzcat(cell_sim_chuck_idx{:}))>1);
num_idx=length(unique(horzcat(cell_sim_chuck_idx{:})));
if ~isempty(missing_idx) || num_idx~=mc_size
    'Error:Check Chunk IDX'
    pause;
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