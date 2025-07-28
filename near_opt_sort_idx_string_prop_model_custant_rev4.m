function [opt_sort_bs_idx]=near_opt_sort_idx_string_prop_model_custant_rev4(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,single_search_dist,sim_array_list_bs,base_protection_pts,temp_pr_dbm,string_prop_model,custom_antenna_pattern,min_azimuth,max_azimuth)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Near-Optimal Move List Function Start
        %%%%%%Not optimal when we do it separately for all protection
        %%%%%%points. But this allows us to calculate the protection points
        %%%%%%in parallel.
        %%%%%%%%%%%%%%%%%%%%%%%%%%First create the pr_watts for all azimuths (similar to below)

        opt_sort_bs_idx_file_name=strcat(data_label1,'_',string_prop_model,'_opt_sort_bs_idx_',num2str(point_idx),'_',num2str(single_search_dist),'km.mat')
        [var_exist_opt_sort]=persistent_var_exist_with_corruption(app,opt_sort_bs_idx_file_name);
        if tf_calc_opt_sort==1
            var_exist_opt_sort=0;
        end

        if var_exist_opt_sort==2
            %%%%%%%%%%%load
            retry_load=1;
            while(retry_load==1)
                try
                    load(opt_sort_bs_idx_file_name,'opt_sort_bs_idx')
                    retry_load=0;
                catch
                    retry_load=1;
                    pause(1)
                end
            end
        else
            tic;
            %point_idx
            % % % %%%%%%%%%%Add Radar Antenna Pattern: Offset from 0 degrees and loss in dB
            % % % if radar_beamwidth==360
            % % %     radar_ant_array=vertcat(horzcat(0,0),horzcat(360,0));
            % % %     min_ant_loss=0;
            % % % else
            % % %     [radar_ant_array]=horizontal_antenna_loss_app(app,radar_beamwidth,min_ant_loss);
            % % %     %%%%%%%%%%%Note, this is not STATGAIN
            % % % end
            % % % 
            % % % %%%%%%%%%%%%%%%%Calculate the simualation azimuths
            % % % [array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev2_360_app(app,radar_beamwidth);

            %%%%%%%%%%%%%%%%Calculate the simualation azimuths
            [array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth);


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Each Base Station Azimuth
            sim_pt=base_protection_pts(point_idx,:);
            non_sort_bs_azimuth=azimuth(sim_pt(1),sim_pt(2),sim_array_list_bs(:,1),sim_array_list_bs(:,2));

            [num_tx,~]=size(sim_array_list_bs);
            temp_Pr_watts_azi=NaN(num_tx,num_sim_azi);
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

                % % fig1=figure;
                % % hold on;
                % % plot(custom_antenna_pattern(:,1),custom_antenna_pattern(:,2),'-ob','Linewidth',2)
                % % plot(shift_antpat(:,1),shift_antpat(:,2),'-xr')
                % % xlabel('Azimuth [Degree]')
                % % ylabel('Antenna Gain')
                % % grid on;
                % % pause(0.1)
                % % close(fig1)


                %%%%%%%Calculate the loss due to off axis in the horizontal direction
                %%%%[off_axis_loss]=calc_off_axix_loss_rev1_app(app,sim_azimuth,bs_azimuth,radar_ant_array,min_ant_loss);
                %%%%%%%%%%%%%%%%%%%%%%%Since we've already rotated the antenna pattern, just need to find the nearest bs_azimuth
                [ant_deg_idx]=nearestpoint_app(app,non_sort_bs_azimuth,shift_antpat(:,1));
                off_axis_gain=shift_antpat(ant_deg_idx,2);
                temp_Pr_dBm_azi=temp_pr_dbm+off_axis_gain;

                % % % % horzcat(temp_Pr_dBm_azi(1:10),temp_pr_dbm(1:10),off_axis_gain(1:10))
                % % % % 'check the off_axis_gain'
                % % % % pause;

                %%%%%%Convert to Watts
                %%%pow2db(0.1*1000)=20, 0.1 Watts = 20dBm
                %%%db2pow(20)/1000=0.1, 20dBm = 0.1 Watts
                temp_Pr_watts=db2pow(temp_Pr_dBm_azi)/1000;
                temp_Pr_watts_azi(:,azimuth_idx)=temp_Pr_watts;
            end

            % %         %%%%%%%%%Calculate the optimized sorted move list for the temp_Pr_watts_azi matrix
            % %         %Find Highest Aggregate Interference Sector
            % %         %Find Strongest CBSD Contributing to that section
            % %         %Add that CBSD to the opt_sorted_move_list
            % %         %Recalculate all Aggregate Interference

            opt_sort_bs_idx=NaN(num_tx,1); %%%%%%%%Preallocate
            tic;
            for i=1:1:num_tx
                %%%%clc;
                i/num_tx*100
                %%%%Calculate all Aggregate Power
                iteration_agg_watts=sum(temp_Pr_watts_azi,"omitnan");
                %%%%size(iteration_agg_watts)

                [~,temp_azi_idx]=max(iteration_agg_watts); %%%%% Index of azimuth with highest Aggregate Power

                %Find Strongest CBSDs Contributing to that sector and turn off
                temp_max_azi_watts=temp_Pr_watts_azi(:,temp_azi_idx);
                %size(temp_max_azi_watts)

                [~,temp_cbsd_idx]=max(temp_max_azi_watts);
                temp_Pr_watts_azi(temp_cbsd_idx,:)=0; %Index to set power to 0 watts
                opt_sort_bs_idx(i)=temp_cbsd_idx;
            end
            toc; %%%%%%%88 Seconds (Is it worth it?)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End of
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Near-Optimal Move
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%List order (Make
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%this pull the
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%last calculated)

            retry_save=1;
            while(retry_save==1)
                try
                    save(opt_sort_bs_idx_file_name,'opt_sort_bs_idx')
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(1)
                end
            end
        end
