function [move_list_turn_off_idx,sort_sim_array_list_bs,sort_bs_idx,array_bs_azi_data,sort_full_Pr_dBm,sorted_array_fed_azi_data,sorted_array_mc_pr_dbm,move_sort_sim_array_list_bs]=pre_sort_movelist_rev7_miti_string_prop_model_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,temp_miti)





%%%%%%%%%Check for Move List File, if none, save place holder

movelist_file_name=strcat(string_prop_model,'_move_list_turn_off_idx_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(temp_miti),'dB.mat');

%%%%%The sort_idx might change if 50% is not included in the move_list_reliability
if isempty(find(move_list_reliability==50))
    'The sort_idx might change if 50% is not included in the move_list_reliability, need to update the filenames.'
    pause;
end


filename_move_sort_sim_array_list_bs=strcat(string_prop_model,'_move_sort_sim_array_list_bs_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(temp_miti),'dB.mat');

sort_bs_idx_file_name=strcat(data_label1,'_',string_prop_model,'_sort_bs_idx_',num2str(point_idx),'_',num2str(temp_miti),'dB.mat');
sort_sim_array_file_name=strcat(data_label1,'_',string_prop_model,'_sort_sim_array_list_bs_',num2str(point_idx),'_',num2str(temp_miti),'dB.mat');
sort_Pr_dBm_file_name=strcat(data_label1,'_',string_prop_model,'_sort_full_Pr_dBm_',num2str(point_idx),'_',num2str(temp_miti),'dB.mat');
sort_bs_azi_data_file_name=strcat(data_label1,'_',string_prop_model,'_array_bs_azi_data_',num2str(point_idx),'_',num2str(temp_miti),'dB.mat');
sorted_array_fed_azi_data_file_name=strcat(data_label1,'_',string_prop_model,'_sorted_array_fed_azi_data_',num2str(point_idx),'_',num2str(temp_miti),'dB.mat');
sorted_array_mc_pr_dbm_file_name=strcat(data_label1,'_',string_prop_model,'_sorted_array_mc_pr_dbm_data_',num2str(point_idx),'_',num2str(temp_miti),'dB.mat');


[var_exist_move_sort_sim_array_list_bs]=persistent_var_exist_with_corruption(app,filename_move_sort_sim_array_list_bs);

[var_exist_movelist]=persistent_var_exist_with_corruption(app,movelist_file_name);
[var_exist_sort_idx]=persistent_var_exist_with_corruption(app,sort_bs_idx_file_name);
[var_exist_sim_array]=persistent_var_exist_with_corruption(app,sort_sim_array_file_name);
[var_exist_PrdBm]=persistent_var_exist_with_corruption(app,sort_Pr_dBm_file_name);
[var_exist_bs_azi]=persistent_var_exist_with_corruption(app,sort_bs_azi_data_file_name);
[var_exist_fed_azi]=persistent_var_exist_with_corruption(app,sorted_array_fed_azi_data_file_name);
[var_exist_mc_pr_dbm]=persistent_var_exist_with_corruption(app,sorted_array_mc_pr_dbm_file_name);

if var_exist_move_sort_sim_array_list_bs==2 && var_exist_movelist==2 && var_exist_sort_idx==2 && var_exist_sim_array==2 && var_exist_PrdBm==2 && var_exist_bs_azi==2 && var_exist_fed_azi==2 && var_exist_mc_pr_dbm==2
    %%%%%%%%%%%load
    retry_load=1;
    while(retry_load==1)
        try
            load(filename_move_sort_sim_array_list_bs,'move_sort_sim_array_list_bs')

            load(movelist_file_name,'move_list_turn_off_idx')
            load(sort_bs_idx_file_name,'sort_bs_idx')
            load(sort_Pr_dBm_file_name,'sort_full_Pr_dBm')
            load(sort_sim_array_file_name,'sort_sim_array_list_bs')
            load(sort_bs_azi_data_file_name,'array_bs_azi_data')
            load(sorted_array_fed_azi_data_file_name,'sorted_array_fed_azi_data')
            load(sorted_array_mc_pr_dbm_file_name,'sorted_array_mc_pr_dbm')
            retry_load=0;
        catch
            retry_load=1;
            pause(1)
        end
    end
else
    tic;
    %point_idx

    %%%%%%Persistent Load
    %%file_name_pathloss=strcat('ITM_Pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
    file_name_pathloss=strcat(string_prop_model,'_pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat')
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

% % %     sim_array_list_bs(1,:)
% % %     '1Lat'
% % %     '2Lon'
% % %     '7 azimuth sector'
% % %     '6: NLCD 1-3'
% % % 
% % %     'check'
% % %     pause;

    %%%%%%%Take into consideration the sector/azimuth off-axis gain
    [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
    %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel


    [mid_idx]=nearestpoint_app(app,50,move_list_reliability);
    mid_pathloss_dB=pathloss(:,mid_idx);
    temp_pr_dbm=sim_array_list_bs(:,4)-mid_pathloss_dB+bs_azi_gain-temp_miti;  %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System

% % % % %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Not optimized, but similar to what CBRS does.
% % % % %     %%%%%%%%%%%%%Quite a bit quicker than the near-opt move list.
% % % % %     tic;
% % % % %     [~,sort_bs_idx]=sort(temp_pr_dbm,'descend'); %%%Sort power received at radar, and then this is the order of turn off.
% % % % %     toc; %%%%%Elapsed time is 0.000862 seconds.


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Near-Optimal Move List Function Start
    %%%%%%Not optimal when we do it separately for all protection points. But this allows us to calculate the protection points in parallel.
    %%%%%%To get closer to optimal, need to have all the temp_pr_dbm for all the protection points. This can be a large array, especially when there are 180~240 azimuths per point.
    % %%%%I assume this is why DoD only calculates the protection with 36 azimuths and 4 protection points, to limit the size of the array.
    %%%%%%But then each protection point is not calculated in parallel, but as one large calculation.
    %%%%%%%%This calculation might take 90 seconds, compared to milliseconds for the CBRS sorted move list.

    tf_calc_opt_sort=0  %%%%%%To be used to re-calculate.
    %%%%%%%%%%%%%%%%%%[opt_sort_bs_idx]=near_opt_sort_idx_rev1(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,min_ant_loss,sim_array_list_bs,base_protection_pts,temp_pr_dbm);
    %%%%%[opt_sort_bs_idx]=near_opt_sort_idx_string_prop_model_rev2(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,min_ant_loss,sim_array_list_bs,base_protection_pts,temp_pr_dbm,string_prop_model);
    [opt_sort_bs_idx]=near_opt_sort_idx_string_prop_model_miti_rev3(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,min_ant_loss,sim_array_list_bs,base_protection_pts,temp_pr_dbm,string_prop_model,temp_miti);

    sort_bs_idx=opt_sort_bs_idx; %%%%%%%%%%Use the "Near-Optimal Approach



    if any(isnan(sort_bs_idx))
        'NaN Error on sort_bs_idx'
        pause;
    end

    %%%sort_mid_pr_dBm(1:10)
    sort_sim_array_list_bs=sim_array_list_bs(sort_bs_idx,:);
    sort_full_Pr_dBm=sim_array_list_bs(sort_bs_idx,4)-pathloss(sort_bs_idx,:)+bs_azi_gain(sort_bs_idx)-temp_miti; %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System

    if any(isnan(bs_azi_gain))
        find(isnan(bs_azi_gain))
        'NaN error on bs_azi_gain'
        pause;
    end

    if any(isnan(pathloss))
        find(isnan(pathloss))
        'NaN error on pathloss'
        pause;
    end

    if any(isnan(sim_array_list_bs(:,4)))
        find(isnan(sim_array_list_bs(:,4)))
        'NaN error on sim_array_list_bs(:,4)'
        pause;
    end

    if any(isnan(sort_full_Pr_dBm))
        sort_full_Pr_dBm
        %find(isnan(sort_full_Pr_dBm(:,1)))
        'NaN error on sort_full_Pr_dBm'
        pause;
    end
    %%%sort_full_Pr_dBm(1:10,:)'
    %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Unique ID

    retry_save=1;
    while(retry_save==1)
        try
            save(sort_bs_idx_file_name,'sort_bs_idx')
            save(sort_Pr_dBm_file_name,'sort_full_Pr_dBm')
            save(sort_sim_array_file_name,'sort_sim_array_list_bs')
            save(sort_bs_azi_data_file_name,'array_bs_azi_data')
            retry_save=0;
        catch
            retry_save=1;
            pause(0.1)
        end
    end

% % %     %%%%%%%%%%%Check to see if it really is sorted, but only do this if we are using the CBRS method.
% % %     [mid_move_idx]=nearestpoint_app(app,50,move_list_reliability);
% % %     if issorted(sort_full_Pr_dBm(:,mid_move_idx),'descend')==0
% % %         'Error: Not sorted'
% % %         pause;
% % %     end

    %%%%%%%%For this first pass, no mitigations


    if isempty(sort_full_Pr_dBm)
        move_list_turn_off_idx=NaN(1,1);
        move_list_turn_off_idx=move_list_turn_off_idx(~isnan(move_list_turn_off_idx));
    else
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%This is where we put the Generalized Move List

        %%%%%%%%%%Add Radar Antenna Pattern: Offset from 0 degrees and loss in dB
        if radar_beamwidth==360
            radar_ant_array=vertcat(horzcat(0,0),horzcat(360,0));
            min_ant_loss=0;
        else
            [radar_ant_array]=horizontal_antenna_loss_app(app,radar_beamwidth,min_ant_loss);
            %%%%%%%%%%%Note, this is not STATGAIN
        end

        %%%%%%%%%%%%%%%%Calculate the simualation azimuths
        [array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev2_360_app(app,radar_beamwidth);


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
        for mc_iter=1:1:mc_size
            mc_iter
            %%%%%%%Generate 1 MC Iteration
            [sort_monte_carlo_pr_dBm]=monte_carlo_Pr_dBm_rev1_app(app,rand_seed1,mc_iter,move_list_reliability,sort_full_Pr_dBm);


            if length(reliability)==1 %%%%%%%This assume 50%
                if ~all(sort_full_Pr_dBm==sort_monte_carlo_pr_dBm)
                    'Error:Pr dBm Mismatch '
                    pause;
                end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Move List for Single MC Iteration
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%Preallocate
            azimuth_turn_off_size=NaN(num_sim_azi,1);
            for azimuth_idx=1:1:num_sim_azi

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
                    'NaN Error: temp_mc_dBm'
                    pause;
                end

                %%%%%%Convert to Watts, Sum, and Find Aggregate
                %%%pow2db(0.1*1000)=20, 0.1 Watts = 20dBm
                %%%db2pow(20)/1000=0.1, 20dBm = 0.1 Watts
                binary_sort_mc_watts=db2pow(sort_temp_mc_dBm)/1000; %%%%%%To be used for the binary search

                if any(isnan(binary_sort_mc_watts))
                    'NaN Error: temp_mc_watts'
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
            move_list_turn_off_idx=move_list_turn_off_idx(~isnan(move_list_turn_off_idx))
            'Check the empty move_list_idx'
            pause;
        else
            move_list_turn_off_idx=1:1:turn_off_size95;
        end
    end

    if isempty(move_list_turn_off_idx)==1
        'Empty move_list_turn_off_idx, need to change the code below for the check'
        pause;
    end


    %%%%%%%%%%%%The Unique Base Station ID and Turn Off Flag, so then
    %%%%%%%%%%%%it is just a simple write of the entire data to a excel
    %%%%%%%%%%%%sheet, with no extra data to be added.
    sorted_array_fed_azi_data=horzcat(vertcat(NaN(1,1),sort_sim_array_list_bs(:,5)),vertcat(array_sim_azimuth,array_off_axis_loss_fed));
    array_sort_mc_dBm(move_list_turn_off_idx,end+1)=1;
    sorted_array_mc_pr_dbm=horzcat(vertcat(NaN(1,1),sort_sim_array_list_bs(:,5)),vertcat(horzcat(array_sim_azimuth,NaN(1,1)),array_sort_mc_dBm));

    move_sort_sim_array_list_bs=sort_sim_array_list_bs(move_list_turn_off_idx,:);

% % % % %         size(sorted_array_fed_azi_data)
% % % % %         size(sorted_array_mc_pr_dbm)
% % % % % 
% % % % %         sorted_array_fed_azi_data([1:2],[1:10])
% % % % %         sorted_array_mc_pr_dbm([1:2],[1:10])
% % % % % 
% % % % %         'Why the discrepency in memory? Digits'
% % % % %         pause;



    [num_tx_full,~]=size(sort_sim_array_list_bs);
    if max(move_list_turn_off_idx)>num_tx_full
        %%%%%%%%For Some Reason, the idx are too
        %%%%%%%%large, we should not get this error
        'Error Move list too large'
        pause;
    else %%%%%%Save the move list
        %%%%%Save master_turn_off_idx, Persistent Save
        retry_save=1;
        while(retry_save==1)
            try
                save(filename_move_sort_sim_array_list_bs,'move_sort_sim_array_list_bs')
                save(movelist_file_name,'move_list_turn_off_idx') %%%%%%These are the index of the sort_sim_array_list_bs
                save(sorted_array_fed_azi_data_file_name,'sorted_array_fed_azi_data')
                save(sorted_array_mc_pr_dbm_file_name,'sorted_array_mc_pr_dbm')
       
                retry_save=0;
            catch
                retry_save=1;
                pause(1)
            end
        end
    end
    toc;
end

end %%%%%%%%Of Function