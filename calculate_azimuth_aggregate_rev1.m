function [sorted_agg_pr_dBm]=calculate_azimuth_aggregate_rev1(app,radar_beamwidth,min_ant_loss,base_protection_pts,point_idx,sim_array_list_bs,sort_bs_idx,norm_aas_zero_elevation_data,temp_sort_pathloss)




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
                        sort_bs_azimuth=azimuth(sim_pt(1),sim_pt(2),sim_array_list_bs(sort_bs_idx,1),sim_array_list_bs(sort_bs_idx,2));
                            %%%%%%%Take into consideration the sector/azimuth off-axis gain
                        [sort_bs_azi_gain,~]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,sim_array_list_bs(sort_bs_idx,:),norm_aas_zero_elevation_data);  %%%%Sorted

                        [~,num_col]=size(temp_sort_pathloss)
                        if num_col>1
                            'Need to cut temp_sort_pathloss'
                            pause;
                        else
                            sort_temp_pr_dbm=sim_array_list_bs(sort_bs_idx,4)-temp_sort_pathloss+sort_bs_azi_gain;  %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System  %%%%%%%%%Sorted
                        end
                                              

                        [num_tx,~]=size(sim_array_list_bs);
                        temp_Pr_watts_azi=NaN(num_tx,num_sim_azi);
                        for azimuth_idx=1:1:num_sim_azi
                            %%%Find CBSD azimuths outside of +/- of half_ant_hor_deg of temp_azimuth
                            sim_azimuth=array_sim_azimuth(azimuth_idx);

                            %%%%%%%Calculate the loss due to off axis in the horizontal direction
                            [sort_off_axis_loss]=calc_off_axix_loss_rev1_app(app,sim_azimuth,sort_bs_azimuth,radar_ant_array,min_ant_loss);
                            sort_temp_Pr_dBm_azi=sort_temp_pr_dbm-sort_off_axis_loss;

                            %%%%%%Convert to Watts
                            %%%pow2db(0.1*1000)=20, 0.1 Watts = 20dBm
                            %%%db2pow(20)/1000=0.1, 20dBm = 0.1 Watts
                            temp_Pr_watts=db2pow(sort_temp_Pr_dBm_azi)/1000;
                            temp_Pr_watts_azi(:,azimuth_idx)=temp_Pr_watts;
                        end


                        size(temp_Pr_watts_azi)  %%%%%%%%%Sorted
                        sorted_agg_pr_dBm=NaN(size(temp_Pr_watts_azi));
                        tic;
                        for row_idx=1:1:num_tx
                            %%%%Calculate all Aggregate Power
                            iteration_agg_watts=sum(temp_Pr_watts_azi,"omitnan");
                            %size(iteration_agg_watts)

                            %%%%%%%%%Convert to dBm
                            %%%%%%Convert to Watts, Sum, and Find Aggregate
                            %%%pow2db(0.1*1000)=20, 0.1 Watts = 20dBm
                            %%%db2pow(20)/1000=0.1, 20dBm = 0.1 Watts
                            %%%%Re-calculate Aggregate Power for each azimuth
                            sorted_agg_pr_dBm(row_idx,:)=pow2db(iteration_agg_watts*1000);

                            %%%%%%%%%Set the top row to 0 watts
                            temp_Pr_watts_azi(row_idx,:)=0; %%%%%Index to set power to 0 watts
                        end
                        toc; %%%%%%%

end