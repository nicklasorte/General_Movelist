function [move_sort_sim_array_list_bs]=parfor_chunk_movelist_dual_man_azi_rev30_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,tf_opt,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,move_list_margin,tf_full_turnoff,cell_sim_data,sim_folder,tf_man_azi_step,azimuth_step,parallel_flag,tf_server_status)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Move List Function with Neighborhoor Cut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp_progress(app,strcat('Line 7: parfor_chunk_movelist_dual_man_azi_rev30_app'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check for Move List File, if none, save place holder
move_sort_file_name=strcat(string_prop_model,'_move_sort_sim_array_list_bs_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
[var_exist_move_sort]=persistent_var_exist_with_corruption(app,move_sort_file_name);

if var_exist_move_sort==2
    %%%%%%%%%%%load
    [move_sort_sim_array_list_bs]=persistent_load_var_rev1(app,move_sort_file_name,'move_sort_sim_array_list_bs');
else
    disp_progress(app,strcat('Line 28: parfor_chunk_movelist_dual_man_azi_rev30_app'))
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%This is where we define the num_chunks
    [num_chunks,cell_sim_chunk_idx,array_rand_chunk_idx]=dynamic_mc_chunks_rev1(app,mc_size);

    if tf_full_turnoff==1
        disp_progress(app,strcat('Line 36: parfor_chunk_movelist_dual_man_azi_rev30_app'))
        %%%%%%%%%If we're turning off the full circle, no need to do all the calculations.
        [keep_idx,bs_distance]=cut_bs_by_search_distance_rev1(base_protection_pts,point_idx,sim_array_list_bs,single_search_dist);
        'length of bs_distance and keep_idx'
        horzcat(length(bs_distance),length(keep_idx))
        %%%%%%%%%%%%Cut the list
        temp_sim_array_list_bs=sim_array_list_bs(keep_idx,:);

        if isempty(temp_sim_array_list_bs)==1
            move_sort_sim_array_list_bs=NaN(1,15);
        else
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Save the full turn off list
            move_sort_sim_array_list_bs=temp_sim_array_list_bs;
            'size move_sort_sim_array_list_bs'
            size(move_sort_sim_array_list_bs)
        end

        persistent_save_var_rev1(app,move_sort_file_name,'move_sort_sim_array_list_bs',move_sort_sim_array_list_bs)


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%tf_full_turnoff==0
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        disp_progress(app,strcat('Line 74: parfor_chunk_movelist_dual_man_azi_rev30_app'))
        tic;

        %%%%%%%%Load pathloss + clutter, cut to move_list_reliability range, fix Inf
        [pathloss,clutter_loss]=load_pathloss_clutter_cut_rel_rev1(app,point_idx,sim_number,data_label1,string_prop_model,reliability,move_list_reliability);
        disp_progress(app,strcat('Line 101: parfor_chunk_movelist_dual_man_azi_rev30_app'))


        %%%%'Cut the base stations and pathloss to be only within the search distance'
        [keep_idx,bs_distance]=cut_bs_by_search_distance_rev1(base_protection_pts,point_idx,sim_array_list_bs,single_search_dist);
        'length of bs_distance and keep_idx'
        horzcat(length(bs_distance),length(keep_idx))


        %%%%%%%%Cut the pathloss / clutter / list
        pathloss=pathloss(keep_idx,:);
        clutter_loss=clutter_loss(keep_idx,:);
        sim_array_list_bs=sim_array_list_bs(keep_idx,:);


        %%%%%%%Take into consideration the sector/azimuth off-axis gain
        [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
        %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain


        [mid_idx]=nearestpoint_app(app,50,move_list_reliability);
        mid_pathloss_dB=pathloss(:,mid_idx);
        mid_clutter_loss=clutter_loss(:,mid_idx);
        'size clutter'
        size(mid_clutter_loss)
        temp_pr_dbm=sim_array_list_bs(:,4)-mid_pathloss_dB-mid_clutter_loss+bs_azi_gain;  %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System


        %%%'need to check if the norm_aas_zero_elevation_data and the 50th percentile cell_aas_dist_data are the same'
        array_aas_dist_data=cell_aas_dist_data{2};
        aas_dist_azimuth=cell_aas_dist_data{1};
        array_50_aas_dist=array_aas_dist_data(:,mid_idx);


        %%%%%%%%%%We just have to make a new bs_eirp_dist based on the azimuth
        %%%%%%%%%%of the base station antenna offset to the federal point.
        mod_azi_diff_bs=array_bs_azi_data(:,4);
        min(mod_azi_diff_bs)
        max(mod_azi_diff_bs)
        %%%%%%%%%Find the azimuth off-axis antenna loss
        [nn_azi_idx]=nearestpoint_app(app,mod_azi_diff_bs,aas_dist_azimuth); %%%%%%%Nearest Azimuth Idx

        %%%%%%%%Now create a super_array_bs_eirp_dist with array_aas_dist_data which will be used in the same way as bs_eirp_dist
        super_array_bs_eirp_dist=array_aas_dist_data(nn_azi_idx, :);



        if tf_opt==0
            disp_progress(app,strcat('Line 185: parfor_chunk_movelist_dual_man_azi_rev30_app'))
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Not optimized, but similar to what CBRS does.
            tic;
            [~,sort_bs_idx]=sort(temp_pr_dbm,'descend'); %%%Sort power received at radar, then this is the order of turn off.
            toc;
        else
            disp_progress(app,strcat('Line 192: parfor_chunk_movelist_dual_man_azi_rev30_app'))

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Near-Optimal Move List
            tf_calc_opt_sort=0  %%%%%%To be used to re-calculate.
            [opt_sort_bs_idx]=near_opt_sort_idx_rev5(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,single_search_dist,sim_array_list_bs,base_protection_pts,temp_pr_dbm,string_prop_model,custom_antenna_pattern,min_azimuth,max_azimuth);
            sort_bs_idx=opt_sort_bs_idx;
        end
        disp_progress(app,strcat('Line 205: parfor_chunk_movelist_dual_man_azi_rev30_app'))


        if any(isnan(sort_bs_idx))
            pause;
        end

        tic;
        sort_sim_array_list_bs=sim_array_list_bs(sort_bs_idx,:);
        sort_full_Pr_dBm=sim_array_list_bs(sort_bs_idx,4)-pathloss(sort_bs_idx,:)+bs_azi_gain(sort_bs_idx); %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain
        sort_clutter_loss=clutter_loss(sort_bs_idx,:);
        toc;
        %%%%%%%Clutter added later because of the randomization.

        check_array_no_nan_rev1(app,bs_azi_gain,'bs_azi_gain','parfor_chunk_movelist_dual_man_azi_rev30_app')
        check_array_no_nan_rev1(app,pathloss,'pathloss','parfor_chunk_movelist_dual_man_azi_rev30_app')
        check_array_no_nan_rev1(app,sim_array_list_bs(:,4),'sim_array_list_bs(:,4)','parfor_chunk_movelist_dual_man_azi_rev30_app')
        check_array_no_nan_rev1(app,sort_full_Pr_dBm,'sort_full_Pr_dBm','parfor_chunk_movelist_dual_man_azi_rev30_app')


        if isempty(sort_full_Pr_dBm)
            disp_progress(app,strcat('Line 248: parfor_chunk_movelist_dual_man_azi_rev30_app'))
            array_turn_off_size=NaN(1,1);
            move_list_turn_off_idx=NaN(1,1);
            move_list_turn_off_idx=move_list_turn_off_idx(~isnan(move_list_turn_off_idx));
        else
            disp_progress(app,strcat('Line 254: parfor_chunk_movelist_dual_man_azi_rev30_app'))

            %%%%%%%%Rand Seed1 for MC Iterations and Move List Calculation
            [rand_seed1]=gen_mc_rand_seed_rev1(mc_size);

            %%%%%%%%%%%%%%%%%This is where we break the mc_iter into chunks
            [hWaitbar_ml_mc_chunks,hWaitbarMsgQueue_ml_mc_chunks]= ParForWaitbarCreateMH_time('MoveList MC Chunks: ',num_chunks);
            if parallel_flag==1
                parfor chunk_idx=1:num_chunks  %%%%%%%%%Parfor
                    parfor_randchunk_ml_rev1_mc_same(app,move_sort_file_name,sim_folder,cell_sim_data,sort_full_Pr_dBm,sort_sim_array_list_bs,super_array_bs_eirp_dist,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,cell_sim_chunk_idx,rand_seed1,sort_clutter_loss,custom_antenna_pattern,single_search_dist,tf_man_azi_step,azimuth_step,move_list_reliability,radar_threshold,move_list_margin,parallel_flag);
                    hWaitbarMsgQueue_ml_mc_chunks.send(0);
                end
                server_status_rev2(app,tf_server_status)
            end


            %%%%%%%%%Then Assemble with for loop
            cell_ml_check_primary=cell(num_chunks,1);
            cell_ml_check_second=cell(num_chunks,1);
            for chunk_idx=1:num_chunks
                temp_parallel_flag=0;
                [sub_array_ml_turnoff_mc,sub_array_ml_turnoff_mc_secondary]=parfor_randchunk_ml_rev1_mc_same(app,move_sort_file_name,sim_folder,cell_sim_data,sort_full_Pr_dBm,sort_sim_array_list_bs,super_array_bs_eirp_dist,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,cell_sim_chunk_idx,rand_seed1,sort_clutter_loss,custom_antenna_pattern,single_search_dist,tf_man_azi_step,azimuth_step,move_list_reliability,radar_threshold,move_list_margin,temp_parallel_flag);
                sub_point_idx=array_rand_chunk_idx(chunk_idx);
                cell_ml_check_primary{sub_point_idx}=sub_array_ml_turnoff_mc;
                cell_ml_check_second{sub_point_idx}=sub_array_ml_turnoff_mc_secondary;
                if parallel_flag==0
                    hWaitbarMsgQueue_ml_mc_chunks.send(0);
                end
            end
            server_status_rev2(app,tf_server_status)

            %%%%%%%%%%%%%%MC Iterations and Calculated Move List
            array_turn_off_size=vertcat(cell_ml_check_primary{:});
            secondary_turn_off_size=vertcat(cell_ml_check_second{:});


            %%%%%%%%%%Pull primary + secondary thresholds/percentiles from cell_sim_data
            [thresh]=get_dpa_thresholds_from_cell_sim_data_rev1(cell_sim_data,sim_folder);
            radar2threshold=thresh.radar2threshold;
            mc_per2=thresh.mc_per2;
            tf_second_data=thresh.tf_second_data_thresh;
            radar2threshold
            mc_per2
            if tf_second_data==0
                tf_second_data=0
            end


            turn_off_size95=ceil(prctile(sort(array_turn_off_size),mc_percentile)) %%%%This was interp between points, so need to ceiling it.

            %%%%%%%%%'need to have the presort move list size determined by both thresholds'
            if tf_second_data==1
                turn_off_size_second=ceil(prctile(sort(secondary_turn_off_size),mc_per2)) %%%%This was interp between points, so need to ceiling it.
                horzcat(turn_off_size95,turn_off_size_second)
                turn_off_size95=max(horzcat(turn_off_size95,turn_off_size_second))
            end


            f2=figure;
            hold on;
            plot(sort(array_turn_off_size),':r')
            xline(length(array_turn_off_size)*mc_percentile/100,'-r','LineWidth',2)
            if tf_second_data==1
                xline(length(array_turn_off_size)*mc_per2/100,'-g','LineWidth',2)
                plot(sort(secondary_turn_off_size),':g')
            end
            yline(turn_off_size95,'-k','LineWidth',2)
            grid on;
            pause(0.1)
            filename1=strcat('MoveList_',num2str(point_idx),'_',num2str(single_search_dist),'km.png');
            persistent_save_figure_rev1(app,gcf,filename1)
            pause(0.1);
            close(f2)


            if turn_off_size95==0
                move_list_turn_off_idx=NaN(1,1);
                move_list_turn_off_idx=move_list_turn_off_idx(~isnan(move_list_turn_off_idx));
                'Error: Inside Pre_sort_ML rev8 Line 301: Check the empty move_list_idx'
            else
                %%%%%Conservative buffer: turn off one additional BS when possible
                [num_tx_full,~]=size(sort_sim_array_list_bs);
                conservative_turn_off=min(turn_off_size95+1,num_tx_full);
                move_list_turn_off_idx=1:1:conservative_turn_off;
            end
        end

        if isempty(move_list_turn_off_idx)==1
            'Empty move_list_turn_off_idx, need to change the code below for the check'
            move_sort_sim_array_list_bs=NaN(1,15);
        else
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Save the full turn off list
            move_sort_sim_array_list_bs=sort_sim_array_list_bs(move_list_turn_off_idx,:);
            size(move_sort_sim_array_list_bs)
        end

        %%%%%%%%%%%%%%%Also saving the distributions
        move_array_turn_off_size_file_name=strcat(string_prop_model,'_array_turn_off_size_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');

        [num_tx_full,~]=size(sort_sim_array_list_bs);
        if max(move_list_turn_off_idx)>num_tx_full
            %%%%%%%%For Some Reason, the idx are too large, we should not get this error
            pause;
        else
            %%%%%Save master_turn_off_idx, Persistent Save
            persistent_save_var_rev1(app,move_array_turn_off_size_file_name,'array_turn_off_size',array_turn_off_size)
            persistent_save_var_rev1(app,move_sort_file_name,'move_sort_sim_array_list_bs',move_sort_sim_array_list_bs)
        end
        toc;
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'This is where we then clean up the single point'
    wait_for_persistent_files_rev1(app,{move_array_turn_off_size_file_name,move_sort_file_name});

    %%%%%%%%%Loop for deleting
    cleanup_subchunk_files_rev1(app,num_chunks,{ ...
        @(s) strcat('sub_',num2str(s),'_array_ml_mc_turnoff_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'_',num2str(single_search_dist),'km.mat'), ...
        @(s) strcat('sub_',num2str(s),'_array_ml_mc_turnoff_secondary_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'_',num2str(single_search_dist),'km.mat')});
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End of clean up



    %%%'Need to clean up the waittimer before leaving the function'
    try
        cleanup_parfor_waitbar_rev1(hWaitbar_ml_mc_chunks,hWaitbarMsgQueue_ml_mc_chunks);
    catch
    end
    server_status_rev2(app,tf_server_status)

end
end
