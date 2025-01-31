function [off_list_bs,mitigation_list_bs,mitigation_sort_sim_array_list_bs,mitigation_sort_bs_idx]=pre_sort_mitigation_movelist_new_AAS_rev8_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model)




%%%%%%%%%Check for Move List File, if none, save place holder
off_list_bs_file_name=strcat(string_prop_model,'_miti_off_list_bs_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'.mat');
mitigation_list_bs_file_name=strcat(string_prop_model,'_miti_mitigation_list_bs_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'.mat');

%%%%%The sort_idx might change if 50% is not included in the move_list_reliability
if isempty(find(move_list_reliability==50))
    'The sort_idx might change if 50% is not included in the move_list_reliability, need to update the filenames.'
    pause;
end

mitigation_sort_bs_idx_file_name=strcat(data_label1,'_',string_prop_model,'_mitigation_sort_bs_idx_',num2str(point_idx),'.mat');
mitigation_sort_sim_array_file_name=strcat(data_label1,'_',string_prop_model,'_mitigation_sort_sim_array_list_bs_',num2str(point_idx),'.mat');

[var_exist_off_list]=persistent_var_exist(app,off_list_bs_file_name);
[var_exist_mitigation_list]=persistent_var_exist(app,mitigation_list_bs_file_name);
[var_exist_sort_idx]=persistent_var_exist(app,mitigation_sort_bs_idx_file_name);
[var_exist_sim_array]=persistent_var_exist(app,mitigation_sort_sim_array_file_name);

if var_exist_off_list==2 && var_exist_mitigation_list==2 && var_exist_sort_idx==2 && var_exist_sim_array==2
    %%%%%%%%%%%load
    retry_load=1;
    while(retry_load==1)
        try
            load(mitigation_sort_bs_idx_file_name,'mitigation_sort_bs_idx')
            load(mitigation_sort_sim_array_file_name,'mitigation_sort_sim_array_list_bs')
            load(off_list_bs_file_name,'off_list_bs')
            load(mitigation_list_bs_file_name,'mitigation_list_bs')
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


    %%%%%%%Take into consideration the sector/azimuth off-axis gain
    %%%%%[bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
    [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev2(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
    %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel


    [mid_idx]=nearestpoint_app(app,50,move_list_reliability);
    mid_pathloss_dB=pathloss(:,mid_idx);
    %%%%temp_pr_dbm=sim_array_list_bs(:,4)-mid_pathloss_dB+bs_azi_gain;  %%%%%%%Non-Mitigation EIRPs ("Full" EIRP)
    temp_pr_dbm_mitigations=sim_array_list_bs(:,8)-mid_pathloss_dB+bs_azi_gain;  %%%%%%%%Mitigation EIRPs

    % % % % % %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Not optimized, but similar to what CBRS does.
    %%%%%%%%%%%%%Quite a bit quicker than the near-opt move list.
    % % % % % %     [~,sort_bs_idx]=sort(temp_pr_dbm,'descend'); %%%Sort power received at radar, and then this is the order of turn off.
    %%%%%%%[~,mitigation_sort_bs_idx]=sort(temp_pr_dbm_mitigations,'descend'); %%%Sort power received at radar, and then this is the order of turn off.

      
    %%%%%%%%%'Need to change the name of the opt_sort_idx so it doesnt overwrite the non-mitigation version'
    %%%strcat(data_label1,'_mitigation')

    tf_calc_opt_sort=0  %%%%%%To be used to re-calculate.
                     %[opt_sort_bs_idx]=near_opt_sort_idx_rev1(app,strcat(data_label1,'_mitigation'),point_idx,tf_calc_opt_sort,radar_beamwidth,min_ant_loss,sim_array_list_bs,base_protection_pts,temp_pr_dbm_mitigations);
    [opt_sort_bs_idx]=near_opt_sort_idx_string_prop_model_rev2(app,strcat(data_label1,'_mitigation'),point_idx,tf_calc_opt_sort,radar_beamwidth,min_ant_loss,sim_array_list_bs,base_protection_pts,temp_pr_dbm_mitigations,string_prop_model);
    mitigation_sort_bs_idx=opt_sort_bs_idx; %%%%%%%%%%Use the "Near-Optimal Approach


    %%%%%%%These two might not be the same when we have a mix of commercial systems that have a different mitigation dB.
    %%%%%%%These two mitigations might be the same if it is all Randomized Real Base Stations with the same Mitigation dB constant across all Base Stations
% %     if ~all(sort_bs_idx==mitigation_sort_bs_idx)
% %         'Double check the mitigation move list since the ordered-lists are not identical'
% %         'We would expect this is the mitigation dBs are not constant across all transmitters'
% %         pause;
% %     end


    sort_full_Pr_dBm=sim_array_list_bs(mitigation_sort_bs_idx,4)-pathloss(mitigation_sort_bs_idx,:)+bs_azi_gain(mitigation_sort_bs_idx);
    mitigation_sort_sim_array_list_bs=sim_array_list_bs(mitigation_sort_bs_idx,:);
    mitigation_sort_full_Pr_dBm=sim_array_list_bs(mitigation_sort_bs_idx,8)-pathloss(mitigation_sort_bs_idx,:)+bs_azi_gain(mitigation_sort_bs_idx);

    %%%sort_full_Pr_dBm(1:10,:)'
    %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Unique ID
    %%%%%%%%%%%%%dual_array_sort_bs_idx=horzcat(sort_bs_idx,mitigation_sort_bs_idx); %%%%%%%1)Full Power Idx, 2)Mitigation Idx

    retry_save=1;
    while(retry_save==1)
        try
            save(mitigation_sort_bs_idx_file_name,'mitigation_sort_bs_idx')
            save(mitigation_sort_sim_array_file_name,'mitigation_sort_sim_array_list_bs')
            %%%%%%%%Just save
            retry_save=0;
        catch
            retry_save=1;
            pause(0.1)
        end
    end


% % %     %%%%%%%%%%%Check to see if it really is sorted
% % %     if issorted(mitigation_sort_full_Pr_dBm(:,mid_idx),'descend')==0
% % %         'Error: Not sorted'
% % %         pause;
% % %     end


    if isempty(sort_full_Pr_dBm) && isempty(mitigation_sort_full_Pr_dBm)
        off_list_bs=NaN(1,1);
        off_list_bs=off_list_bs(~isnan(off_list_bs));
        mitigation_list_bs=NaN(1,1);
        mitigation_list_bs=mitigation_list_bs(~isnan(mitigation_list_bs));
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
        bs_azimuth_mitigation=azimuth(sim_pt(1),sim_pt(2),mitigation_sort_sim_array_list_bs(:,1),mitigation_sort_sim_array_list_bs(:,2));

        %%%%%%%%%Need to calculate the off-axis gain when we take

        %%%%%%%%Rand Seed1 for MC Iterations and Move List Calculation
        tempx=ceil(rand(1)*mc_size);
        tempy=ceil(rand(1)*mc_size);
        rand_seed1=tempx+tempy;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % % % % % % % % % % % % % % % % % % % % % % % % Two Sequential Binary Searches (Probably not optimal in terms of minimum change to Base Stations)
        % % % % % % % % % % % % % % % % % % % % % % % % First Binary Search Find Mitigation Turnoff

        %%%%%%%%%%%%%%Generate MC Iterations and Calculate Move List
        %%%Preallocate
        array_turn_off_size=NaN(mc_size,1);
        [num_tx,~]=size(mitigation_sort_sim_array_list_bs);


        for mc_iter=1:1:mc_size
            mc_iter
            %%%%%%%Generate 1 MC Iteration
            [mitigation_sort_monte_carlo_pr_dBm]=monte_carlo_Pr_dBm_rev1_app(app,rand_seed1,mc_iter,move_list_reliability,mitigation_sort_full_Pr_dBm);

            if length(reliability)==1 %%%%%%%This assume 50%
                if ~all(mitigation_sort_full_Pr_dBm==mitigation_sort_monte_carlo_pr_dBm)
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
                [off_axis_loss]=calc_off_axix_loss_rev1_app(app,sim_azimuth,bs_azimuth_mitigation,radar_ant_array,min_ant_loss);
                mitigation_sort_temp_mc_dBm=mitigation_sort_monte_carlo_pr_dBm-off_axis_loss;

                if any(isnan(mitigation_sort_temp_mc_dBm))  %%%%%%%%Check
                    'NaN Error: temp_mc_dBm'
                    pause;
                end

                %%%%%%Convert to Watts, Sum, and Find Aggregate
                %%%pow2db(0.1*1000)=20, 0.1 Watts = 20dBm
                %%%db2pow(20)/1000=0.1, 20dBm = 0.1 Watts
                mitigation_binary_sort_mc_watts=db2pow(mitigation_sort_temp_mc_dBm)/1000; %%%%%%To be used for the binary search

                if any(isnan(mitigation_binary_sort_mc_watts))
                    'NaN Error: temp_mc_watts'
                    pause;
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Binary Search
                [off_mid]=pre_sort_binary_movelist_rev2_app(app,radar_threshold,mitigation_binary_sort_mc_watts);
                azimuth_turn_off_size(azimuth_idx)=off_mid;
            end
            array_turn_off_size(mc_iter)=max(azimuth_turn_off_size); %%%%%%%%%%%max across all azimuths for a single MC iteration
        end
        turn_off_size95=ceil(prctile(array_turn_off_size,mc_percentile)) %%%%This was interp between points, so need to ceiling it.

        if turn_off_size95==0
            move_list_turn_off_idx=NaN(1,1);
            move_list_turn_off_idx=move_list_turn_off_idx(~isnan(move_list_turn_off_idx))
            % % % % %                                         'Check the empty move_list_idx'
            % % % % %                                         pause;
        else
            move_list_turn_off_idx=1:1:turn_off_size95;
        end


        %%%%'Do we give it another name: move_list_turn_off_idx???'


        %%%%%%%%Second Binary Search: Keep Mitigation off, run with the full power to see which sites need to keep the mitigation EIRP and which can use the full EIRP
        %%%%%%%%Constant (lo in binary search)

    
        %%%%%%%%%%%%%%Generate MC Iterations and Calculate Move List
        %%%Preallocate
        mitigation_array_turn_off_size=NaN(mc_size,1);
        [num_tx,~]=size(mitigation_sort_sim_array_list_bs);

        for mc_iter=1:1:mc_size
            mc_iter
            %%%%%%%Generate 1 MC Iteration
            [mitigation_sort_monte_carlo_pr_dBm]=monte_carlo_Pr_dBm_rev1_app(app,rand_seed1,mc_iter,move_list_reliability,mitigation_sort_full_Pr_dBm);
            [full_eirp_sort_monte_carlo_pr_dBm]=monte_carlo_Pr_dBm_rev1_app(app,rand_seed1,mc_iter,move_list_reliability,sort_full_Pr_dBm);

            %%%%%%%%%%%The Binary Search finds the combination of mitigation EIRP and "full" EIRP

            if length(reliability)==1 %%%%%%%This assume 50%
                if ~all(mitigation_sort_full_Pr_dBm==mitigation_sort_monte_carlo_pr_dBm)
                    'Error:Pr dBm Mismatch '
                    pause;
                end

                if ~all(full_eirp_sort_monte_carlo_pr_dBm==sort_full_Pr_dBm)
                    'Error:Pr dBm Mismatch '
                    pause;
                end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Move List for Single MC Iteration
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%Preallocate
            mitigation_azimuth_turn_off_size=NaN(num_sim_azi,1);
            for azimuth_idx=1:1:num_sim_azi

                %%%Find CBSD azimuths outside of +/- of half_ant_hor_deg of temp_azimuth
                sim_azimuth=array_sim_azimuth(azimuth_idx);

                %%%%%%%Calculate the loss due to off axis in the horizontal direction
                [off_axis_loss]=calc_off_axix_loss_rev1_app(app,sim_azimuth,bs_azimuth_mitigation,radar_ant_array,min_ant_loss);
                mitigation_sort_temp_mc_dBm=mitigation_sort_monte_carlo_pr_dBm-off_axis_loss;
                full_eirp_sort_temp_mc_dBm=full_eirp_sort_monte_carlo_pr_dBm-off_axis_loss;

                if any(isnan(mitigation_sort_temp_mc_dBm))  %%%%%%%%Check
                    'NaN Error: mitigation_sort_temp_mc_dBm'
                    pause;
                end

                if any(isnan(full_eirp_sort_temp_mc_dBm))  %%%%%%%%Check
                    'NaN Error: full_eirp_sort_temp_mc_dBm'
                    pause;
                end

                %%%%%%Convert to Watts, Sum, and Find Aggregate
                %%%pow2db(0.1*1000)=20, 0.1 Watts = 20dBm
                %%%db2pow(20)/1000=0.1, 20dBm = 0.1 Watts
                mitigation_binary_sort_mc_watts=db2pow(mitigation_sort_temp_mc_dBm)/1000; %%%%%%To be used for the binary search
                full_eirp_binary_sort_mc_watts=db2pow(full_eirp_sort_temp_mc_dBm)/1000; %%%%%%To be used for the binary search

                if any(isnan(mitigation_binary_sort_mc_watts))
                    'NaN Error: mitigation_binary_sort_mc_watts'
                    pause;
                end

                if any(isnan(full_eirp_binary_sort_mc_watts))
                    'NaN Error: full_eirp_binary_sort_mc_watts'
                    pause;
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Binary Search
                [mitigation_mid]=pre_sort_binary_movelist_mitigations_rev3_app(app,move_list_turn_off_idx,mitigation_binary_sort_mc_watts,full_eirp_binary_sort_mc_watts,turn_off_size95,radar_threshold);
                mitigation_azimuth_turn_off_size(azimuth_idx)=mitigation_mid;
            end
            mitigation_array_turn_off_size(mc_iter)=max(mitigation_azimuth_turn_off_size); %%%%%%%%%%%max across all azimuths for a single MC iteration
        end
        mitigation_turn_off_size95=ceil(prctile(mitigation_array_turn_off_size,mc_percentile)) %%%%This was interp between points, so need to ceiling it.
        %%%%%%%%%%%%%%This mitigation size also includes the turn-off
        %%%%%%%%%%Don't be throw off by the size95 label


        if mitigation_turn_off_size95==0
            mitigation_move_list_turn_off_idx=NaN(1,1);
            mitigation_move_list_turn_off_idx=mitigation_move_list_turn_off_idx(~isnan(mitigation_move_list_turn_off_idx))
        else
            if isempty(move_list_turn_off_idx)
                mitigation_move_list_turn_off_idx=1:1:mitigation_turn_off_size95;
            else
                mitigation_move_list_turn_off_idx=max(move_list_turn_off_idx)+1:1:mitigation_turn_off_size95;
            end
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%This will be one of the outputs
        off_list_bs=mitigation_sort_sim_array_list_bs(move_list_turn_off_idx,:); %%%%%Need to turn off even if mitigations are used.
        mitigation_list_bs=mitigation_sort_sim_array_list_bs(mitigation_move_list_turn_off_idx,:); %%%%%%%%Need to use the mitigations

        % %                                     close all;
        % %                                     figure;
        % %                                     hold on;
        % %                                     plot(sim_pt(2),sim_pt(1),'ob','LineWidth',3)
        % %                                     plot(mitigation_list_bs(:,2),mitigation_list_bs(:,1),'dm','LineWidth',2)
        % %                                     plot(off_list_bs(:,2),off_list_bs(:,1),'sr','LineWidth',2)
        % %
        % %                                     grid on;
        % %                                     plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com

        % % %                                     filename1=strcat('Sim_Area_Deployment_',data_label1,'.png');
        % % %                                     pause(0.1)
        % % %                                     saveas(gcf,char(filename1))
        [num_tx_full,~]=size(mitigation_sort_sim_array_list_bs);
        if ~isempty(mitigation_move_list_turn_off_idx)

            if max(mitigation_move_list_turn_off_idx)>num_tx_full
                %%%%%%%%For Some Reason, the idx are too
                %%%%%%%%large, we should not get this error
                'Error Move list too large'
                pause;
            end
        end

    end


    
    %%%%%%Save the move list
    %%%%%Save master_turn_off_idx, Persistent Save
    retry_save=1;
    while(retry_save==1)
        try
            save(off_list_bs_file_name,'off_list_bs')
            save(mitigation_list_bs_file_name,'mitigation_list_bs')
            retry_save=0;
        catch
            retry_save=1;
            pause(1)
        end
    end
    toc;
end


end