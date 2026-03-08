function [sub_array_agg_check_mc_dBm]=parfor_randchunk_aggcheck_rev8(app,agg_check_file_name,agg_dist_file_name,parfor_idx,parfor_chunk_indices,point_idx,sim_number,data_label1,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,on_list_bs,cell_sim_chuck_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,parallel_flag)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rev8 change: instead of one file per subchunk, one file covers all chunks
% assigned to this parfor slot (parfor_chunk_indices).  File count is
% therefore bounded by num_parfor <= 64 regardless of num_chunks.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sub_array_agg_check_mc_dBm=NaN(1,1);

file_name_agg_check_parfor=strcat('parfor_',num2str(parfor_idx),'_array_agg_check_mc_dBm_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
[var_exist3]=persistent_var_exist_with_corruption(app,file_name_agg_check_parfor);

if var_exist3==2 && parallel_flag==0  %%%%%Load only in non-parallel mode
    retry_load=1;
    while(retry_load==1)
        try
            load(file_name_agg_check_parfor,'sub_array_agg_check_mc_dBm')
            temp_data=sub_array_agg_check_mc_dBm;
            clear sub_array_agg_check_mc_dBm;
            sub_array_agg_check_mc_dBm=temp_data;
            clear temp_data;
            retry_load=0;
        catch
            retry_load=1;
            pause(1)
        end
    end
elseif var_exist3==2 && parallel_flag==1  %%%%%Parallel: placeholder only
    sub_array_agg_check_mc_dBm=NaN(1,1);
else
    %%%%%Compute each chunk assigned to this parfor slot, then combine
    num_group_chunks=length(parfor_chunk_indices);
    group_results=cell(num_group_chunks,1);

    for k=1:num_group_chunks
        sub_point_idx=parfor_chunk_indices(k);
        [group_results{k}]=subchunk_agg_check_rev7(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chuck_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);
    end

    sub_array_agg_check_mc_dBm=vertcat(group_results{:});  %%%%%[total_mc_in_group x num_sim_azi]

    %%%%%Persistent Save
    [var_exist5]=persistent_var_exist_with_corruption(app,file_name_agg_check_parfor);
    if var_exist5==0
        retry_save=1;
        while(retry_save==1)
            try
                save(file_name_agg_check_parfor,'sub_array_agg_check_mc_dBm')
                retry_save=0;
            catch
                retry_save=1;
                pause(1)
            end
        end
    end
end
sub_array_agg_check_mc_dBm
