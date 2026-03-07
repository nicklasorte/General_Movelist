function [sub_array_agg_check_mc_dBm,tf_stop_subchunk]=parfor_randchunk_aggcheck_rev7(app,agg_check_file_name,agg_dist_file_name,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,on_list_bs,cell_sim_chuck_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,parallel_flag)


%%%%Check if the big file is there before
[var_exist1]=persistent_var_exist_with_corruption(app,agg_check_file_name);
[var_exist2]=persistent_var_exist_with_corruption(app,agg_dist_file_name);
if var_exist1==2 && var_exist2==2
    tf_stop_subchunk=1;  %'It does exist and we  don't need to load the sub-chunk and need to stop the chunks
    sub_array_agg_check_mc_dBm=NaN(1,1);
else
    tf_stop_subchunk=0;
    sub_array_agg_check_mc_dBm=NaN(1,1);

    %%%%%%%%%%%%%%%%%%%%The large file doesn't exist, we need to check for the chunk.
    sub_point_idx=array_rand_chunk_idx(chunk_idx);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%This was the last check point before a stop.[THIS IS the last successful checkpoint.]

    %%%%%%Check/Calculate path loss
    file_name_agg_check_chunk=strcat('sub_',num2str(sub_point_idx),'_array_agg_check_mc_dBm_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
    [var_exist3_chunk]=persistent_var_exist_with_corruption(app,file_name_agg_check_chunk);


    %%%%%%%Large file doesn't exist, keep going.
    %%%%%%%%%%%%%%%%%%%%%%%Large file does not exist, see if we need to calculate the sub-chunk
    if var_exist3_chunk==2 && parallel_flag==0 %%%%%%%%%%%%%We should only load in the non-parllel
        retry_load=1;
        while(retry_load==1) %%%%%%
            try
                load(file_name_agg_check_chunk,'sub_array_agg_check_mc_dBm')
                temp_data=sub_array_agg_check_mc_dBm;
                clear sub_array_agg_check_mc_dBm;
                sub_array_agg_check_mc_dBm=temp_data;
                clear temp_data;
                retry_load=0;
            catch
                retry_load=1;
                pause(1)  %%%%%%%%%%%Need to catch the error here and display it.
            end
        end
    elseif var_exist3_chunk==2 && parallel_flag==1  %%%%%Parallel, just need a placeholder: No loading
        sub_array_agg_check_mc_dBm=NaN(1,1);
    else
        %%%%%%%%The sub-chunk doesn't exist and we need to calculate it
        %%%'this is where we create a function and feed the inputs'
        [sub_array_agg_check_mc_dBm]=subchunk_agg_check_rev7(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chuck_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);

        sub_array_agg_check_mc_dBm
        %%%%%%Persistent Save
        [var_exist5]=persistent_var_exist_with_corruption(app,file_name_agg_check_chunk); %%%%%%%Check one more time if its there
        if var_exist5==0
            retry_save=1;
            while(retry_save==1)
                try
                    save(file_name_agg_check_chunk,'sub_array_agg_check_mc_dBm')
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(1)
                end
            end
        end
    end
end
sub_array_agg_check_mc_dBm
tf_stop_subchunk