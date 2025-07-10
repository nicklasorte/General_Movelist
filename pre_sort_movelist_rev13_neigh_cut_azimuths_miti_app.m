function [cell_miti_list]=pre_sort_movelist_rev13_neigh_cut_azimuths_miti_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,array_mitigation,tf_opt,min_azimuth,max_azimuth,neighborhood_radius)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Move List Function with Neighborhoor Cut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check for Move List File, if none, save place holder
num_miti=length(array_mitigation);
move_sort_file_name_cell_miti=strcat(string_prop_model,'_cell_miti_move_sort_sim_array_list_bs_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(num_miti),'_',num2str(neighborhood_radius),'km.mat')
[var_exist_move_sort]=persistent_var_exist_with_corruption(app,move_sort_file_name_cell_miti);
if var_exist_move_sort==2
    %%%%%%%%%%%load
    retry_load=1;
    while(retry_load==1)
        try
            load(move_sort_file_name_cell_miti,'cell_miti_list')
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
    %disp_progress(app,strcat('Inside Pre_sort_ML_rev8 Line46: Loading Pathloss'))

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
    %disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line62: Cutting Reliabilities'))
    size(pathloss)
    [rel_first_idx]=nearestpoint_app(app,min(move_list_reliability),reliability);
    [rel_second_idx]=nearestpoint_app(app,max(move_list_reliability),reliability);
    if strcmp(string_prop_model,'TIREM')
        % % % % if TIREM, we wont cut the reliabilites because there are none to cut.
    else
        pathloss=pathloss(:,[rel_first_idx:rel_second_idx]);
    end
    size(pathloss)
    [pathloss]=fix_inf_pathloss_rev1(app,pathloss);


    %%%%'Cut the base stations and pathloss to be only within the search distance'
    %disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line75: Cutting Base Stations'))
    sim_pt=base_protection_pts(point_idx,:);
    bs_distance=deg2km(distance(sim_pt(1),sim_pt(2),sim_array_list_bs(:,1),sim_array_list_bs(:,2)));
    keep_idx=find(bs_distance<=neighborhood_radius);
    horzcat(length(bs_distance),length(keep_idx))

    %%%%%%%%Cut the pathloss
    pathloss=pathloss(keep_idx,:);
    size(pathloss)

    sim_array_list_bs=sim_array_list_bs(keep_idx,:);
    size(sim_array_list_bs)

    %%%%%%%%%%%%Might need to create the sorted list before we move into the move list calculation, a sort of step 1b.
    %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Unique ID
    %%%%%%Creating a sorted move list for each protection point is not optimial but it allows the calculations to be done in parallel.

    % % %     sim_array_list_bs(1,:)
    % % %     '1Lat'
    % % %     '2Lon'
    % % %     '7 azimuth sector'
    % % %     '6: NLCD 1-3'
    % % %

    %%%%%%%Take into consideration the sector/azimuth off-axis gain
    %disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line 102: Calculating Off Axis BS Gain'))
    [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
    %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel

    [mid_idx]=nearestpoint_app(app,50,move_list_reliability);
    mid_pathloss_dB=pathloss(:,mid_idx);
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


    %%%%%%%%For this first pass, no mitigations


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
        %%%[array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev2_360_app(app,radar_beamwidth);
        [array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth);


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
        num_miti=length(array_mitigation);
        if mc_size>1
            'Need to check the mc_size for greater than 1'
            pause;
        end

        cell_miti_list=cell(num_miti+1,5);  %%%%1)Move list with EIRP Change 2)IDX of sort 3)Mitigations, 4)Min IDX, 5)Max IDX
        %%%%%%%%%%%%The idx is the level that they can't operate at.
        rev_array_mitigation=fliplr(array_mitigation);
        for miti_idx=1:1:num_miti
            miti_idx
            %%%%%%%%%%Apply Mitigation here
            temp_miti_dB=rev_array_mitigation(miti_idx)
            sort_full_Pr_dBm_miti=sort_full_Pr_dBm-temp_miti_dB; %%%%%%%%Apply current mitigations to all base stations.
            if miti_idx>1
                %%%%%%%%%%%%%%%%Apply Past mitigations
                for miti_row_idx=1:1:(miti_idx-1)
                    temp_uni_miti_idx=cell_miti_list{miti_row_idx,2};

                    [~,num_col]=size(sort_full_Pr_dBm);
                    if num_col>1
                        'Need to check for larger'
                        pause;
                    end
                    if miti_row_idx==1
                        %%%These are turned off
                        sort_full_Pr_dBm_miti(temp_uni_miti_idx)=sort_full_Pr_dBm(temp_uni_miti_idx)-99999; %%%%%Off
                    else
                        %%%%Apply the past mitigations
                        past_miti_dB=cell_miti_list{miti_row_idx-1,3};
                        sort_full_Pr_dBm_miti(temp_uni_miti_idx)=sort_full_Pr_dBm(temp_uni_miti_idx)-past_miti_dB;
                    end
                end
                %%%%%%%%%%%%%We are setting it to
                %%%%%%%%%%%%%the max, since we
                %%%%%%%%%%%%%typically set it to 0

                %%%%%%Empty problem
                temp_cell_max_idx=cell_miti_list(:,5);
                temp_cell_max_idx=temp_cell_max_idx(~cellfun('isempty',temp_cell_max_idx));
                low_idx=max(cell2mat(temp_cell_max_idx));
            else
                low_idx=0;
            end


            %diff(horzcat(sort_full_Pr_dBm_miti(1:100),sort_full_Pr_dBm(1:100)),1,2)
            unique(diff(horzcat(sort_full_Pr_dBm_miti,sort_full_Pr_dBm),1,2))
            % if miti_idx>4
            %     'check'
            %     pause;
            % end

            for mc_iter=1:1:mc_size
                mc_iter
                %%%%%%%Generate 1 MC Iteration
                [sort_monte_carlo_pr_dBm]=monte_carlo_Pr_dBm_rev1_app(app,rand_seed1,mc_iter,move_list_reliability,sort_full_Pr_dBm_miti);

                if length(reliability)==1 %%%%%%%This assume 50%
                    if ~all(sort_full_Pr_dBm_miti==sort_monte_carlo_pr_dBm)
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

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Binary Search

                    %%%%%%%%%%Input is lo_idx to
                    %%%%%%%%%%not affect the
                    %%%%%%%%%%previous mitigations

                    %[mid]=pre_sort_binary_movelist_rev2_app(app,radar_threshold,binary_sort_mc_watts);
                    %function [mid]=pre_sort_binary_movelist_rev2_app(app,radar_threshold,binary_sort_mc_watts)
                    % %%%%%For Mitigation, we need to stay in dB
                    binary_sort_mc_dBm=sort_temp_mc_dBm;
                    [mid]=pre_sort_binary_miti_movelist_rev3_app(app,radar_threshold,binary_sort_mc_dBm,low_idx,miti_idx,rev_array_mitigation);
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
                %move_list_turn_off_idx=1:1:turn_off_size95;
                move_list_turn_off_idx=(low_idx+1):1:turn_off_size95;  %%%%%%%low_idx+1, since we set it to the last affected tx
            end

            if isempty(move_list_turn_off_idx)==1
                %'Empty move_list_turn_off_idx, need to change the code below for the check'
                move_sort_sim_array_list_bs=NaN(1,15);
                %%%move_sort_sim_array_list_bs(:,[1:15])=[]
                %%%%%
            else
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Save the full turn off list
                move_sort_sim_array_list_bs=sort_sim_array_list_bs(move_list_turn_off_idx,:);
                size(move_sort_sim_array_list_bs)
            end



            if miti_idx>1
                %%%%%%%%%%%%%%%%Find the Unique
                %cell_miti_list
                %cell_miti_list([1:1:(miti_idx-1)],2)
                temp_cell=cell_miti_list([1:1:(miti_idx-1)],2);
                temp_cell_size_before=cell2mat(cellfun(@size,temp_cell,'UniformOutput',false));
                for n = 1:length(temp_cell)
                    temp_cell{n} = reshape(temp_cell{n}, numel(temp_cell{n}),1);
                end
                %temp_cell
                temp_cell_size_after=cell2mat(cellfun(@size,temp_cell,'UniformOutput',false));
                %temp_cell{:}
                %vertcat(temp_cell{:})
                %%%cell2mat(temp_cell)
                all_past_idx=unique(vertcat(temp_cell{:}));
                %%%cell2mat(cell_miti_list([1:1:(miti_idx-1)],2))
                %%%all_past_idx=unique(cell2mat(cell_miti_list([1:1:(miti_idx-1)],2)));
                all_past_idx=all_past_idx(~isnan(all_past_idx));
            else
                all_past_idx=NaN(1,1);
                all_past_idx=all_past_idx(~isnan(all_past_idx));
            end

            if isempty(move_list_turn_off_idx)
                %%%'empty move_list_turn_off_idx'
                %move_list_setxor_idx=move_list_turn_off_idx;
                move_sort_sim_array_list_bs_setxor=sort_sim_array_list_bs(move_list_turn_off_idx,:);
            else
                %move_list_setxor_idx=setxor(all_past_idx,move_list_turn_off_idx)
                %move_sort_sim_array_list_bs_setxor=sort_sim_array_list_bs(move_list_setxor_idx,:);
                move_sort_sim_array_list_bs_setxor=sort_sim_array_list_bs(move_list_turn_off_idx,:);
                move_sort_sim_array_list_bs_setxor(:,4)=move_sort_sim_array_list_bs_setxor(:,4)-temp_miti_dB;
            end
            % cell_miti_list{miti_idx,1}=move_sort_sim_array_list_bs_setxor;
            % cell_miti_list{miti_idx,2}=move_list_setxor_idx;
            % cell_miti_list{miti_idx,3}=temp_miti_dB;
            % cell_miti_list{miti_idx,4}=min(move_list_setxor_idx);
            % cell_miti_list{miti_idx,5}=max(move_list_setxor_idx);



            if ~isempty(move_sort_sim_array_list_bs_setxor)
                if miti_idx==1
                    %%%These are turned off
                    move_sort_sim_array_list_bs_setxor(:,4)=move_sort_sim_array_list_bs_setxor(:,4)-99999; %%%%%Off
                else
                    %%%%%%%Use sort_full_Pr_dBm
                    %max(sort_sim_array_list_bs(:,4))
                    past_miti_dB=rev_array_mitigation(miti_idx-1);
                    move_sort_sim_array_list_bs_setxor(:,4)=sort_sim_array_list_bs(move_list_turn_off_idx,4)-past_miti_dB; %%%%What was the original EIRP?
                    %max(sort_sim_array_list_bs(move_list_turn_off_idx,4))
                    %move_sort_sim_array_list_bs_setxor
                    %'This should have the eirp that needs to be checked for the double aggregate check at the bottom, not what was turned off.'
                    %'check for fourth colum'
                end
            end

            cell_miti_list{miti_idx,1}=move_sort_sim_array_list_bs_setxor;
            cell_miti_list{miti_idx,2}=move_list_turn_off_idx;
            cell_miti_list{miti_idx,3}=temp_miti_dB;
            cell_miti_list{miti_idx,4}=min(move_list_turn_off_idx); %%%%%%Since we are changing this to be the low_idx
            cell_miti_list{miti_idx,5}=max(move_list_turn_off_idx);

            % array_turn_off_size
            % turn_off_size95
            % cell_miti_list

            % % % if miti_idx>6
            % % %     miti_idx
            % % %     'check the turn off'
            % % %     'starting here for miti_idx==6, line 1091.'
            % % %     pause;
            % % % end
        end

        %%%%%%%%%%%%%% 'Need to add a final column of those not turned off.'
        [num_bs,~]=size(sort_sim_array_list_bs)
        %%%all_past_idx=unique(cell2mat(cell_miti_list([1:1:(miti_idx)],2)));

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Fix for the concat error
        temp_cell=cell_miti_list([1:1:(miti_idx)],2);
        temp_cell_size_before=cell2mat(cellfun(@size,temp_cell,'UniformOutput',false));
        for n = 1:length(temp_cell)
            temp_cell{n} = reshape(temp_cell{n}, numel(temp_cell{n}),1);
        end
        %temp_cell
        temp_cell_size_after=cell2mat(cellfun(@size,temp_cell,'UniformOutput',false));
        %temp_cell{:}
        %vertcat(temp_cell{:})
        %%%cell2mat(temp_cell)
        all_past_idx=unique(vertcat(temp_cell{:}));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


        %%%%'Need to check format of cell for consistency'

        all_past_idx=all_past_idx(~isnan(all_past_idx));
        move_list_setxor_idx=setxor(all_past_idx,[1:1:num_bs]);
        move_sort_sim_array_list_bs_setxor=sort_sim_array_list_bs(move_list_setxor_idx,:);
        horzcat(max(sort_sim_array_list_bs(:,4)),max(move_sort_sim_array_list_bs_setxor(:,4)))
        cell_miti_list{end,1}=move_sort_sim_array_list_bs_setxor;
        cell_miti_list{end,2}=move_list_setxor_idx';
        cell_miti_list{end,3}=NaN(1,1);
        cell_miti_list{end,4}=min(move_list_setxor_idx);
        cell_miti_list{end,5}=max(move_list_setxor_idx);

        cell_miti_list


        %%%%%%Save the move list
        %%%%%Save master_turn_off_idx, Persistent Save
        retry_save=1;
        while(retry_save==1)
            try
                save(move_sort_file_name_cell_miti,'cell_miti_list')
                retry_save=0;
            catch
                retry_save=1;
                pause(1)
            end
        end

        % [num_rows,~]=size(cell_miti_list)
        % color_set=plasma(num_rows);
        % %%%%%%%%%%%%%%%%Original Linear Heat Map Color set
        % f1=figure;
        % for i=num_rows:-1:1
        %     temp_latlon=cell_miti_list{i,1};
        %     %geoplot(temp_latlon(:,1),temp_latlon(:,2),'o','Color',color_set(i,:))
        %     geoscatter(temp_latlon(:,1),temp_latlon(:,2),10,color_set(i,:),'filled');
        %     hold on;
        % end
        % h = colorbar;
        % ylabel(h, 'Margin [dB]')
        % colorbar_labels=cell2mat(cell_miti_list(:,3))
        % num_labels=length(colorbar_labels)*2+1;
        % cell_bar_label=cell(num_labels,1);
        % counter=0;
        % for miti_idx=2:2:num_labels
        %     counter=counter+1;
        %     if isnan(colorbar_labels(counter))
        %         cell_bar_label{miti_idx}=strcat(num2str(colorbar_labels(counter)));
        %     else
        %         cell_bar_label{miti_idx}=strcat(num2str(colorbar_labels(counter)),'dB');
        %     end
        % end
        % bar_tics=linspace(0,1,num_labels);
        % h = colorbar('Location','eastoutside','Ticks',bar_tics,'TickLabels',cell_bar_label);
        % colormap(f1,color_set)
        % grid on;
        % title({strcat('Mitigation Turnoff')})
        % pause(0.1)
        % %geobasemap landcover
        % geobasemap streets-light%landcover
        % f1.Position = [100 100 1200 900];
        % pause(1)
        % filename1=strcat('Miti_turnoff_',data_label1,'.png');
        % %saveas(gcf,char(filename1))
        % pause(1);
        % %%%close(f1)
    end
    toc;
end
%disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line 344: Finished'))