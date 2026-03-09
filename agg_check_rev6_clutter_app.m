function [array_agg_check_95,array_agg_check_mc_dBm]=agg_check_rev6_clutter_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth,custom_antenna_pattern,bs_eirp_dist,cell_aas_dist_data,cell_sim_data,sim_folder)

%%%%%Input validation
if isempty(agg_check_reliability) || ~isnumeric(agg_check_reliability)
    disp_progress(app,'ERROR PAUSE: agg_check_rev6_clutter_app: agg_check_reliability is empty or non-numeric')
    pause;
end
if isempty(base_protection_pts) || ~isnumeric(base_protection_pts)
    disp_progress(app,'ERROR PAUSE: agg_check_rev6_clutter_app: base_protection_pts is empty or non-numeric')
    pause;
end
if isempty(on_list_bs) || ~isnumeric(on_list_bs)
    disp_progress(app,'ERROR PAUSE: agg_check_rev6_clutter_app: on_list_bs is empty or non-numeric')
    pause;
end
if isempty(reliability) || ~isnumeric(reliability)
    disp_progress(app,'ERROR PAUSE: agg_check_rev6_clutter_app: reliability is empty or non-numeric')
    pause;
end
if isempty(custom_antenna_pattern) || ~isnumeric(custom_antenna_pattern)
    disp_progress(app,'ERROR PAUSE: agg_check_rev6_clutter_app: custom_antenna_pattern is empty or non-numeric')
    pause;
end
if isempty(cell_aas_dist_data) || ~iscell(cell_aas_dist_data)
    disp_progress(app,'ERROR PAUSE: agg_check_rev6_clutter_app: cell_aas_dist_data is empty or not a cell')
    pause;
end
if ~isnumeric(mc_size) || ~isscalar(mc_size) || mc_size<1
    disp_progress(app,'ERROR PAUSE: agg_check_rev6_clutter_app: mc_size is invalid')
    pause;
end
if ~isnumeric(point_idx) || ~isscalar(point_idx) || point_idx<1
    disp_progress(app,'ERROR PAUSE: agg_check_rev6_clutter_app: point_idx is invalid')
    pause;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Agg Check Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
