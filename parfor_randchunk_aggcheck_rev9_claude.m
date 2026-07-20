function [save_chunk_agg_check_mc_dBm]=parfor_randchunk_aggcheck_rev9_claude(app,agg_check_file_name,agg_dist_file_name,chunk_plan,save_chunk_loop_idx,point_idx,sim_number,data_label1,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,on_list_bs,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,parallel_flag,single_search_dist)
%PARFOR_RANDCHUNK_AGGCHECK_REV9_CLAUDE Grouped-save Monte Carlo wrapper.
%   Rev9 processes one save chunk at a time, where each save chunk contains
%   multiple memory-safe compute subchunks. It writes one MAT file per save
%   chunk (instead of one file per compute subchunk).

save_chunk_agg_check_mc_dBm = NaN(1,1);

[var_exist1]=persistent_var_exist_with_corruption(app,agg_check_file_name);
[var_exist2]=persistent_var_exist_with_corruption(app,agg_dist_file_name);
if var_exist1==2 && var_exist2==2
    % Final files already exist; no further work needed.
    return
end

if ~isstruct(chunk_plan) || ~isfield(chunk_plan,'save_chunk_rand_order')
    error('parfor_randchunk_aggcheck_rev9_claude:InvalidPlan', ...
        'chunk_plan must be a struct created by dynamic_mc_chunks_rev2.');
end

save_chunk_idx = chunk_plan.save_chunk_rand_order(save_chunk_loop_idx);
mc_range = chunk_plan.save_chunk_idx_ranges(save_chunk_idx,:);

file_name_agg_check_chunk = strcat( ...
    'subg_',num2str(save_chunk_idx), ...
    '_array_agg_check_mc_dBm_',num2str(point_idx),'_',num2str(sim_number),'_', ...
    data_label1,'_',num2str(single_search_dist),'km_', ...
    'mc',num2str(mc_range(1)),'_',num2str(mc_range(2)),'.mat');

[var_exist_group]=persistent_var_exist_with_corruption(app,file_name_agg_check_chunk);
if var_exist_group==2 && parallel_flag==0
    retry_load=1;
    while(retry_load==1)
        try
            load(file_name_agg_check_chunk,'save_chunk_agg_check_mc_dBm');
            temp_data=save_chunk_agg_check_mc_dBm;
            clear save_chunk_agg_check_mc_dBm;
            save_chunk_agg_check_mc_dBm=temp_data;
            clear temp_data;
            retry_load=0;
        catch
            retry_load=1;
            pause(1);
        end
    end
    return
elseif var_exist_group==2 && parallel_flag==1
    % In parallel mode, avoid loading if already present.
    return
end

compute_subchunk_idx_list = chunk_plan.save_chunk_to_compute_subchunks{save_chunk_idx};
num_compute_subchunks = length(compute_subchunk_idx_list);
sub_results = cell(num_compute_subchunks,1);

for local_idx = 1:num_compute_subchunks
    compute_subchunk_idx = compute_subchunk_idx_list(local_idx);
    sub_results{local_idx} = subchunk_agg_check_rev8( ...
        app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth, ...
        max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
        chunk_plan.cell_compute_chunk_idx,rand_seed1,agg_check_reliability, ...
        on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,compute_subchunk_idx);
end

save_chunk_agg_check_mc_dBm = vertcat(sub_results{:});
expected_rows = mc_range(2) - mc_range(1) + 1;
if size(save_chunk_agg_check_mc_dBm,1) ~= expected_rows
    error('parfor_randchunk_aggcheck_rev9_claude:SizeMismatch', ...
        'Grouped save chunk rows (%d) != expected MC rows (%d).', ...
        size(save_chunk_agg_check_mc_dBm,1), expected_rows);
end

[var_exist_after_compute]=persistent_var_exist_with_corruption(app,file_name_agg_check_chunk);
if var_exist_after_compute==0
    temp_file_name = strcat(file_name_agg_check_chunk,'.tmp_',num2str(feature('getpid')),'_',num2str(randi(1e9)),'.mat');
    retry_save=1;
    while(retry_save==1)
        try
            save(temp_file_name,'save_chunk_agg_check_mc_dBm','save_chunk_idx','mc_range','compute_subchunk_idx_list','-v7.3');
            movefile(temp_file_name,file_name_agg_check_chunk,'f');
            retry_save=0;
        catch
            retry_save=1;
            if exist(temp_file_name,'file')==2
                delete(temp_file_name);
            end
            pause(1);
        end
    end
end

end
