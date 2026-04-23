function [sub_array_agg_check_mc_dBm]=parfor_randchunk_aggcheck_rev9_mc_same(app,agg_check_file_name,agg_dist_file_name,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,parallel_flag,single_search_dist,tf_man_azi_step,azimuth_step)

sub_array_agg_check_mc_dBm=NaN(1,1);

%%%%Check if the big file is there before
[var_exist1]=persistent_var_exist_with_corruption(app,agg_check_file_name);
[var_exist2]=persistent_var_exist_with_corruption(app,agg_dist_file_name);
if var_exist1==2 && var_exist2==2
    %%%%%%%%%%%%%%%%%%%%%%%%If the big file exists, and we are trying to clean up the chunks, this doesn't come back  and create more chunks.
    sub_array_agg_check_mc_dBm=NaN(1,1);
else

    %%%%%%%%%%%%%%%%%%%%The large file doesn't exist, we need to check for the chunk.
    sub_point_idx=array_rand_chunk_idx(chunk_idx);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%This was the last check point before a stop.[THIS IS the last successful checkpoint.]

    %%%%%%Check/Calculate path loss
    file_name_agg_check_chunk=strcat('sub_',num2str(sub_point_idx),'_array_agg_check_mc_dBm_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'_',num2str(single_search_dist),'km.mat');
    [var_exist3_chunk]=persistent_var_exist_with_corruption(app,file_name_agg_check_chunk);

    %%%%%%%%%%%%%%%%%%%%%%%See if we need to calculate the sub-chunk
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

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Rev9 is just the max of all azimuths.
        % 'Rev 9 time:'
        % tic;
        % [sub_array_agg_check_mc_dBm_9]=subchunk_agg_check_maxazi_rev9(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);
        % toc;
        %%%Same as subchunk_agg_check_rev8, just a simple azi max at the end
        %%%%%%Same as subchunk_agg_check_maxazi_rev9, just adding the manual azimuth step with calc_sim_azimuths_rev4_man_azi_app
        [sub_array_agg_check_mc_dBm]=subchunk_agg_check_maxazi_man_azi_rev10(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx,tf_man_azi_step,azimuth_step);

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
%sub_array_agg_check_mc_dBm