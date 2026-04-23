function [sub_array_ml_turnoff_mc,sub_array_ml_turnoff_mc_secondary]=parfor_randchunk_ml_rev1_mc_same(app,move_sort_file_name,sim_folder,cell_sim_data,sort_full_Pr_dBm,sort_sim_array_list_bs,super_array_bs_eirp_dist,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,cell_sim_chunk_idx,rand_seed1,sort_clutter_loss,custom_antenna_pattern,single_search_dist,tf_man_azi_step,azimuth_step,move_list_reliability,radar_threshold,move_list_margin,parallel_flag)



%%%%%%%%%Similar format to parfor_randchunk_aggcheck_rev9_mc_same

sub_array_ml_turnoff_mc=NaN(1,1); %%%%%%%%%%For each Monte Carlo Iteration, we need the turn off size, across all azimuths
sub_array_ml_turnoff_mc_secondary=NaN(1,1); %%%%%%%%%%For each Monte Carlo Iteration, we need the turn off size, across all azimuths
%%%%%%%%%%%%%%%%%%%%%%%%This is the data we are building towards.
%array_turn_off_size=NaN(mc_size,1);
%secondary_turn_off_size=NaN(mc_size,1);
%%%%%%%%%%%%%%%%%%%%%%%%%We just need the max of both, if there is a secondary I/N threshold
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%Check if the big file is there before
[var_exist1_final_ml]=persistent_var_exist_with_corruption(app,move_sort_file_name);
if var_exist1_final_ml==2
    %%%%%%%%%%%%%%%%%%%%%%%%If the big file exists, and we are trying to clean up the chunks, this doesn't come back  and create more chunks.
    sub_array_ml_turnoff_mc=NaN(1,1);
    sub_array_ml_turnoff_mc_secondary=NaN(1,1);
else


    %%%%%%%%%%%%%%%%%%%%The large file doesn't exist, we need to check for the chunk.
    sub_point_idx=array_rand_chunk_idx(chunk_idx);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%This was the last check point before a stop.[THIS IS the last successful checkpoint.]

    %%%%%%Check/Calculate path loss
    file_name_ml_turnoff_chunk=strcat('sub_',num2str(sub_point_idx),'_array_ml_mc_turnoff_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'_',num2str(single_search_dist),'km.mat');
    [var_exist3_chunk]=persistent_var_exist_with_corruption(app,file_name_ml_turnoff_chunk);

    %%%%%%Check/Calculate path loss
    file_name_ml_turnoff_chunk_second=strcat('sub_',num2str(sub_point_idx),'_array_ml_mc_turnoff_secondary_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'_',num2str(single_search_dist),'km.mat');
    [var_exist4_chunk]=persistent_var_exist_with_corruption(app,file_name_ml_turnoff_chunk_second);

    %%%%%%%%%%%%%%%%%%%%%%%See if we need to calculate the sub-chunk
    if var_exist3_chunk==2 && var_exist4_chunk==2 && parallel_flag==0 %%%%%%%%%%%%%We should only load in the non-parllel
        retry_load=1;
        while(retry_load==1) %%%%%%
            try
                load(file_name_ml_turnoff_chunk,'sub_array_ml_turnoff_mc')
                temp_data=sub_array_ml_turnoff_mc;
                clear sub_array_ml_turnoff_mc;
                sub_array_ml_turnoff_mc=temp_data;
                clear temp_data;

                load(file_name_ml_turnoff_chunk_second,'sub_array_ml_turnoff_mc_secondary')
                temp_data=sub_array_ml_turnoff_mc_secondary;
                clear sub_array_ml_turnoff_mc_secondary;
                sub_array_ml_turnoff_mc_secondary=temp_data;
                clear temp_data;
                retry_load=0;
            catch
                retry_load=1;
                pause(1)  %%%%%%%%%%%Need to catch the error here and display it.
            end
        end
    elseif var_exist3_chunk==2 && parallel_flag==1  %%%%%Parallel, just need a placeholder: No loading
        sub_array_ml_turnoff_mc=NaN(1,1);
        sub_array_ml_turnoff_mc_secondary=NaN(1,1);
    else

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Rev9 is just the max of all azimuths.
        %[sub_array_ml_turnoff_mc]=subchunk_agg_check_maxazi_man_azi_rev10(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx,tf_man_azi_step,azimuth_step);
        [sub_array_ml_turnoff_mc,sub_array_ml_turnoff_mc_secondary]=subchunk_ml_man_azi_rev11(app,sim_folder,sort_sim_array_list_bs,sort_full_Pr_dBm,super_array_bs_eirp_dist,cell_sim_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,cell_sim_chunk_idx,rand_seed1,sort_clutter_loss,custom_antenna_pattern,sub_point_idx,tf_man_azi_step,azimuth_step,move_list_reliability,radar_threshold,move_list_margin);

        % %horzcat(sub_array_ml_turnoff_mc,sub_array_ml_turnoff_mc_secondary)
        % 'sub_array_ml_turnoff_mc'
        % sub_array_ml_turnoff_mc
        % 'sub_array_ml_turnoff_mc_secondary'
        % sub_array_ml_turnoff_mc_secondary
        % 'check'
        % pause;

        %%%%%%Persistent Save
        [var_exist5]=persistent_var_exist_with_corruption(app,file_name_ml_turnoff_chunk); %%%%%%%Check one more time if its there
        [var_exist6_chunk]=persistent_var_exist_with_corruption(app,file_name_ml_turnoff_chunk_second);

        if var_exist5==0 || var_exist6_chunk==0
            retry_save=1;
            while(retry_save==1)
                try
                    save(file_name_ml_turnoff_chunk,'sub_array_ml_turnoff_mc')
                    save(file_name_ml_turnoff_chunk_second,'sub_array_ml_turnoff_mc_secondary')
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(1)
                end
            end
        end
    end
end
%sub_array_agg_check_mc_dBm


%'end of parfor rankdchunk function'