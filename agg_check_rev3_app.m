function [array_agg_check_mc_dBm,array_agg_check_percentile]=agg_check_rev3_app(app,agg_check_reliability,point_idx,sim_number,agg_check_mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,agg_check_mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,off_idx,min_azimuth,max_azimuth,temp_miti)

%%%Function agg check rev 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Agg Check Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
agg_check_file_name=strcat(string_prop_model,'_array_agg_check_mc_dBm_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(agg_check_mc_size),'_',num2str(agg_check_mc_percentile),'_',num2str(temp_miti),'.mat');
[var_exist_agg_check]=persistent_var_exist_with_corruption(app,agg_check_file_name);

agg_percentile_file_name=strcat(string_prop_model,'_array_agg_check_percentile_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(agg_check_mc_size),'_',num2str(agg_check_mc_percentile),'_',num2str(temp_miti),'.mat');
[var_exist_agg_percentile]=persistent_var_exist_with_corruption(app,agg_percentile_file_name);



if var_exist_agg_check==2 && var_exist_agg_percentile==2
    %%%%%%%%%%%load
    retry_load=1;
    while(retry_load==1)
        try
            load(agg_check_file_name,'array_agg_check_mc_dBm')
            temp_data=array_agg_check_mc_dBm;
            clear array_agg_check_mc_dBm;
            array_agg_check_mc_dBm=temp_data;
            clear temp_data;

            load(agg_percentile_file_name,'array_agg_check_percentile')
            temp_data=array_agg_check_percentile;
            clear array_agg_check_percentile;
            array_agg_check_percentile=temp_data;
            clear temp_data;

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

    %%%%%%%% Cut the reliabilities that we will use for the aggregate check
    [pathloss]=trim_pathloss_reliability_rev1(app,pathloss,agg_check_reliability,reliability,string_prop_model);

    %%%%%%%%%Cut the pathloss from those on
    size(pathloss)
    pathloss(off_idx,:)=[];  %%%%%%%Cut off_idx
    size(pathloss)

    %%%%%%%Take into consideration the sector/azimuth off-axis gain
    [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,on_list_bs,norm_aas_zero_elevation_data);
    %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel

    tic;
    on_full_Pr_dBm=on_list_bs(:,4)-pathloss(:,:)+bs_azi_gain; %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System
    toc;
    size(on_full_Pr_dBm)

    if any(isnan(bs_azi_gain))
        find(isnan(bs_azi_gain))
        disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check: NaN error on bs_azi_gain'))
        pause;
    end

    if any(isnan(pathloss))
        find(isnan(pathloss))
        disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check: NaN error on pathloss'))
        pause;
    end

    if any(isnan(on_full_Pr_dBm))
        on_full_Pr_dBm
        %find(isnan(sort_full_Pr_dBm(:,1)))
        disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check: NaN error on on_full_Pr_dBm'))
        pause;
    end


    if isempty(on_full_Pr_dBm)
        disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check: Empty on_full_Pr_dBm, cant calculate aggrgate'))
        array_agg_check=NaN(1,1);
        %pause;
    else
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%This is where we put the Generalized Agg Check

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

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Each Base Station Azimuth
        sim_pt=base_protection_pts(point_idx,:);
        bs_azimuth=azimuth(sim_pt(1),sim_pt(2),on_list_bs(:,1),on_list_bs(:,2));

        %%%%%%%%%Need to calculate the off-axis
        %%%%%%%%%gain when we take

        %%%%%%%%Rand Seed1 for MC Iterations and Move List Calculation
        tempx=ceil(rand(1)*agg_check_mc_size);
        tempy=ceil(rand(1)*agg_check_mc_size);
        rand_seed1=tempx+tempy;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%Generate MC Iterations and Calculate Move List
        %%%Preallocate
        array_agg_check_mc_dBm=NaN(agg_check_mc_size,num_sim_azi);
        [num_tx,~]=size(on_list_bs);


        % disp_progress(app,strcat('Inside Agg Check Rev1: Line 126: Starting the MC'))
        %%%array_off_axis_loss_fed=NaN(num_tx,num_sim_azi);%%%%%Export this in the excel file. Only do this for the first monte carlo iteration
        %%%%array_sort_mc_dBm=NaN(num_tx,num_sim_azi);%%%%%Export this in the excel file. Only do this for the first monte carlo iteration
        for mc_iter=1:1:agg_check_mc_size
            %disp_progress(app,strcat('Inside Agg Check Rev1: Line 130:  MC:',num2str(mc_iter)))
            mc_iter
            %%%%%%%Generate 1 MC Iteration
            [sort_monte_carlo_pr_dBm]=monte_carlo_Pr_dBm_rev1_app(app,rand_seed1,mc_iter,agg_check_reliability,on_full_Pr_dBm);


            if length(reliability)==1 %%%%%%%This assume 50%
                if ~all(on_full_Pr_dBm==sort_monte_carlo_pr_dBm)
                    disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check: Pr dBm Mismatch'))
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
                    'ERROR PAUSE: Inside Agg Check: NaN Error: temp_mc_watts'
                    pause;
                end

                mc_agg_dbm=pow2db(sum(binary_sort_mc_watts,"omitnan")*1000);
                azimuth_agg_dBm(azimuth_idx)=mc_agg_dbm;
            end
            array_agg_check_mc_dBm(mc_iter,:)=azimuth_agg_dBm; %%%%%%%%%%%max across all azimuths for a single MC iteration

        end

        size(array_agg_check_mc_dBm)
        size(array_agg_check_mc_dBm)
        array_agg_check_percentile=ceil(prctile(array_agg_check_mc_dBm,agg_check_mc_percentile));
        size(array_agg_check_percentile)

        % % % % figure;
        % % % % hold on;
        % % % % plot(array_agg_check_mc_dBm')
        % % % % plot(array_agg_check_percentile,'-b','LineWidth',3)
        % % % % grid on;
        % % % % pause;

        %%%%%Save master_turn_off_idx, Persistent Save
        %disp_progress(app,strcat('Inside Agg Check Rev1: Line 194: Saving array_agg_check_95'))
        retry_save=1;
        while(retry_save==1)
            try
                save(agg_check_file_name,'array_agg_check_mc_dBm')
                save(agg_percentile_file_name,'array_agg_check_percentile')
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