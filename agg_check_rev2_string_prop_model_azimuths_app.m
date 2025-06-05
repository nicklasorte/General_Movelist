function [array_agg_check_95]=agg_check_rev2_string_prop_model_azimuths_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth)

 %disp_progress(app,strcat('Inside Agg Check Rev1: Line 3'))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Agg Check Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
agg_check_file_name=strcat(string_prop_model,'_array_agg_check_95_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
[var_exist_agg_check]=persistent_var_exist_with_corruption(app,agg_check_file_name);


if var_exist_agg_check==2
    %%%%%%%%%%%load
    retry_load=1;
    while(retry_load==1)
        try
            load(agg_check_file_name,'array_agg_check_95')
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
     %disp_progress(app,strcat('Inside Agg Check Rev1: Line 29: Loading Pathloss'))
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
    %disp_progress(app,strcat('Inside Agg Check Rev1: Line 44: Cutting Reliabilities'))
    size(pathloss)
    [rel_first_idx]=nearestpoint_app(app,min(agg_check_reliability),reliability);
    [rel_second_idx]=nearestpoint_app(app,max(agg_check_reliability),reliability);
    if strcmp(string_prop_model,'TIREM')
        % % % % if TIREM, we wont cut the reliabilites because there are none to cut.
    else
        pathloss=pathloss(:,[rel_first_idx:rel_second_idx]);
    end
    size(pathloss)
    min(pathloss)

    [pathloss]=fix_inf_pathloss_rev1(app,pathloss);

    %%%%%%%%%Cut the pathloss from those on
    pathloss(off_idx,:)=[];  %%%%%%%Cut off_idx
    size(pathloss)




    %%%%%%%Take into consideration the sector/azimuth off-axis gain
    [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,on_list_bs,norm_aas_zero_elevation_data);
    %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel

    tic;
    on_full_Pr_dBm=on_list_bs(:,4)-pathloss(:,:)+bs_azi_gain; %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System
    toc;

    if any(isnan(bs_azi_gain))
        find(isnan(bs_azi_gain))
         %disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev1: Line 70: NaN error on bs_azi_gain'))
        pause;
    end

    if any(isnan(pathloss))
        find(isnan(pathloss))
         %disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev1: Line 76: NaN error on pathloss'))
        pause;
    end

    if any(isnan(on_full_Pr_dBm))
        on_full_Pr_dBm
        %find(isnan(sort_full_Pr_dBm(:,1)))
        %disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev1: Line 83: NaN error on on_full_Pr_dBm'))
        'ERROR PAUSE: Inside Agg Check Rev1: Line 83: NaN error on on_full_Pr_dBm'
        pause;
    end


    if isempty(on_full_Pr_dBm)
        %disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev1: Line 89: Empty on_full_Pr_dBm, cant calculate aggrgate'))
        array_agg_check_95=NaN(1,1);
        'ERROR PAUSE: Inside Agg Check Rev1: Line 89: Empty on_full_Pr_dBm, cant calculate aggrgate'
        %pause;
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
        %%%[array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev2_360_app(app,radar_beamwidth);
        [array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Each Base Station Azimuth
        sim_pt=base_protection_pts(point_idx,:);
        bs_azimuth=azimuth(sim_pt(1),sim_pt(2),on_list_bs(:,1),on_list_bs(:,2));

        %%%%%%%%%Need to calculate the off-axis
        %%%%%%%%%gain when we take

        %%%%%%%%Rand Seed1 for MC Iterations and Move List Calculation
        tempx=ceil(rand(1)*mc_size);
        tempy=ceil(rand(1)*mc_size);
        rand_seed1=tempx+tempy;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%Generate MC Iterations and Calculate Move List
        %%%Preallocate
        array_agg_check_mc_dBm=NaN(mc_size,num_sim_azi);
        [num_tx,~]=size(on_list_bs);


        % disp_progress(app,strcat('Inside Agg Check Rev1: Line 126: Starting the MC'))
        %%%array_off_axis_loss_fed=NaN(num_tx,num_sim_azi);%%%%%Export this in the excel file. Only do this for the first monte carlo iteration
        %%%%array_sort_mc_dBm=NaN(num_tx,num_sim_azi);%%%%%Export this in the excel file. Only do this for the first monte carlo iteration
        for mc_iter=1:1:mc_size
            %disp_progress(app,strcat('Inside Agg Check Rev1: Line 130:  MC:',num2str(mc_iter)))
            mc_iter
            %%%%%%%Generate 1 MC Iteration
            [sort_monte_carlo_pr_dBm]=monte_carlo_Pr_dBm_rev1_app(app,rand_seed1,mc_iter,agg_check_reliability,on_full_Pr_dBm);


            if length(reliability)==1 %%%%%%%This assume 50%
                if ~all(on_full_Pr_dBm==sort_monte_carlo_pr_dBm)
                    min(pathloss)
                    disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev1: Line 138: Pr dBm Mismatch'))
                    pause;
                end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Move List for Single MC Iteration
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%Preallocate
            azimuth_agg_dBm=NaN(num_sim_azi,1);
            for azimuth_idx=1:1:num_sim_azi

                %%%Find CBSD azimuths outside of +/- of half_ant_hor_deg of temp_azimuth
                sim_azimuth=array_sim_azimuth(azimuth_idx);

                %%%%%%%Calculate the loss due to off axis in the horizontal direction
                [off_axis_loss]=calc_off_axix_loss_rev1_app(app,sim_azimuth,bs_azimuth,radar_ant_array,min_ant_loss);
                sort_temp_mc_dBm=sort_monte_carlo_pr_dBm-off_axis_loss;

                if any(isnan(sort_temp_mc_dBm))  %%%%%%%%Check
                     %disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev1: Line 158: NaN Error: temp_mc_dBm'))
                    pause;
                end

                %%%%%%Convert to Watts, Sum, and Find Aggregate
                %%%pow2db(0.1*1000)=20, 0.1 Watts = 20dBm
                %%%db2pow(20)/1000=0.1, 20dBm = 0.1 Watts
                binary_sort_mc_watts=db2pow(sort_temp_mc_dBm)/1000; %%%%%%

                if any(isnan(binary_sort_mc_watts))
                     %disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev1: Line 168: NaN Error: temp_mc_watts'))
                     'ERROR PAUSE: Inside Agg Check Rev1: Line 168: NaN Error: temp_mc_watts'
                    pause;
                end

                mc_agg_dbm=pow2db(sum(binary_sort_mc_watts,"omitnan")*1000);
                azimuth_agg_dBm(azimuth_idx)=mc_agg_dbm;
            end
            array_agg_check_mc_dBm(mc_iter,:)=azimuth_agg_dBm; %%%%%%%%%%%max across all azimuths for a single MC iteration

        end

        size(array_agg_check_mc_dBm)
        array_agg_check_95=prctile(array_agg_check_mc_dBm,mc_percentile);

% %                                                 figure;
% %                                                 hold on;
% %                                                 plot(array_agg_check_mc_dBm')
% %                                                 plot(array_agg_check_95,'-b','LineWidth',3)
% %                                                 grid on;
% % 
% %                                                 pause;




        %%%%%Save master_turn_off_idx, Persistent Save
        %disp_progress(app,strcat('Inside Agg Check Rev1: Line 194: Saving array_agg_check_95'))
        retry_save=1;
        while(retry_save==1)
            try
                save(agg_check_file_name,'array_agg_check_95')
                retry_save=0;
            catch
                retry_save=1;
                pause(1)
            end
        end

    end
    toc;
end
%disp_progress(app,strcat('Inside Agg Check Rev1: Line 209: Finished'))
end