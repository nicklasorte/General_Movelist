function [move_list_turn_off_idx,sort_bs_idx]=pre_sort_movelist_rev10_multi_eirp_azimuths_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,tf_opt,min_azimuth,max_azimuth,temp_eirp,temp_rsu_eirp)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Move List Function with Azimuth Cut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

move_sort_file_name=strcat(string_prop_model,'_move_list_turn_off_idx_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(temp_eirp),'dBm.mat');
[var_exist_move_sort]=persistent_var_exist_with_corruption(app,move_sort_file_name);

sort_bs_idx_file_name=strcat(string_prop_model,'_sort_bs_idx_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(temp_eirp),'dBm.mat');
[var_exist_sort_idx]=persistent_var_exist_with_corruption(app,sort_bs_idx_file_name);


if var_exist_move_sort==2 && var_exist_sort_idx==2
    %%%%%%%%%%%load
    retry_load=1;
    while(retry_load==1)
        try
            load(sort_bs_idx_file_name,'sort_bs_idx')
            load(move_sort_file_name,'move_list_turn_off_idx')
            retry_load=0;
        catch
            retry_load=1;
            pause(1)
        end
    end
else
    tic;
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


    %%%%%%%% Cut the reliabilities that we will use for the move list
    size(pathloss)
    [rel_first_idx]=nearestpoint_app(app,min(move_list_reliability),reliability);
    [rel_second_idx]=nearestpoint_app(app,max(move_list_reliability),reliability);
    if strcmp(string_prop_model,'TIREM')
        % % % % if TIREM, we wont cut the reliabilites because there are none to cut.
    else
        pathloss=pathloss(:,[rel_first_idx:rel_second_idx]);
    end
    size(pathloss)


    %%%%%%%%%%%%Might need to create the sorted list before we move into the move list calculation, a sort of step 1b.
    %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Unique ID
    %%%%%%Creating a sorted move list for each protection point is not optimial but it allows the calculations to be done in parallel.

    %%%%%%%Take into consideration the sector/azimuth off-axis gain
    [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
    %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel


    [mid_idx]=nearestpoint_app(app,50,move_list_reliability);
    mid_pathloss_dB=pathloss(:,mid_idx);

    %%%%%'Update the EIPR into Column #4'
    %%%%%dBm/10MHz %%%%%EIRP [dBm/10MHz] for Rural, Suburan, Urban : temp_rsu_eirp
    %%%%%%%%%%Add an index for R/S/U (NLCD)
     % % %      %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth
    rural_idx=find(sim_array_list_bs(:,6)==1);
    suburban_idx=find(sim_array_list_bs(:,6)==2);
    urban_idx=find(sim_array_list_bs(:,6)==3);

    array_update_eirp=sim_array_list_bs(:,4);
    array_update_eirp(rural_idx)=temp_rsu_eirp(1);
    array_update_eirp(suburban_idx)=temp_rsu_eirp(2);
    array_update_eirp(urban_idx)=temp_rsu_eirp(3);
    %max(sim_array_list_bs(:,4))
    sim_array_list_bs(:,4)=array_update_eirp;
    %max(sim_array_list_bs(:,4))

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    temp_pr_dbm=sim_array_list_bs(:,4)-mid_pathloss_dB+bs_azi_gain;  %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System

    if tf_opt==0
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Not optimized, but similar to what CBRS does.
        %%%%%%%%%%%%%Quite a bit quicker than the near-opt move list.
        tic;
        [~,sort_bs_idx]=sort(temp_pr_dbm,'descend'); %%%Sort power received at radar, and then this is the order of turn off.
        toc; %%%%%Elapsed time is 0.000862 seconds.
    else
        %disp_progress(app,strcat('PAUSE: Inside Pre_sort_ML rev8 Line 118: Need to double check optimal sort Logic Below'))
        pause;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Near-Optimal Move List Function Start
        %%%%%%Not optimal when we do it separately for all protection points. But this allows us to calculate the protection points in parallel.
        %%%%%%To get closer to optimal, need to have all the temp_pr_dbm for all the protection points. This can be a large array, especially when there are 180~240 azimuths per point.
        % %%%%I assume this is why DoD only calculates the protection with 36 azimuths and 4 protection points, to limit the size of the array.
        %%%%%%But then each protection point is not calculated in parallel, but as one large calculation.
        %%%%%%%%This calculation might take 90 seconds, compared to milliseconds for the CBRS sorted move list.

        tf_calc_opt_sort=0  %%%%%%To be used to re-calculate.
        [opt_sort_bs_idx]=near_opt_sort_idx_string_prop_model_miti_rev3(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,min_ant_loss,sim_array_list_bs,base_protection_pts,temp_pr_dbm,string_prop_model,temp_miti);
        sort_bs_idx=opt_sort_bs_idx; %%%%%%%%%%Use the "Near-Optimal Approach
    end


    if any(isnan(sort_bs_idx))
        %disp_progress(app,strcat('Error: PAUSE: Inside Pre_sort_ML rev8 Line 133: NaN Error on sort_bs_idx'))
        pause;
    end

    %%%sort_mid_pr_dBm(1:10)
    tic;
    sort_sim_array_list_bs=sim_array_list_bs(sort_bs_idx,:);
    sort_full_Pr_dBm=sim_array_list_bs(sort_bs_idx,4)-pathloss(sort_bs_idx,:)+bs_azi_gain(sort_bs_idx); %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System
    toc;

    if any(isnan(bs_azi_gain))
        find(isnan(bs_azi_gain))
        %disp_progress(app,strcat('Error: PAUSE: Inside Pre_sort_ML rev8 Line 145: NaN error on bs_azi_gain'))
        pause;
    end

    if any(isnan(pathloss))
        find(isnan(pathloss))
        %disp_progress(app,strcat('Error: PAUSE: Inside Pre_sort_ML rev8 Line 151: NaN error on pathloss'))
        pause;
    end

    if any(isnan(sim_array_list_bs(:,4)))
        find(isnan(sim_array_list_bs(:,4)))
        %disp_progress(app,strcat('Error: PAUSE: Inside Pre_sort_ML rev8 Line 157: NaN error on sim_array_list_bs(:,4)'))
        pause;
    end

    if any(isnan(sort_full_Pr_dBm))
        sort_full_Pr_dBm
        %find(isnan(sort_full_Pr_dBm(:,1)))
        %disp_progress(app,strcat('Error: PAUSE: Inside Pre_sort_ML rev8 Line 164: NaN error on sort_full_Pr_dBm'))
        pause;
    end
    %%%sort_full_Pr_dBm(1:10,:)'
    %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Unique ID


    if isempty(sort_full_Pr_dBm)
        %disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line 194: Empty sort_full_Pr_dBm'))
        move_list_turn_off_idx=NaN(1,1);
        move_list_turn_off_idx=move_list_turn_off_idx(~isnan(move_list_turn_off_idx));
    else
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%This is where we put the Generalized Move List
        %disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line 200: Starting to Calculate the Move List'))

        %%%%%%%%%%Add Radar Antenna Pattern: Offset from 0 degrees and loss in dB
        if radar_beamwidth==360
            radar_ant_array=vertcat(horzcat(0,0),horzcat(360,0));
            min_ant_loss=0;
        else
            [radar_ant_array]=horizontal_antenna_loss_app(app,radar_beamwidth,min_ant_loss);
            %%%%%%%%%%%Note, this is not STATGAIN
        end
        %%%%%%%%%%%%%%%%Calculate the simualation azimuths
        [array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth);
        %array_sim_azimuth


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Each Base Station Azimuth
        sim_pt=base_protection_pts(point_idx,:);
        bs_azimuth=azimuth(sim_pt(1),sim_pt(2),sort_sim_array_list_bs(:,1),sort_sim_array_list_bs(:,2));

        %%%%%%%%%Need to calculate the off-axis
        %%%%%%%%%gain when we take

        %%%%%%%%Rand Seed1 for MC Iterations and Move List Calculation
        tempx=ceil(rand(1)*mc_size);
        tempy=ceil(rand(1)*mc_size);
        rand_seed1=tempx+tempy;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%Generate MC Iterations and Calculate Move List
        %%%Preallocate
        array_turn_off_size=NaN(mc_size,1);
        [num_tx,~]=size(sort_sim_array_list_bs);

        array_off_axis_loss_fed=NaN(num_tx,num_sim_azi);%%%%%Export this in the excel file. Only do this for the first monte carlo iteration
        array_sort_mc_dBm=NaN(num_tx,num_sim_azi);%%%%%Export this in the excel file. Only do this for the first monte carlo iteration
        %disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line 234: Entering the Monte Carlo Loop'))
        for mc_iter=1:1:mc_size
            %disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line 236:',num2str(mc_iter)))
            mc_iter
            %%%%%%%Generate 1 MC Iteration
            [sort_monte_carlo_pr_dBm]=monte_carlo_Pr_dBm_rev1_app(app,rand_seed1,mc_iter,move_list_reliability,sort_full_Pr_dBm);


            if length(reliability)==1 %%%%%%%This assume 50%
                if ~all(sort_full_Pr_dBm==sort_monte_carlo_pr_dBm)
                    disp_progress(app,strcat('Error: Pause: Inside Pre_sort_ML rev8 Line 244:Error:Pr dBm Mismatch'))
                    pause;
                end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Move List for Single MC Iteration
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%Preallocate
            azimuth_turn_off_size=NaN(num_sim_azi,1);
            for azimuth_idx=1:1:num_sim_azi
                %horzcat(azimuth_idx,num_sim_azi)

                %%%Find CBSD azimuths outside of +/- of half_ant_hor_deg of temp_azimuth
                sim_azimuth=array_sim_azimuth(azimuth_idx);

                %%%%%%%Calculate the loss due to off axis in the horizontal direction
                [off_axis_loss]=calc_off_axix_loss_rev1_app(app,sim_azimuth,bs_azimuth,radar_ant_array,min_ant_loss);
                sort_temp_mc_dBm=sort_monte_carlo_pr_dBm-off_axis_loss;

                %%%%Maybe save this too, but only for the first
                %%%%mc-iteration, and only if there is one mc iteration.

                if mc_iter==1
                    array_sort_mc_dBm(:,azimuth_idx)=sort_temp_mc_dBm;
                    array_off_axis_loss_fed(:,azimuth_idx)=off_axis_loss;
                end

                if any(isnan(sort_temp_mc_dBm))  %%%%%%%%Check
                    disp_progress(app,strcat('Error: Pause: Inside Pre_sort_ML rev8 Line 272: NaN Error: temp_mc_dBm'))
                    pause;
                end

                %%%%%%Convert to Watts, Sum, and Find Aggregate
                %%%pow2db(0.1*1000)=20, 0.1 Watts = 20dBm
                %%%db2pow(20)/1000=0.1, 20dBm = 0.1 Watts
                binary_sort_mc_watts=db2pow(sort_temp_mc_dBm)/1000; %%%%%%To be used for the binary search

                if any(isnan(binary_sort_mc_watts))
                    disp_progress(app,strcat('Error: Pause: Inside Pre_sort_ML rev8 Line 282: NaN Error: temp_mc_watts'))
                    pause;
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Binary Search
                [mid]=pre_sort_binary_movelist_rev2_app(app,radar_threshold,binary_sort_mc_watts);
                azimuth_turn_off_size(azimuth_idx)=mid;
            end
            array_turn_off_size(mc_iter)=max(azimuth_turn_off_size); %%%%%%%%%%%max across all azimuths for a single MC iteration
        end


        %sort(array_turn_off_size)
        turn_off_size95=ceil(prctile(array_turn_off_size,mc_percentile)); %%%%This was interp between points, so need to ceiling it.


        if turn_off_size95==0
            move_list_turn_off_idx=NaN(1,1);
            move_list_turn_off_idx=move_list_turn_off_idx(~isnan(move_list_turn_off_idx));
            %disp_progress(app,strcat('Error: Pause: Inside Pre_sort_ML rev8 Line 301: Check the empty move_list_idx'))
            'Error: Inside Pre_sort_ML rev8 Line 301: Check the empty move_list_idx'
            %pause;
        else
            move_list_turn_off_idx=1:1:turn_off_size95;
        end
    end

% % %     if isempty(move_list_turn_off_idx)==1
% % %         'Empty move_list_turn_off_idx, need to change the code below for the check'
% % %         move_sort_sim_array_list_bs=NaN(1,15);
% % %         %%%move_sort_sim_array_list_bs(:,[1:15])=[]
% % %         %%%%%
% % %     else
% % %         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Save the full turn off list
% % %         move_sort_sim_array_list_bs=sort_sim_array_list_bs(move_list_turn_off_idx,:);
% % %         size(move_sort_sim_array_list_bs)
% % %     end


    

    [num_tx_full,~]=size(sort_sim_array_list_bs);
    if max(move_list_turn_off_idx)>num_tx_full
        %%%%%%%%For Some Reason, the idx are too
        %%%%%%%%large, we should not get this error
        disp_progress(app,strcat('Error: Pause: Inside Pre_sort_ML rev10 Line 326: Error Move list too large'))
        pause;
    else %%%%%%Save the move list
        %%%%%Save master_turn_off_idx, Persistent Save
        retry_save=1;
        while(retry_save==1)
            try
                save(move_sort_file_name,'move_list_turn_off_idx') %%%%%%These are the index of the sort_sim_array_list_bs
                save(sort_bs_idx_file_name,'sort_bs_idx')
                retry_save=0;
            catch
                retry_save=1;
                pause(1)
            end
        end
    end
    toc;
end
%disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line 344: Finished'))

end