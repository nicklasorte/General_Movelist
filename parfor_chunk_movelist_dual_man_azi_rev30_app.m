function [move_sort_sim_array_list_bs]=parfor_chunk_movelist_dual_man_azi_rev30_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,tf_opt,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,move_list_margin,tf_full_turnoff,cell_sim_data,sim_folder,tf_man_azi_step,azimuth_step,parallel_flag,tf_server_status)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Move List Function with Neighborhoor Cut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp_progress(app,strcat('Line 7: parfor_chunk_movelist_dual_man_azi_rev30_app'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check for Move List File, if none, save place holder
%disp_progress(app,strcat('Inside Pre_sort_ML_rev8 Line11'))

move_sort_file_name=strcat(string_prop_model,'_move_sort_sim_array_list_bs_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
[var_exist_move_sort]=persistent_var_exist_with_corruption(app,move_sort_file_name);

if var_exist_move_sort==2
    %%%%%%%%%%%load
    retry_load=1;
    while(retry_load==1)
        try
            load(move_sort_file_name,'move_sort_sim_array_list_bs')
            retry_load=0;
        catch
            retry_load=1;
            pause(1)
        end
    end
else
    disp_progress(app,strcat('Line 28: parfor_chunk_movelist_dual_man_azi_rev30_app'))
    %%%Same as Agg Check
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%This is where we define the num_chunks,
    [num_chunks,cell_sim_chunk_idx,array_rand_chunk_idx]=dynamic_mc_chunks_rev1(app,mc_size);

    %%%%%%%%Remove empty cell_sim_chunk_idx
    
    if tf_full_turnoff==1
        disp_progress(app,strcat('Line 36: parfor_chunk_movelist_dual_man_azi_rev30_app'))
        %%%%%%%%%If we're turning off the full circle, no need to do all the calculations.
        %%%%%%This cuts overall computational time in half.
        sim_pt=base_protection_pts(point_idx,:);
        bs_distance=deg2km(distance(sim_pt(1),sim_pt(2),sim_array_list_bs(:,1),sim_array_list_bs(:,2)));
        keep_idx=find(bs_distance<=single_search_dist);
        'length of bs_distance and keep_idx'
        horzcat(length(bs_distance),length(keep_idx))
        %%%%%%%%%%%%Cut the list
        temp_sim_array_list_bs=sim_array_list_bs(keep_idx,:);

        if isempty(temp_sim_array_list_bs)==1
            %'Empty list'
            move_sort_sim_array_list_bs=NaN(1,15);
            %'check for empty'
            %pause;
        else
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Save the full turn off list
            move_sort_sim_array_list_bs=temp_sim_array_list_bs;
            'size move_sort_sim_array_list_bs'
            size(move_sort_sim_array_list_bs)
        end

        retry_save=1;
        while(retry_save==1)
            try
                save(move_sort_file_name,'move_sort_sim_array_list_bs')
                retry_save=0;
            catch
                retry_save=1;
                pause(1)
            end
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%tf_full_turnoff==0
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        disp_progress(app,strcat('Line 74: parfor_chunk_movelist_dual_man_azi_rev30_app'))
        tic;
        %point_idx

        file_name_pathloss=strcat(string_prop_model,'_pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
        retry_load=1;
        while(retry_load==1)
            try
                load(file_name_pathloss,'pathloss')
                retry_load=0;
            catch
                retry_load=1;
                pause(1)
            end
        end

        file_name_clutter=strcat('P2108_clutter_loss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
        retry_load=1;
        while(retry_load==1)
            try
                load(file_name_clutter,'clutter_loss')
                retry_load=0;
            catch
                retry_load=1;
                pause(1)
            end
        end
        disp_progress(app,strcat('Line 101: parfor_chunk_movelist_dual_man_azi_rev30_app'))


        %%%%%%%% Cut the reliabilities that we will use for the move list
        %disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line62: Cutting Reliabilities'))
        %size(pathloss)
        [rel_first_idx]=nearestpoint_app(app,min(move_list_reliability),reliability);
        [rel_second_idx]=nearestpoint_app(app,max(move_list_reliability),reliability);
        if strcmp(string_prop_model,'TIREM')
            % % % % if TIREM, we wont cut the reliabilites because there are none to cut.
        else
            pathloss=pathloss(:,[rel_first_idx:rel_second_idx]);
        end
        %size(pathloss)
        [pathloss]=fix_inf_pathloss_rev1(app,pathloss);

        %%%%%%%% Cut the reliabilities that we will use for the move list
        %size(clutter_loss)
        [rel_first_idx]=nearestpoint_app(app,min(move_list_reliability),reliability);
        [rel_second_idx]=nearestpoint_app(app,max(move_list_reliability),reliability);
        clutter_loss=clutter_loss(:,[rel_first_idx:rel_second_idx]);
        %size(clutter_loss)


        %%%%'Cut the base stations and pathloss to be only within the search distance'
        %disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line75: Cutting Base Stations'))
        sim_pt=base_protection_pts(point_idx,:);
        bs_distance=deg2km(distance(sim_pt(1),sim_pt(2),sim_array_list_bs(:,1),sim_array_list_bs(:,2)));
        keep_idx=find(bs_distance<=single_search_dist);
        'length of bs_distance and keep_idx'
        horzcat(length(bs_distance),length(keep_idx))


        %%%%%%%%Cut the pathloss
        pathloss=pathloss(keep_idx,:);
        %size(pathloss)
        %%%%%%%%Cut the clutter
        clutter_loss=clutter_loss(keep_idx,:);
        %size(clutter_loss)

        %%%%%%%%%%%%Cut the list
        sim_array_list_bs=sim_array_list_bs(keep_idx,:);
        %size(sim_array_list_bs)

        %%%%%%%%%%%%Might need to create the sorted list before we move into the move list calculation, a sort of step 1b.
        %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Unique ID
        %%%%%%Creating a sorted move list for each protection point is not optimial but it allows the calculations to be done in parallel.


        %%%%%%%Take into consideration the sector/azimuth off-axis gain
        %disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line 102: Calculating Off Axis BS Gain'))
        [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
        %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel


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
        %size(super_array_bs_eirp_dist)


        
        if tf_opt==0
            disp_progress(app,strcat('Line 185: parfor_chunk_movelist_dual_man_azi_rev30_app'))
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Not optimized, but similar to what CBRS does.
            %%%%%%%%%%%%%Quite a bit quicker than the near-opt move list.
            tic;
            [~,sort_bs_idx]=sort(temp_pr_dbm,'descend'); %%%Sort power received at radar, and then this is the order of turn off.
            toc; %%%%%Elapsed time is 0.000862 seconds.
        else
            disp_progress(app,strcat('Line 192: parfor_chunk_movelist_dual_man_azi_rev30_app'))
            %disp_progress(app,strcat('PAUSE: Inside Pre_sort_ML rev8 Line 118: Need to double check optimal sort Logic Below'))

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Near-Optimal Move List Function Start
            %%%%%%Not optimal when we do it separately for all protection points. But this allows us to calculate the protection points in parallel.
            %%%%%%To get closer to optimal, need to have all the temp_pr_dbm for all the protection points. This can be a large array, especially when there are 180~240 azimuths per point.
            % %%%%I assume this is why DoD only calculates the protection with 36 azimuths and 4 protection points, to limit the size of the array.
            %%%%%%But then each protection point is not calculated in parallel, but as one large calculation.
            %%%%%%%%This calculation might take 90 seconds, compared to milliseconds for the CBRS sorted move list.
            tf_calc_opt_sort=0  %%%%%%To be used to re-calculate.
            [opt_sort_bs_idx]=near_opt_sort_idx_rev5(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,single_search_dist,sim_array_list_bs,base_protection_pts,temp_pr_dbm,string_prop_model,custom_antenna_pattern,min_azimuth,max_azimuth);
            sort_bs_idx=opt_sort_bs_idx; %%%%%%%%%%Use the "Near-Optimal Approach
        end
        disp_progress(app,strcat('Line 205: parfor_chunk_movelist_dual_man_azi_rev30_app'))


        if any(isnan(sort_bs_idx))
            %disp_progress(app,strcat('Error: PAUSE: Inside Pre_sort_ML rev8 Line 133: NaN Error on sort_bs_idx'))
            pause;
        end

        %%%sort_mid_pr_dBm(1:10)
        tic;
        sort_sim_array_list_bs=sim_array_list_bs(sort_bs_idx,:);
        sort_full_Pr_dBm=sim_array_list_bs(sort_bs_idx,4)-pathloss(sort_bs_idx,:)+bs_azi_gain(sort_bs_idx); %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System
        sort_clutter_loss=clutter_loss(sort_bs_idx,:);
        toc;
        %%%%%%%Clutter added later because of the randomization.

        if any(isnan(bs_azi_gain))
            find(isnan(bs_azi_gain))
            disp_progress(app,strcat('Line 223: Error: PAUSE: parfor_chunk_movelist_dual_man_azi_rev30_app: NaN error on bs_azi_gain'))
            pause;
        end

        if any(isnan(pathloss))
            find(isnan(pathloss))
            disp_progress(app,strcat('Line 229: Error: PAUSE: parfor_chunk_movelist_dual_man_azi_rev30_app:: NaN error on pathloss'))
            pause;
        end

        if any(isnan(sim_array_list_bs(:,4)))
            find(isnan(sim_array_list_bs(:,4)))
            disp_progress(app,strcat('Line 235: Error: PAUSE: parfor_chunk_movelist_dual_man_azi_rev30_app:: NaN error on sim_array_list_bs(:,4)'))
            pause;
        end

        if any(isnan(sort_full_Pr_dBm))
            sort_full_Pr_dBm
            %find(isnan(sort_full_Pr_dBm(:,1)))
            disp_progress(app,strcat('Line 242: Error: PAUSE: parfor_chunk_movelist_dual_man_azi_rev30_app:: NaN error on sort_full_Pr_dBm'))
            pause;
        end


        if isempty(sort_full_Pr_dBm)
            disp_progress(app,strcat('Line 248: parfor_chunk_movelist_dual_man_azi_rev30_app'))
            %disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line 194: Empty sort_full_Pr_dBm'))
            array_turn_off_size=NaN(1,1);
            move_list_turn_off_idx=NaN(1,1);
            move_list_turn_off_idx=move_list_turn_off_idx(~isnan(move_list_turn_off_idx));
        else
            disp_progress(app,strcat('Line 254: parfor_chunk_movelist_dual_man_azi_rev30_app'))
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %%%%%%%%Rand Seed1 for MC Iterations and Move List Calculation
            tempx=ceil(rand(1)*mc_size);
            tempy=ceil(rand(1)*mc_size);
            rand_seed1=tempx+tempy;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%This is where we break the mc_iter into chunks, like pathloss

            [hWaitbar_ml_mc_chunks,hWaitbarMsgQueue_ml_mc_chunks]= ParForWaitbarCreateMH_time('MoveList MC Chunks: ',num_chunks);    %%%%%%% Create ParFor Waitbar, this one covers points and chunks
            %%%%'This is where we create the chunks and do a parfor and then stitch together with a for loop'
            if parallel_flag==1
                parfor chunk_idx=1:num_chunks  %%%%%%%%%Parfor
                    parfor_randchunk_ml_rev1_mc_same(app,move_sort_file_name,sim_folder,cell_sim_data,sort_full_Pr_dBm,sort_sim_array_list_bs,super_array_bs_eirp_dist,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,cell_sim_chunk_idx,rand_seed1,sort_clutter_loss,custom_antenna_pattern,single_search_dist,tf_man_azi_step,azimuth_step,move_list_reliability,radar_threshold,move_list_margin,parallel_flag);
                    hWaitbarMsgQueue_ml_mc_chunks.send(0);
                end
                server_status_rev2(app,tf_server_status) %%%%%%%%%%Send an update after we done all the heavy computation
            end


            %%%%%%%%%Then Assemble with for loop
            cell_ml_check_primary=cell(num_chunks,1);  %%%%Primary and Secondary
            cell_ml_check_second=cell(num_chunks,1);
            for chunk_idx=1:num_chunks  %%%%%%%%%Parfor
                temp_parallel_flag=0;
                %[sub_array_agg_check_mc_dBm]=parfor_randchunk_aggcheck_rev9_mc_same(app,agg_check_file_name,agg_dist_file_name,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,temp_parallel_flag,single_search_dist,tf_man_azi_step,azimuth_step);
                [sub_array_ml_turnoff_mc,sub_array_ml_turnoff_mc_secondary]=parfor_randchunk_ml_rev1_mc_same(app,move_sort_file_name,sim_folder,cell_sim_data,sort_full_Pr_dBm,sort_sim_array_list_bs,super_array_bs_eirp_dist,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,cell_sim_chunk_idx,rand_seed1,sort_clutter_loss,custom_antenna_pattern,single_search_dist,tf_man_azi_step,azimuth_step,move_list_reliability,radar_threshold,move_list_margin,temp_parallel_flag);
                sub_point_idx=array_rand_chunk_idx(chunk_idx);
                cell_ml_check_primary{sub_point_idx}=sub_array_ml_turnoff_mc;
                cell_ml_check_second{sub_point_idx}=sub_array_ml_turnoff_mc_secondary;
                if parallel_flag==0
                    hWaitbarMsgQueue_ml_mc_chunks.send(0);%%%%%%%Decrement the waitbar
                end
            end
            server_status_rev2(app,tf_server_status) %%%%%%%%%%Send an update after we done all the heavy computation

            %%%%%%%%%%%%%%MC Iterations and Calculated Move List
            array_turn_off_size=vertcat(cell_ml_check_primary{:});
            secondary_turn_off_size=vertcat(cell_ml_check_second{:});

            % size(array_turn_off_size)
            % size(secondary_turn_off_size)


            %%%%%%%%%%Find the secondary I/N and Percentiles and the
            %%%%%Need the secondary, if they are there
            %%%%%%%%%%Find the secondary DPA Threshold and Percentiles,
            %%%%%%%%%%if so then another all_data_stats_binary
            data_header=cell_sim_data(1,:)';
            label_idx=find(matches(data_header,'data_label1'));
            row_folder_idx=find(matches(cell_sim_data(:,label_idx),sim_folder));

            %%%%%Need the secondary, if they are there
            dpa2thres_idx=find(matches(data_header,'dpa_second_threshold'));
            per2_idx=find(matches(data_header,'second_mc_percentile'));

            if ~isempty(dpa2thres_idx)
                radar2threshold=cell_sim_data{row_folder_idx,dpa2thres_idx};
            else
                radar2threshold=NaN(1,1);
            end
            if ~isempty(per2_idx)
                mc_per2=cell_sim_data{row_folder_idx,per2_idx};
            else
                mc_per2=NaN(1,1);
            end
            radar2threshold
            mc_per2

            if ~isnan(radar2threshold)
                tf_second_data=1;
            else
                tf_second_data=0
                %pause;
            end


            %sort(array_turn_off_size)
            turn_off_size95=ceil(prctile(sort(array_turn_off_size),mc_percentile)) %%%%This was interp between points, so need to ceiling it.

            %%%%%%%%%'need to have the presort move list size determined by both thresholds'
            if tf_second_data==1
                turn_off_size_second=ceil(prctile(sort(secondary_turn_off_size),mc_per2)) %%%%This was interp between points, so need to ceiling it.
                horzcat(turn_off_size95,turn_off_size_second)
                turn_off_size95=max(horzcat(turn_off_size95,turn_off_size_second))
                %%%'take the max'
            end

            % 'DONE: need to check turn_off_size95 for the turn_off_size_second that has NaN'
            % pause;


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
            retry_save=1;
            while(retry_save==1)
                try
                    saveas(gcf,char(filename1))
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(1)
                end
            end
            pause(0.1);
            close(f2)
            % 'Check percentile'
            % pause;



            if turn_off_size95==0
                move_list_turn_off_idx=NaN(1,1);
                move_list_turn_off_idx=move_list_turn_off_idx(~isnan(move_list_turn_off_idx));
                %disp_progress(app,strcat('Error: Pause: Inside Pre_sort_ML rev8 Line 301: Check the empty move_list_idx'))
                'Error: Inside Pre_sort_ML rev8 Line 301: Check the empty move_list_idx'
                %pause;
            else
                %%%%move_list_turn_off_idx=1:1:turn_off_size95;%%%%%%%%%%%%%%%%%%%%%This was the original

                %%%%%Conservative buffer: turn off one additional BS when possible
                [num_tx_full,~]=size(sort_sim_array_list_bs);
                conservative_turn_off=min(turn_off_size95+1,num_tx_full);
                move_list_turn_off_idx=1:1:conservative_turn_off;
            end
        end

        if isempty(move_list_turn_off_idx)==1
            'Empty move_list_turn_off_idx, need to change the code below for the check'
            move_sort_sim_array_list_bs=NaN(1,15);
            %%%move_sort_sim_array_list_bs(:,[1:15])=[]
            %%%%%
        else
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Save the full turn off list
            move_sort_sim_array_list_bs=sort_sim_array_list_bs(move_list_turn_off_idx,:);
            size(move_sort_sim_array_list_bs)
        end

        %%%%%%%%%%%%%%%Also saving the distributions
        move_array_turn_off_size_file_name=strcat(string_prop_model,'_array_turn_off_size_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');

        [num_tx_full,~]=size(sort_sim_array_list_bs);
        if max(move_list_turn_off_idx)>num_tx_full
            %%%%%%%%For Some Reason, the idx are too
            %%%%%%%%large, we should not get this error
            %disp_progress(app,strcat('Error: Pause: Inside Pre_sort_ML rev8 Line 326: Error Move list too large'))
            pause;
        else %%%%%%Save the move list
            %%%%%Save master_turn_off_idx, Persistent Save
            retry_save=1;
            while(retry_save==1)
                try
                    save(move_array_turn_off_size_file_name,'array_turn_off_size')
                    save(move_sort_file_name,'move_sort_sim_array_list_bs')
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(1)
                end
            end
        end
        toc;
    end


    %%%%'delete the chunks before leaving this function'

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'This is where we then clean up the single point'
    %%%%%%%%%%%%Double check that it is there.
    tf_file_check_loop=1;
    while(tf_file_check_loop==1)
        try
            [var_exist1]=persistent_var_exist_with_corruption(app,move_array_turn_off_size_file_name);
            [var_exist2]=persistent_var_exist_with_corruption(app,move_sort_file_name);
            pause(0.1);
        catch
            var_exist1=0;
            var_exist2=0;
            pause(0.1)
        end
        if var_exist1==2 && var_exist2==2
            tf_file_check_loop=0;
        else
            tf_file_check_loop=1;
            pause(10)
        end
    end

    if var_exist1==2 && var_exist2==2
        %%%%%%%%%Loop for deleting
        for sub_point_idx=1:num_chunks
            file_name_ml_turnoff_chunk=strcat('sub_',num2str(sub_point_idx),'_array_ml_mc_turnoff_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'_',num2str(single_search_dist),'km.mat');
            persistent_delete_rev1(app,file_name_ml_turnoff_chunk)

            file_name_ml_turnoff_chunk_second=strcat('sub_',num2str(sub_point_idx),'_array_ml_mc_turnoff_secondary_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'_',num2str(single_search_dist),'km.mat');
            persistent_delete_rev1(app,file_name_ml_turnoff_chunk_second)
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End of clean up



    %%%'Need to clean up the waittimer before leaving the function'
    try
        delete(hWaitbarMsgQueue_ml_mc_chunks);
        close(hWaitbar_ml_mc_chunks);
    catch
    end
    server_status_rev2(app,tf_server_status) %%%%%%%%%%Send an update after we done all the heavy computation

end
%disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line 344: Finished'))
