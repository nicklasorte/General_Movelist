function excel_print_empty_union_rev2(app,tf_print_excel,reliability,data_label1,mc_size,base_protection_pts,sim_array_list_bs,string_prop_model,sim_number,norm_aas_zero_elevation_data,radar_beamwidth,min_azimuth,max_azimuth,move_list_reliability,sim_radius_km,custom_antenna_pattern,dpa_threshold)

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Before we mark it complete, print the excel
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if tf_print_excel==1
                    num_rel=length(reliability)
                    if num_rel>1
                        'Need to update this with multiple reliabilities'
                        pause;
                    end
                 
                    %%%%%%%%%%%%Pull the neighborhood radius--> Union Move list --> Pathloss --> Excel
                    retry_load=1;
                    while(retry_load==1)
                        try
                            CBSD_label='BaseStation';
                            load(strcat(CBSD_label,'_',data_label1,'_catb_neighborhood_radius.mat'),'catb_neighborhood_radius')
                            temp_data=catb_neighborhood_radius;
                            clear catb_neighborhood_radius;
                            neighborhood_radius=temp_data;
                            clear temp_data;

                            retry_load=0;
                        catch
                            retry_load=1;
                            pause(0.1)
                        end
                    end

                    file_name_union_move=strcat(CBSD_label,'_union_turn_off_list_data_',num2str(mc_size),'_',num2str(neighborhood_radius),'km.mat');
                    [file_union_move_exist]=persistent_var_exist_with_corruption(app,file_name_union_move);
                    if file_union_move_exist==2
                        disp_progress(app,strcat('Neighborhood Calc Rev1: Line 237: Loading Union:',num2str(neighborhood_radius),'km'))
                        retry_load=1;
                        while(retry_load==1)
                            try
                                load(file_name_union_move,'union_turn_off_list_data')
                                retry_load=0;
                            catch
                                retry_load=1;
                                pause(1)
                            end
                        end
                    else
                        union_turn_off_list_data=NaN(1,5);
                        'Error: NO Union turn off list'
                        %pause;
                    end
                    

                    %%%Export the pathloss data, 1 sheet for each point
                    [num_sim_pts,~]=size(base_protection_pts)
                    if num_sim_pts>1
                        'More than 1 sim pts'
                        pause;
                    end
                    [num_tx,~]=size(sim_array_list_bs);
                    for point_idx=1:1:num_sim_pts

                        %%%%%%Load all the pathloss data
                        %%%%%%%%%'Load all the point pathloss calculations'
                        %%%%%%Persistent Load
                        file_name_pathloss=strcat(string_prop_model,'_pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
                        retry_load=1;
                        while(retry_load==1)
                            try
                                load(file_name_pathloss,'pathloss')
                                retry_load=0;
                            catch
                                retry_load=1;
                                'Having trouble loading pathloss . . .'
                                pause(1)
                            end
                        end

                        %%%%%%%Calculate Distance
                        sim_pt=base_protection_pts(point_idx,:);
                        bs_distance_km=deg2km(distance(sim_pt(1),sim_pt(2),sim_array_list_bs(:,1),sim_array_list_bs(:,2)));

                        [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'Calculate the antenna gain at Rx'
                        %%%%%%%%%%%%%%%%Calculate the simualation azimuths
                        [array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth);
                        % % if num_sim_azi>1
                        % %     'Need to expand the spreadsheet for multiple rx antenna rotations'
                        % %     pause;
                        % % end


                        [mid_idx]=nearestpoint_app(app,50,move_list_reliability);
                        mid_pathloss_dB=pathloss(:,mid_idx);
                        temp_pr_dbm=sim_array_list_bs(:,4)-mid_pathloss_dB+bs_azi_gain;  %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System
                        %%%%%%Need to do it twice, once for the sim
                        %%%%%%distance and another for the neighbohrood
                        %%%%%%distance (neighborhood_radius)

                        %%%%%%%%First for the sim_radius_km
                        tf_calc_opt_sort=0%1%0%1%0  %%%%%%%Load if it's been calculated before
                        [opt_sort_bs_idx,array_max_agg]=near_opt_sort_idx_string_prop_model_custant_rev4_agg_output(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,sim_radius_km,sim_array_list_bs,base_protection_pts,temp_pr_dbm,string_prop_model,custom_antenna_pattern,min_azimuth,max_azimuth);


                        % % figure;
                        % % hold on;
                        % % plot(array_max_agg,'-ok')
                        % % grid on;
                        % % pause(0.1)

                        delta_agg=diff(array_max_agg);
                        if max(delta_agg)>0
                            'Not optimum'
                            pause;
                        end

                        % figure;
                        % hold on;
                        % plot(delta_agg,'-ok')
                        % grid on;
                        % pause(0.1)

  
                        [num_tx,~]=size(sim_array_list_bs)
                        full_array_off_axis_gain=NaN(num_tx,num_sim_azi);
                        for azimuth_idx=1:1:num_sim_azi
                            %%%Find CBSD azimuths outside of +/- of half_ant_hor_deg of temp_azimuth
                            sim_azimuth=array_sim_azimuth(azimuth_idx);
                            circshift_antpat=custom_antenna_pattern;
                            circshift_antpat(:,1)=custom_antenna_pattern(:,1)+sim_azimuth; %%%%%%%Add the azimuth, then we don't have to worry about azimuth spacing on pattern
                            %%%%Then Mod
                            mod_ant_pat=mod(circshift_antpat(:,1),360);
                            circshift_antpat(:,1)=mod_ant_pat;

                            %%%%%%Now find the 0
                            nn_zero_azi_idx=nearestpoint_app(app,0,circshift_antpat(:,1));
                            [num_ele,~]=size(circshift_antpat);
                            shift_antpat=circshift(circshift_antpat,num_ele-nn_zero_azi_idx+1);
                            shift_antpat=table2array(unique(array2table(shift_antpat),'rows')); %%%%%%Only keep unique azimuth rows

                            %%%%%%Test to make sure 0 is first in array
                            nn_check_idx=nearestpoint_app(app,0,shift_antpat(:,1));
                            if nn_check_idx~=1
                                'Circ shift error'
                                pause;
                            end

                            bs_azimuth=azimuth(sim_pt(1),sim_pt(2),sim_array_list_bs(:,1),sim_array_list_bs(:,2));
                            [ant_deg_idx]=nearestpoint_app(app,bs_azimuth,shift_antpat(:,1));
                            off_axis_gain=shift_antpat(ant_deg_idx,2);
                            full_array_off_axis_gain(:,azimuth_idx)=off_axis_gain;                            
                        end

                        size(full_array_off_axis_gain)
                        max_off_axis_gain=max(full_array_off_axis_gain,[],2);
                        size(max_off_axis_gain)

                        % % % figure;
                        % % % hold on;
                        % % % plot(max_off_axis_gain)
                        % % % grid on;

                        %%%%%%%%%%%%%%%%%%%%%Calculate Power Received;
                        %array_rx_pwr=sim_array_list_bs(:,4)-pathloss+off_axis_gain+bs_azi_gain;
                        max_array_rx_pwr=sim_array_list_bs(:,4)-pathloss+max_off_axis_gain+bs_azi_gain;
                        % horzcat(array_rx_pwr(1:10),sim_array_list_bs(1:10,4),pathloss(1:10),off_axis_gain(1:10),bs_azi_gain(1:10))
                        % 'check'
                        % pause;

                        %%%%%%%%%%Make a table:
                        % %%%%%%%%1) Uni_Id
                        % %%%%%%%%2) BS_Latitude_DD
                        % %%%%%%%%3) BS_Longitude_DD
                        % %%%%%%%%4) BS_Height_m
                        % %%%%%%%%5) Fed_Latitude_DD
                        % %%%%%%%%6) Fed_Longitude_DD
                        % %%%%%%%%7) Fed_Height_m
                        % %%%%%%%%8) BS_EIRP_dBm
                        %%%%%%%%%%9) Path_Loss_dB
                        %%%%%%%%%10) Distance km
                        %%%%%%%%%11) Rx Ant Gain (dBi)
                        %%%%%%%%%12) Power Received dBm
                        %%%%%%%%%13) TF_off
                        %%%%%%%%%14) Aggregate
          
                        array_excel_data=horzcat(sim_array_list_bs(:,5),sim_array_list_bs(:,[1,2,3]),sim_pt.*ones(num_tx,1),sim_array_list_bs(:,[4]),pathloss,bs_distance_km,max_off_axis_gain,max_array_rx_pwr);
                        array_excel_data(:,13)=0;
                        array_excel_data(1:10,:)
                        sort_array_excel_data=array_excel_data(opt_sort_bs_idx,:);
                        sort_array_excel_data(:,14)=array_max_agg;
                        
                        %%%%%%%%%%Now find the turnoff
                        if isnan(union_turn_off_list_data(1,5))
                            bs_turnoff_idx=NaN(1,1);
                            bs_turnoff_idx=bs_turnoff_idx(~isnan(bs_turnoff_idx));
                        else
                            bs_turnoff_idx=union_turn_off_list_data(:,5);
                        end
                        nn_off_idx=nearestpoint_app(app,bs_turnoff_idx,sort_array_excel_data(:,1));
                        sort_nn_off_idx=sort(nn_off_idx);  %%%%%%%%%%%%%%%%%%%%%We don't need this sort, but I like to see them sequentially.
                        sort_array_excel_data(sort_nn_off_idx,13)=1;
                        sort_array_excel_data(1:10,:)
                        sort_array_excel_data(:,15)=dpa_threshold;%%%%.*ones(num_tx,1)
                        full_excel_data=sort_array_excel_data;

                        table_excel_data=array2table(full_excel_data);
                        table_excel_data.Properties.VariableNames={'Uni_Id' 'BS_Latitude_DD' 'BS_Longitude_DD' 'BS_Height_m' 'Fed_Latitude_DD' 'Fed_Longitude_DD' 'Fed_Height_m' 'BS_EIRP_dBm' 'Path_Loss_dB' 'Distance_km' 'Max_Rx_Ant_Gain' 'Max_Rx_Pwr'  'TF_off' 'Aggregate_dBm'  'Interference_Threshold'}
                        disp_progress(app,strcat('Writing Excel File . . . '))
                        tic;
                        retry_save=1;
                        while(retry_save==1)
                            try
                                writetable(table_excel_data,strcat('FULL_',data_label1,'_Point',num2str(point_idx),'_',string_prop_model,'_Rev',num2str(sim_number),'.xlsx'));
                                pause(0.1);
                                retry_save=0;
                            catch
                                retry_save=1;
                                pause(0.1)
                            end
                        end
                        toc;  %%%%%%A few seconds


                        %%%%%%%%%%%%%%%%%%Now cut all that are outside the neighborhood
                        keep_idx=find(bs_distance_km<=neighborhood_radius);
                        keep_sim_array_list_bs=sim_array_list_bs(keep_idx,:);
                        keep_temp_pr_dbm=temp_pr_dbm(keep_idx,:);

                        %%%%%%%%First for the neighborhood_radius
                        %%%%Need this input: sim_array_list_bs, temp_pr_dbm
                        neighborhood_radius
                        tf_calc_opt_sort=0%1%0%1%0  %%%%%%%Load if it's been calculated before
                        [neigh_opt_sort_bs_idx,neigh_array_max_agg]=near_opt_sort_idx_string_prop_model_custant_rev4_agg_output(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,neighborhood_radius,keep_sim_array_list_bs,base_protection_pts,keep_temp_pr_dbm,string_prop_model,custom_antenna_pattern,min_azimuth,max_azimuth);


                        % figure;
                        % hold on;
                        % plot(neigh_array_max_agg,'-ok')
                        % grid on;
                        % pause(0.1)
                        % 
                        % delta_agg=diff(neigh_array_max_agg);
                        % if max(delta_agg)>0
                        %     'Not optimum'
                        %     pause;
                        % end


                        keep_array_excel_data=horzcat(keep_sim_array_list_bs(:,5),keep_sim_array_list_bs(:,[1,2,3]),sim_pt.*ones(length(keep_idx),1),keep_sim_array_list_bs(:,[4]),pathloss(keep_idx),bs_distance_km(keep_idx),max_off_axis_gain(keep_idx),max_array_rx_pwr(keep_idx));
                        keep_array_excel_data(:,13)=0;
                        sort_keep_array_excel_data=keep_array_excel_data(neigh_opt_sort_bs_idx,:);
                        sort_keep_array_excel_data(:,14)=neigh_array_max_agg;  %%%%%%But this is sorted.


                        %%%%%%%%%%Now find the turnoff
                        if isnan(union_turn_off_list_data(1,5))
                            bs_turnoff_idx=NaN(1,1);
                            bs_turnoff_idx=bs_turnoff_idx(~isnan(bs_turnoff_idx));
                        else
                            bs_turnoff_idx=union_turn_off_list_data(:,5);
                        end
                        keep_nn_off_idx=nearestpoint_app(app,bs_turnoff_idx,sort_keep_array_excel_data(:,1));
                        sort_keep_nn_off_idx=sort(keep_nn_off_idx);  %%%%%%%%%%%%%%%%%%%%%We don't need this sort, but I like to see them sequentially.
                        sort_keep_array_excel_data(sort_keep_nn_off_idx,13)=1;
                        sort_keep_array_excel_data(:,15)=dpa_threshold;%%%%.*ones(num_tx,1)
                        keep_full_excel_data=sort_keep_array_excel_data;

   

                        %%%%%%%%%%Make a table:
                        % %%%%%%%%1) Uni_Id
                        % %%%%%%%%2) BS_Latitude_DD
                        % %%%%%%%%3) BS_Longitude_DD
                        % %%%%%%%%4) BS_Height_m
                        % %%%%%%%%5) Fed_Latitude_DD
                        % %%%%%%%%6) Fed_Longitude_DD
                        % %%%%%%%%7) Fed_Height_m
                        % %%%%%%%%8) BS_EIRP_dBm
                        %%%%%%%%%%9) Path_Loss_dB
                        %%%%%%%%%10) Distance km
                        %%%%%%%%%11) Rx Ant Gain (dBi)
                        %%%%%%%%%12) Power Received dBm
                        %%%%%%%%%13) TF_off
                        %%%%%%%%%14) Aggregate
                      
                        table_excel_keep_data=array2table(keep_full_excel_data);
                        table_excel_keep_data.Properties.VariableNames={'Uni_Id' 'BS_Latitude_DD' 'BS_Longitude_DD' 'BS_Height_m' 'Fed_Latitude_DD' 'Fed_Longitude_DD' 'Fed_Height_m' 'BS_EIRP_dBm' 'Path_Loss_dB' 'Distance_km' 'Max_Rx_Ant_Gain' 'Max_Rx_Pwr'  'TF_off' 'Aggregate_dBm'  'Interference_Threshold'}
                        disp_progress(app,strcat('Writing Excel File . . . '))
                        tic;
                        retry_save=1;
                        while(retry_save==1)
                            try
                                writetable(table_excel_keep_data,strcat('Neighborhood_',data_label1,'_Point',num2str(point_idx),'_',string_prop_model,'_Rev',num2str(sim_number),'.xlsx'));
                                pause(0.1);
                                retry_save=0;
                            catch
                                retry_save=1;
                                pause(0.1)
                            end
                        end
                        toc;  %%%%%%A few seconds
                    end
                end

end