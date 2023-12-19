function [full_agg_check_dBm]=full_sequential_agg_check_rev1(app,string_prop_model,mc_percentile,agg_check_reliability,point_idx,sim_number,mc_size,temp_miti,sim_array_list_bs,reliability,base_protection_pts,radar_beamwidth,min_ant_loss,data_label1,norm_aas_zero_elevation_data,opt_multi_point_idx)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Agg Check Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filename_full_agg_check_dBm=strcat(string_prop_model,'_full_agg_check_dBm_',num2str(mc_percentile),'_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(temp_miti),'dB.mat');
[var_exist_agg_check]=persistent_var_exist_with_corruption(app,filename_full_agg_check_dBm);


if var_exist_agg_check==2
    %%%%%%%%%%%load
    retry_load=1;
    while(retry_load==1)
        try
            load(filename_full_agg_check_dBm,'full_agg_check_dBm')
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


    %%%%%%%Take into consideration the sector/azimuth off-axis gain
    [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev2_no_bs_azi(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
    %%%%%%%%%%[bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
    %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel

    %%%%%'At some point we need to sort the list based on opt_multi_point_idx and sequentially calculate the aggregate, lean more into the move list code'
    tic;
    full_Pr_dBm=sim_array_list_bs(:,4)-pathloss(:,:)+bs_azi_gain-temp_miti; %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System
    sort_full_Pr_dBm=full_Pr_dBm(opt_multi_point_idx,:);
    sort_sim_array_list_bs=sim_array_list_bs(opt_multi_point_idx,:);
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

    if any(isnan(sort_full_Pr_dBm))
        sort_full_Pr_dBm
        %find(isnan(sort_full_Pr_dBm(:,1)))
        %disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev1: Line 83: NaN error on on_full_Pr_dBm'))
        pause;
    end


    if isempty(sort_full_Pr_dBm)
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

        [num_tx,~]=size(sort_sim_array_list_bs);
        %%%%full_agg_check_dBm=NaN(num_tx,1); %%%%%%%%%This will be the Max 95th Percentile Aggregate, where we sequentially remove one tx at a time. and this will be in the excel spreadsheet

        tic;
        %%%%%%%%%%%%%%Generate MC Iterations and Calculate Move List
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Preallocate
        %%%%%%array_agg_check_mc_dBm=NaN(mc_size,num_sim_azi);
        array_agg_check_mc_dBm=NaN(mc_size,num_sim_azi,num_tx); %%%100 MB at least {1000MC, 1 Azimuth, 12k Tx}
        for mc_iter=1:1:mc_size
            mc_iter
            %%%%%%%Generate 1 MC Iteration
            %%%tic;
            [sort_monte_carlo_pr_dBm]=monte_carlo_Pr_dBm_rev1_app(app,rand_seed1,mc_iter,agg_check_reliability,sort_full_Pr_dBm);
            %%%%toc;  %%%%0.0329 seconds for single MC randomization

            if length(reliability)==1 %%%%%%%This assume 50%
                if ~all(sort_full_Pr_dBm==sort_monte_carlo_pr_dBm)
                    pause;
                end
            end


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Move List for Single MC Iteration
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Preallocate
            %%%%%%%azimuth_agg_dBm=NaN(num_sim_azi,1);
            azimuth_agg_dBm=NaN(num_sim_azi,num_tx);
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
                sort_temp_mc_watts=db2pow(sort_temp_mc_dBm)/1000; %%%%%%

                if any(isnan(sort_temp_mc_watts))
                    %disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev1: Line 168: NaN Error: temp_mc_watts'))
                    pause;
                end

                %%%%%%%%First Try, for loop the
                %%%%%%%%tx right here, will
                %%%%%%%%need to save a lot of
                %%%%%%%%data

                %%%%This is where we start to cut the number of transmitters. It's hard to see where it might be the least computational intensive, maybe after the MC randomization

                %tic;
                for tx_idx=1:1:num_tx
                    if tx_idx==1
                        %%%%%Nothing set to 0 watts
                    else
                        sort_temp_mc_watts(1:1:[tx_idx-1])=0;  %%%%%%%%%%Set to 0 watts
                    end
                    mc_agg_dbm=pow2db(sum(sort_temp_mc_watts,"omitnan")*1000);
                    azimuth_agg_dBm(azimuth_idx,tx_idx)=mc_agg_dbm;
                end
                %toc;  %%%%%%0.156 seconds (This seems likely to be the quickest but the most memory intensive.)


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%This looks like a an inverse PDF
                % % %                                             figure;
                % % %                                             hold on;
                % % %                                             plot(azimuth_agg_dBm)

                % % %                                             mc_agg_dbm=pow2db(sum(sort_temp_mc_watts,"omitnan")*1000);
                % % %                                             azimuth_agg_dBm(azimuth_idx)=mc_agg_dbm;
            end
            array_agg_check_mc_dBm(mc_iter,:,:)=azimuth_agg_dBm; %%%%%%%For a single MC iteration

        end
        toc; %%%%%191 seconds {1000MC, 1 Azimuth, 12k Tx} (First try, inner Tx loop, (This seems likely to be the quickest but the most memory intensive.)

        size(array_agg_check_mc_dBm)


        %%%%%Need to check if we're doing this along the right dimension
        double_check=NaN(num_sim_azi,num_tx);
        for tx_idx=1:1:num_tx
            for azi_idx=1:1:num_sim_azi
                double_check(azi_idx,tx_idx)=prctile(array_agg_check_mc_dBm(:,azi_idx,tx_idx),mc_percentile);
            end
        end
        double_check=squeeze(double_check);
        double_check=double_check';
        squeeze_array_agg_check_mc_dBm=squeeze(array_agg_check_mc_dBm);
        size(squeeze_array_agg_check_mc_dBm)
        %%%array_agg_check_95=prctile(squeeze_array_agg_check_mc_dBm,mc_percentile); %%%%%%%%%%%%%%%%%%%This is not right for a single monte carlo iteration as we lost all the base stations loops
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%size(array_agg_check_95)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%full_agg_check_dBm=squeeze(array_agg_check_95);
        full_agg_check_dBm=double_check;


        %%%%%Save master_turn_off_idx, Persistent Save
        retry_save=1;
        while(retry_save==1)
            try
                save(filename_full_agg_check_dBm,'full_agg_check_dBm')
                retry_save=0;
            catch
                retry_save=1;
                pause(1)
            end
        end

    end
    toc;
end

end
