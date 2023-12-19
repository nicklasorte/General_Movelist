function [opt_multi_point_idx]=multi_point_near_opt_idx_rev1(app,temp_miti,string_prop_model,data_label1,sim_array_list_bs,radar_beamwidth,min_ant_loss,base_protection_pts,tf_calc_opt_sort,sim_number,reliability)


                    %%%%%%%The hard part is that if we have more than 1
                    %%%%%%%point, then the list to turn off devices will
                    %%%%%%%need to take into consideration all the pathloss
                    %%%%%%%for all the points, and then do the larger
                    %%%%%%%calculation similar to the "optimized" move
                    %%%%%%%list. For now, since there is only one point, we
                    %%%%%%%can keep pushing forward for now.

                    %%%%%%%%%%%The original single point function
                      %%%[opt_sort_bs_idx]=near_opt_sort_idx_string_prop_model_miti_rev3(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,min_ant_loss,sim_array_list_bs,base_protection_pts,temp_pr_dbm,string_prop_model,temp_miti);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Near-Optimal Move List Function Start
%%%%%%Not optimal when we do it separately for all protection points. But this allows us to calculate the protection points in parallel.
%%%%%%%%%%%%%%%%%%%%%%%%%%First create the pr_watts for all azimuths (similar to below)



[num_ppts,~]=size(base_protection_pts)
filename_opt_multi_point_idx=strcat(data_label1,'_',string_prop_model,'_opt_multi_point_idx_',num2str(temp_miti),'dB.mat');
[var_exist_opt_multi_point_idx]=persistent_var_exist_with_corruption(app,filename_opt_multi_point_idx);
if tf_calc_opt_sort==1
    var_exist_opt_multi_point_idx=0;
end

if var_exist_opt_multi_point_idx==2
    %%%%%%%%%%%load
    retry_load=1;
    while(retry_load==1)
        try
            load(filename_opt_multi_point_idx,'opt_multi_point_idx')
            retry_load=0;
        catch
            retry_load=1;
            pause(1)
        end
    end
else
    %%%%Need to load all the pathloss and create the pr_watts for the 50th

    [num_tx,~]=size(sim_array_list_bs)
    array_multi_point_pr_dBm=NaN(num_tx,num_ppts);
    for point_idx=1:1:num_ppts
        point_idx
        %%%%%%Persistent Load
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

        if all(isnan(sim_array_list_bs(:,7)))
            bs_azi_gain=0;
        else
            'Need to add azimuth'
            pause
            %%%%%%%Take into consideration the sector/azimuth off-axis gain
            %[bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
            %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel
        end

        [mid_idx]=nearestpoint_app(app,50,reliability);
        mid_pathloss_dB=pathloss(:,mid_idx);
        temp_pr_dbm=sim_array_list_bs(:,4)-mid_pathloss_dB+bs_azi_gain-temp_miti;  %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System
        array_multi_point_pr_dBm(:,point_idx)=temp_pr_dbm;
    end


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


    cell_temp_Pr_watts_azi=cell(num_ppts,1);
    for point_idx=1:1:num_ppts
        if num_ppts>1
            'Need to check the function below for multiple points specifically expanding the temp_Pr_watts_azi, which will be the (number of azimuths) X (number of points)'
            pause;
        end
        %%%%%%%%%%%%%%%%%%%%%%%Calculate Each Base Station Azimuth
        sim_pt=base_protection_pts(point_idx,:);
        non_sort_bs_azimuth=azimuth(sim_pt(1),sim_pt(2),sim_array_list_bs(:,1),sim_array_list_bs(:,2));

        temp_Pr_watts_azi=NaN(num_tx,num_sim_azi);
        for azimuth_idx=1:1:num_sim_azi
            %%%Find CBSD azimuths outside of +/- of half_ant_hor_deg of temp_azimuth
            sim_azimuth=array_sim_azimuth(azimuth_idx);

            %%%%%%%Calculate the loss due to off axis in the horizontal direction
            [off_axis_loss]=calc_off_axix_loss_rev1_app(app,sim_azimuth,non_sort_bs_azimuth,radar_ant_array,min_ant_loss);
            temp_Pr_dBm_azi=array_multi_point_pr_dBm(:,point_idx)-off_axis_loss;


            %%%%%%Convert to Watts
            %%%pow2db(0.1*1000)=20, 0.1 Watts = 20dBm
            %%%db2pow(20)/1000=0.1, 20dBm = 0.1 Watts
            temp_Pr_watts=db2pow(temp_Pr_dBm_azi)/1000;
            temp_Pr_watts_azi(:,azimuth_idx)=temp_Pr_watts;
        end
        cell_temp_Pr_watts_azi{point_idx}=temp_Pr_watts_azi;
    end

    multi_point_Pr_watts_azi=horzcat(cell_temp_Pr_watts_azi{:});
    size(multi_point_Pr_watts_azi)

    % %         %%%%%%%%%Calculate the optimized sorted move list for the multi_point_Pr_watts_azi matrix
    % %         %Find Highest Aggregate Interference Sector
    % %         %Find Strongest CBSD Contributing to that section
    % %         %Add that CBSD to the opt_sorted_move_list
    % %         %Recalculate all Aggregate Interference

    opt_multi_point_idx=NaN(num_tx,1); %%%%%%%%Preallocate
    tic;
    for tx_idx=1:1:num_tx
        %%%%clc;
        tx_idx/num_tx*100
        %%%%Calculate all Aggregate Power
        iteration_agg_watts=sum(multi_point_Pr_watts_azi,"omitnan");
        %%%%size(iteration_agg_watts)

        [~,temp_azi_idx]=max(iteration_agg_watts); %%%%% Index of azimuth with highest Aggregate Power

        %Find Strongest CBSDs Contributing to that sector and turn off
        temp_max_azi_watts=multi_point_Pr_watts_azi(:,temp_azi_idx);
        %size(temp_max_azi_watts)
        [~,temp_max_idx]=max(temp_max_azi_watts);
        multi_point_Pr_watts_azi(temp_max_idx,:)=0; %Index to set power to 0 watts
        opt_multi_point_idx(tx_idx)=temp_max_idx;
    end
    toc; %%%%%%%3 seconds for a single point and a single azimuth, typically 88 Seconds for a single point and 100+ azimuths

    %%%%%%%%%%Save the order
    retry_save=1;
    while(retry_save==1)
        try
            save(filename_opt_multi_point_idx,'opt_multi_point_idx')
            retry_save=0;
        catch
            retry_save=1;
            pause(1)
        end
    end
end
end