agg_check_file_name=strcat(string_prop_model,'_array_agg_check_95_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
[var_exist_agg_check]=persistent_var_exist_with_corruption(app,agg_check_file_name);

%%%%%%%%%Need to save the distribution also.
agg_dist_file_name=strcat(string_prop_model,'_array_agg_check_mc_dBm_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
[var_exist_agg_dist]=persistent_var_exist_with_corruption(app,agg_dist_file_name);

if var_exist_agg_check==2 && var_exist_agg_dist==2
    %%%%%%%%%%%load
    retry_load=1;
    while(retry_load==1)
        try
            load(agg_check_file_name,'array_agg_check_95')
            load(agg_dist_file_name,'array_agg_check_mc_dBm')
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

    file_name_clutter=strcat('P2108_clutter_loss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
    retry_load=1;
    while(retry_load==1)
        try
            load(file_name_clutter,'clutter_loss')
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

    %%%%%%%% Cut the reliabilities that we will use for the move list
    %size(clutter_loss)
    [rel_first_idx]=nearestpoint_app(app,min(agg_check_reliability),reliability);
    [rel_second_idx]=nearestpoint_app(app,max(agg_check_reliability),reliability);
    clutter_loss=clutter_loss(:,[rel_first_idx:rel_second_idx]);
    %size(clutter_loss)

    %%%%%%%%%Cut the pathloss and clutter from those on
    pathloss(off_idx,:)=[];  %%%%%%%Cut off_idx
    %size(clutter_loss)
    clutter_loss(off_idx,:)=[];  %%%%%%%Cut off_idx
    %size(clutter_loss)
    %size(pathloss)
    %size(on_list_bs)



    %%%%%%%Take into consideration the sector/azimuth off-axis gain
    [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,on_list_bs,norm_aas_zero_elevation_data);
    %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel

    tic;
    on_full_Pr_dBm=on_list_bs(:,4)-pathloss(:,:)+bs_azi_gain; %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System
    toc;

    %%%%%%%%%Adding clutter in monte carlo later

    %%%%%%%%%%We just have to make a new bs_eirp_dist based on the azimuth
    %%%%%%%%%%of the base station antenna offset to the federal point.
    array_aas_dist_data=cell_aas_dist_data{2};
    aas_dist_azimuth=cell_aas_dist_data{1};
    mod_azi_diff_bs=array_bs_azi_data(:,4);
    min(mod_azi_diff_bs)
    max(mod_azi_diff_bs)
    %%%%%%%%%Find the azimuth off-axis antenna loss
    [nn_azi_idx]=nearestpoint_app(app,mod_azi_diff_bs,aas_dist_azimuth); %%%%%%%Nearest Azimuth Idx
    size(nn_azi_idx)
    size(on_full_Pr_dBm)

    %%%%%%%%Now create a super_array_bs_eirp_dist with array_aas_dist_data which will be used in the same way as bs_eirp_dist
    % % % num_rows=length(nn_azi_idx)
    % % % [~,num_int_col]=size(array_aas_dist_data);
    % % % super_array_bs_eirp_dist=NaN(num_rows,num_int_col);
    % % % size(super_array_bs_eirp_dist)
    % % % for k=1:1:num_rows
    % % %     super_array_bs_eirp_dist(k,:)=array_aas_dist_data(nn_azi_idx(k),:);
    % % % end
    super_array_bs_eirp_dist=array_aas_dist_data(nn_azi_idx, :);
    %size(super_array_bs_eirp_dist)

   
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
        array_agg_check_mc_dBm=NaN(1,1);
        %'ERROR PAUSE: Inside Agg Check : Line 89: Empty on_full_Pr_dBm, cant calculate aggrgate'
        %pause;

        retry_save=1;
        while(retry_save==1)
            try
                save(agg_dist_file_name,'array_agg_check_mc_dBm')
                save(agg_check_file_name,'array_agg_check_95')
                retry_save=0;
            catch
                retry_save=1;
                pause(1)
            end
        end
    else
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%Calculate the simualation azimuths
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


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%Pre-compute off_axis_gain for every simulation azimuth [num_tx x num_sim_azi]
        %%%%%This block is independent of MC data so it runs once, not once per MC iteration.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        all_off_axis_gain=NaN(num_tx,num_sim_azi);
        [num_ele,~]=size(custom_antenna_pattern);
        for azimuth_idx=1:1:num_sim_azi
            sim_azimuth=array_sim_azimuth(azimuth_idx);
            circshift_antpat=custom_antenna_pattern;
            circshift_antpat(:,1)=mod(custom_antenna_pattern(:,1)+sim_azimuth,360);
            nn_zero_azi_idx=nearestpoint_app(app,0,circshift_antpat(:,1));
            shift_antpat=circshift(circshift_antpat,num_ele-nn_zero_azi_idx+1);
            shift_antpat=unique(shift_antpat,'rows'); %%%%%%Only keep unique azimuth rows
            nn_check_idx=nearestpoint_app(app,0,shift_antpat(:,1));
            if nn_check_idx~=1
                'Circ shift error'
                pause;
            end
            [ant_deg_idx]=nearestpoint_app(app,bs_azimuth,shift_antpat(:,1));
            all_off_axis_gain(:,azimuth_idx)=shift_antpat(ant_deg_idx,2);
        end

        % disp_progress(app,strcat('Inside Agg Check Rev1: Line 126: Starting the MC'))
        %%%MC loop — antenna work is gone, only math remains
        for mc_iter=1:1:mc_size
            %disp_progress(app,strcat('Inside Agg Check Rev1: Line 130:  MC:',num2str(mc_iter)))
            mc_iter
            %%%%%%%Generate 1 MC Iteration
            [pre_sort_monte_carlo_pr_dBm]=monte_carlo_Pr_dBm_rev1_app(app,rand_seed1,mc_iter,agg_check_reliability,on_full_Pr_dBm);

            %%%%%'interp super_array_bs_eirp_dist in the same way as bs_eirp_dist'
            [rand_norm_eirp]=monte_carlo_super_bs_eirp_dist_rev3(app,super_array_bs_eirp_dist,rand_seed1,mc_iter,num_tx,agg_check_reliability);
            [monte_carlo_clutter_loss]=monte_carlo_clutter_rev1_app(app,rand_seed1,mc_iter,agg_check_reliability,clutter_loss);

            sort_monte_carlo_pr_dBm=pre_sort_monte_carlo_pr_dBm+rand_norm_eirp-monte_carlo_clutter_loss;

            %%%%sort_monte_carlo_pr_dBm is [num_tx x 1], all_off_axis_gain is [num_tx x num_sim_azi]
            sort_temp_all_azi=sort_monte_carlo_pr_dBm+all_off_axis_gain;  %%%%[num_tx x num_sim_azi] broadcast

            if any(isnan(sort_temp_all_azi(:)))
                'ERROR PAUSE: Inside Agg Check Rev6: NaN Error: sort_temp_all_azi'
                pause;
            end

            %%%%Sum across BSs (dim 1) for all azimuths at once: /1000 and *1000 cancel
            array_agg_check_mc_dBm(mc_iter,:)=pow2db(sum(db2pow(sort_temp_all_azi)/1000,1,"omitnan")*1000);
        end

        if num_sim_azi>1
            'need to check percentile function of array_agg_check_mc_dBm'
            pause;
        end
        size(array_agg_check_mc_dBm)
        array_agg_check_95=prctile(sort(array_agg_check_mc_dBm),mc_percentile)
        [f_y,x_dB]=ecdf(array_agg_check_mc_dBm);
        %horzcat(x_dB,f_y)

 
        %%%%%%%%%%Find the secondary I/N and Percentiles and the
       
        data_header=cell_sim_data(1,:)';
        in1_idx=find(matches(data_header,'in_ratio'));
        label_idx=find(matches(data_header,'data_label1'));
        row_folder_idx=find(matches(cell_sim_data(:,label_idx),sim_folder));
        in_ratio1=cell_sim_data{row_folder_idx,in1_idx};

        %%%%%Need the secondary, if they are there
        in2_idx=find(matches(data_header,'second_in_ratio'));
        per2_idx=find(matches(data_header,'second_mc_percentile'));

        threshold_idx=find(matches(data_header,'dpa_threshold'));
        radar_threshold=cell_sim_data{row_folder_idx,threshold_idx};


        %%%%%%%%%%This is the zero dB shift.
        zero_dB=in_ratio1-radar_threshold;
        per_first_in=array_agg_check_95+zero_dB;

        if ~isempty(in2_idx)
            in_ratio2=cell_sim_data{row_folder_idx,in2_idx};
        else
            in_ratio2=NaN(1,1);
        end
        if ~isempty(per2_idx)
            per2=cell_sim_data{row_folder_idx,per2_idx};

            %%%%%%Find the second percentile also
            array_agg_check_second=prctile(sort(array_agg_check_mc_dBm),per2);
            per_second_in=array_agg_check_second+zero_dB;
        else
            per2=NaN(1,1);
            per_second_in=NaN(1,1);
        end

        f2=figure;
        hold on;
        plot(x_dB+zero_dB,f_y,':b','LineWidth',3)
        yline(mc_percentile/100,'--k','LineWidth',1)
        xline(in_ratio1,'-r','LineWidth',2)
        xline(per_first_in,':r','LineWidth',2)
        xline(in_ratio2,'-g','LineWidth',2)
        yline(per2/100,'--k','LineWidth',1)
        xline(per_second_in,':g','LineWidth',2)
        plot(x_dB+zero_dB,f_y,':b','LineWidth',3)
        title('Aggregate CDF')
        xlabel('I/N [dB]')
        ylabel('Cumulative Probability')
        grid on;
        pause(0.1)
        filename1=strcat('AggCheckCDF_',num2str(point_idx),'_',num2str(single_search_dist),'km.png');
        retry_save=1;
        while(retry_save==1)
            try
                saveas(gcf,char(filename1))
                retry_save=0;
            catch
                retry_save=1;
                pause(1)
            end
        end
        pause(0.1);
        close(f2)


        % close all;
        % f2=figure;
        % hold on;
        % plot(sort(array_agg_check_mc_dBm)+zero_dB,':')
        % xline(length(array_agg_check_mc_dBm)*mc_percentile/100,'-r','LineWidth',2)
        % yline(array_agg_check_95+zero_dB)
        % grid on;
        % pause(0.1)
        % filename1=strcat('AggCheck_',num2str(point_idx),'_',num2str(single_search_dist),'km.png');
        % retry_save=1;
        % while(retry_save==1)
        %     try
        %         saveas(gcf,char(filename1))
        %         retry_save=0;
        %     catch
        %         retry_save=1;
        %         pause(1)
        %     end
        % end
        % pause(0.1);
        %close(f2)
        % 'Check percentile'
        % pause;


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
                save(agg_dist_file_name,'array_agg_check_mc_dBm')
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

%%%%%Output validation
if isempty(array_agg_check_95)
    disp_progress(app,'ERROR PAUSE: agg_check_rev6_clutter_app: array_agg_check_95 is empty')
    pause;
end
if isempty(array_agg_check_mc_dBm)
    disp_progress(app,'ERROR PAUSE: agg_check_rev6_clutter_app: array_agg_check_mc_dBm is empty')
    pause;
end
%disp_progress(app,strcat('Inside Agg Check Rev1: Line 209: Finished'))