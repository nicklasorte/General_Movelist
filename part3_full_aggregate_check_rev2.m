function part3_full_aggregate_check_rev2(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,agg_check_mc_size,agg_check_mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,mitigation_dB,agg_check_reliability,tf_server_status,move_list_mc_size,move_list_mc_percentile)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Aggregate Check
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function:
cell_status_filename=strcat('cell_',string_prop_model,'_',num2str(sim_number),'_FullAggCheck_status.mat')
label_single_filename=strcat(string_prop_model,'_',num2str(sim_number),'_FullAggCheck_status')
location_table=table([1:1:length(folder_names)]',folder_names)
server_status_rev2(app,tf_server_status)


%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
[cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
zero_idx=find(cell2mat(cell_status(:,2))==0);

if ~isempty(zero_idx)==1
    temp_folder_names=folder_names(zero_idx)
    num_folders=length(temp_folder_names);

    %%%%%%%%Pick a random folder and go to the folder to do the sim
    disp_progress(app,strcat('Starting the Sims (Aggregate Check). . .',string_prop_model))
    [tf_ml_toolbox]=check_ml_toolbox(app);
    if tf_ml_toolbox==1
        array_rand_folder_idx=randsample(num_folders,num_folders,false);
    else
        array_rand_folder_idx=randperm(num_folders);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder Aggregate Check: ',num_folders);    %%%%%%% Create ParFor Waitbar

    for folder_idx=1:1:num_folders
        %%%%%%%%Before going to the sim folder, check one last time if we
        %%%%%%%%need to go to it, since another server may have already
        %%%%%%%%checked.

        %%%%%%%Load
        [cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
        sim_folder=temp_folder_names{array_rand_folder_idx(folder_idx)};
        temp_cell_idx=find(strcmp(cell_status(:,1),sim_folder)==1);

        if cell_status{temp_cell_idx,2}==0
            %%%%%%%%%%Calculate
            retry_cd=1;
            while(retry_cd==1)
                try
                    cd(rev_folder)
                    pause(0.1);
                    retry_cd=0;
                catch
                    retry_cd=1;
                    pause(0.1)
                end
            end

            retry_cd=1;
            while(retry_cd==1)
                try
                    sim_folder=temp_folder_names{array_rand_folder_idx(folder_idx)};
                    cd(sim_folder)
                    pause(0.1);
                    retry_cd=0;
                catch
                    retry_cd=1;
                    pause(0.1)
                end
            end

            disp_multifolder(app,sim_folder)
            data_label1=sim_folder;

            %%%%%%Check for the complete_filename
            complete_filename=strcat(data_label1,'_',label_single_filename,'.mat'); %%%This is a marker for me
            [var_exist]=persistent_var_exist_with_corruption(app,complete_filename);
            if var_exist==2
                retry_cd=1;
                while(retry_cd==1)
                    try
                        cd(rev_folder)
                        pause(0.1);
                        retry_cd=0;
                    catch
                        retry_cd=1;
                        pause(0.1)
                    end
                end

                %%%%%%%%Update the Cell
                [cell_status]=update_generic_status_cell_rev1(app,folder_names,sim_folder,cell_status_filename);
            else
                %%%%%%%%%%%%%%%%%Persistent Load the other variables
                disp_progress(app,strcat('Loading Sim Data . . . '))
                retry_load=1;
                while(retry_load==1)
                    try
                        disp_progress(app,strcat('Loading Sim Data . . . '))
                        load(strcat(data_label1,'_base_polygon.mat'),'base_polygon')
                        temp_data=base_polygon;
                        clear base_polygon;
                        base_polygon=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_base_protection_pts.mat'),'base_protection_pts')
                        temp_data=base_protection_pts;
                        clear base_protection_pts;
                        base_protection_pts=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_sim_array_list_bs.mat'),'sim_array_list_bs')
                        temp_data=sim_array_list_bs;
                        clear sim_array_list_bs;
                        sim_array_list_bs=temp_data;
                        clear temp_data;
                        % % %      %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation

                        load(strcat(data_label1,'_min_ant_loss.mat'),'min_ant_loss')
                        temp_data=min_ant_loss;
                        clear min_ant_loss;
                        min_ant_loss=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_radar_threshold.mat'),'radar_threshold')
                        temp_data=radar_threshold;
                        clear radar_threshold;
                        radar_threshold=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_radar_beamwidth.mat'),'radar_beamwidth')
                        temp_data=radar_beamwidth;
                        clear radar_beamwidth;
                        radar_beamwidth=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_min_azimuth.mat'),'min_azimuth')
                        temp_data=min_azimuth;
                        clear min_azimuth;
                        min_azimuth=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_max_azimuth.mat'),'max_azimuth')
                        temp_data=max_azimuth;
                        clear max_azimuth;
                        max_azimuth=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_neighborhood_dist.mat'),'neighborhood_dist')
                        temp_data=neighborhood_dist;
                        clear neighborhood_dist;
                        neighborhood_dist=temp_data;
                        clear temp_data;

                        retry_load=0;
                    catch
                        retry_load=1;
                        pause(0.1)
                    end
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Used to pull the right
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%union move list
                single_search_dist=neighborhood_dist;

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Agg Check list
                disp_progress(app,strcat('Starting the Aggregate Check . . . '))
                [num_ppts,~]=size(base_protection_pts)

                if parallel_flag==1  %%%%%%%%%%%%Double Check to start the parpool
                    [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                end

                %%%%%%%%%TIREM only does single "reliability"
                [agg_check_reliability]=trim_ml_rel_tirem_rev1(app,string_prop_model,agg_check_reliability);

                if any(mitigation_dB>0)
                    'Need to figure out how to do this for a nonzero mitigation_dB'
                    pause;
                end

                num_miti=length(mitigation_dB);
                [hWaitbar_agg,hWaitbarMsgQueue_agg]= ParForWaitbarCreateMH_time('Aggregate Check: ',num_ppts*num_miti);    %%%%%%% Create ParFor Waitbar

                file_name_cc_miti_aggregate=strcat(string_prop_model,'_',data_label1,'_cell_cell_miti_aggregate_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(sim_number),'_',num2str(agg_check_mc_size),'_',num2str(agg_check_mc_percentile),'.mat');
                [file_cc_miti_aggregate_exist]=persistent_var_exist_with_corruption(app,file_name_cc_miti_aggregate);

                file_name_max_miti_agg=strcat(string_prop_model,'_',data_label1,'_max_miti_aggregate_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(sim_number),'_',num2str(agg_check_mc_size),'_',num2str(agg_check_mc_percentile),'.mat');
                [file_max_agg_exist]=persistent_var_exist_with_corruption(app,file_name_max_miti_agg);

                if file_cc_miti_aggregate_exist==2 && file_max_agg_exist==2
                    retry_load=1;
                    while(retry_load==1)
                        try
                            load(file_name_cc_miti_aggregate,'cell_cell_miti_aggregate')
                            load(file_name_max_miti_agg,'max_miti_aggregate')
                            pause(0.1);
                            retry_load=0;
                        catch
                            retry_load=1;
                            pause(0.1)
                        end
                    end
                else
                    %%%%'Do the mitigiation loop over the aggregate
                    cell_cell_miti_aggregate=cell(num_miti,3); %%%%%%%%%%%%%1) cell_agg_check_data, 2)cell_agg_percentile 3)Azimuth Degrees
                    max_miti_aggregate=NaN(num_miti,2); %%%%%1) Mitigation dB, 2) Interference Over Threshold
                    for miti_idx=1:1:num_miti
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Aggregate
                        temp_miti=mitigation_dB(miti_idx)

                        %%%%%%%%%%First check for the union move list
                        %%%%%%%%%First, check to see if the union of the move list exists
                        file_name_union_move=strcat(string_prop_model,'_',data_label1,'_union_turn_off_list_data_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(sim_number),'_',num2str(move_list_mc_size),'_',num2str(move_list_mc_percentile),'_',num2str(temp_miti),'_',num2str(single_search_dist),'km.mat');
                        [file_union_move_exist]=persistent_var_exist_with_corruption(app,file_name_union_move);

                        if file_union_move_exist==2
                            retry_load=1;
                            while(retry_load==1)
                                try
                                    load(file_name_union_move,'union_turn_off_list_data')
                                    temp_data=file_name_union_move;
                                    clear file_name_union_move;
                                    file_name_union_move=temp_data;
                                    clear temp_data;
                                    retry_load=0;
                                catch
                                    retry_load=1;
                                    pause(0.1)
                                end
                            end
                        else
                            disp_progress(app,strcat('Pause Error: No Union Move List'))
                            pause;
                        end


                        file_name_cell_agg_check_data=strcat(string_prop_model,'_',data_label1,'_cell_agg_check_data_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(sim_number),'_',num2str(agg_check_mc_size),'_',num2str(agg_check_mc_percentile),'_',num2str(temp_miti),'.mat');
                        [file_agg_check_data_exist]=persistent_var_exist_with_corruption(app,file_name_cell_agg_check_data);

                        file_name_cell_agg_percentile=strcat(string_prop_model,'_',data_label1,'_cell_agg_percentile_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(sim_number),'_',num2str(agg_check_mc_size),'_',num2str(agg_check_mc_percentile),'_',num2str(temp_miti),'.mat');
                        [file_agg_percentile_exist]=persistent_var_exist_with_corruption(app,file_name_cell_agg_percentile);

                        if file_agg_check_data_exist==2 && file_agg_percentile_exist==2
                            retry_load=1;
                            while(retry_load==1)
                                try
                                    load(file_name_cell_agg_check_data,'cell_agg_check_data')
                                    temp_data=cell_agg_check_data;
                                    clear cell_agg_check_data;
                                    cell_agg_check_data=temp_data;
                                    clear temp_data;

                                    load(file_name_cell_agg_percentile,'cell_agg_percentile')
                                    temp_data=cell_agg_percentile;
                                    clear cell_agg_percentile;
                                    cell_agg_percentile=temp_data;
                                    clear temp_data;
                                    retry_load=0;
                                catch
                                    retry_load=1;
                                    pause(0.1)
                                end
                            end
                            %%%%%%%%%%Need to update the bar.
                            for point_idx=1:1:num_ppts
                                hWaitbarMsgQueue_agg.send(0);
                            end
                        else

                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%First create the keep_on list (to be used in the aggregate check)
                            %%%Push this into the aggregate check funtion
                            on_list_bs=sim_array_list_bs;
                            if isempty(union_turn_off_list_data)
                                off_idx=[];
                            else
                                [C_on,off_idx,ib_on]=intersect(sim_array_list_bs,union_turn_off_list_data,'rows');
                                %off_idx(1:10)
                            end
                            off_idx=sort(off_idx);
                            on_list_bs(off_idx,:)=[];  %%%%%%%Cut off_idx from A
                            off_list_bs=sim_array_list_bs(off_idx,:);

                            size(off_list_bs)
                            size(on_list_bs)
                            size(sim_array_list_bs)


                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Aggregate Check

                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate first-->Parfor --> No data load
                            disp_progress(app,strcat('Parfor Aggregate Check'))
                            server_status_rev1(app)
                            if parallel_flag==1
                                [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                                parfor point_idx=1:num_ppts  %%%%Change to parfor
                                    agg_check_rev3_app(app,agg_check_reliability,point_idx,sim_number,agg_check_mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,agg_check_mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,off_idx,min_azimuth,max_azimuth,temp_miti);
                                    %agg_check_rev2_string_prop_model_azimuths_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth);
                                    hWaitbarMsgQueue_agg.send(0);
                                end
                            end

                            %%%%%%%%%%%Then for each point, scrap the data and save to excel. Only hold onto 1 point data at a time.
                            %%%%%%%%For this case (1 Monte Carlo Iteration), we really don't need to save most of the data, only the optimized move list order.
                            %%%%%%%%%Keep the move list flexible with the reliability inputs, so we can have multiple move lists.
                            %%%%%%%%%%In the next revision, do the full ITM reliability and do the aggregate check of the 50% ITM with the full 1-99%. (1000 MC and 95th Percentile)
                            cell_agg_check_data=cell(num_ppts,1);
                            cell_agg_percentile=cell(num_ppts,1);
                            disp_progress(app,strcat('Loading Aggregate Check in For Loop '))
                            server_status_rev1(app)
                            for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
                                point_idx
                                [array_agg_check_mc_dBm,array_agg_check_percentile]=agg_check_rev3_app(app,agg_check_reliability,point_idx,sim_number,agg_check_mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,agg_check_mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,off_idx,min_azimuth,max_azimuth,temp_miti);

                                cell_agg_check_data{point_idx}=array_agg_check_mc_dBm;
                                cell_agg_percentile{point_idx}=array_agg_check_percentile;

                                %%%%%%%Check Aggregate with Move List Inputs
                                %[agg_check_med_dBm,array_check_med_per]=agg_check_rev3_app(app,move_list_reliability,point_idx,sim_number,move_list_mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,move_list_mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,off_idx,min_azimuth,max_azimuth);
                                if parallel_flag==0
                                    %%%%%%%Decrement the waitbar
                                    hWaitbarMsgQueue_agg.send(0);
                                end
                            end
                            toc;

                            retry_save=1;
                            while(retry_save==1)
                                try
                                    save(file_name_cell_agg_check_data,'cell_agg_check_data')
                                    save(file_name_cell_agg_percentile,'cell_agg_percentile')
                                    retry_save=0;
                                catch
                                    retry_save=1;
                                    pause(0.1)
                                end
                            end
                        end

                        cell_cell_miti_aggregate{miti_idx,1}=cell_agg_check_data;
                        cell_cell_miti_aggregate{miti_idx,2}=cell_agg_percentile;
                        [array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth);
                        cell_cell_miti_aggregate{miti_idx,3}=array_sim_azimuth;


                        %%%%%Need to compile all the aggregate into CDFS
                        full_agg_data=vertcat(cell_agg_check_data{:});
                        merged_agg_percentile=vertcat(cell_agg_percentile{:});
      
                        f12=figure;
                        hold on;
                        plot(array_sim_azimuth,merged_agg_percentile')
                        yline(radar_threshold,'r','LineWidth',2)
                        grid on;
                        title(strcat('Aggregate Percentile:',num2str(agg_check_mc_percentile)))
                        xlabel('Radar Azimuth [Deg]')
                        ylabel('Aggregate')
                        xlim([floor(min(array_sim_azimuth)) ceil(max(array_sim_azimuth))])
                        filename2=strcat(data_label1,'_',string_prop_model,'_',num2str(temp_miti),'dB_Agg_Percentile.png');
                        pause(0.1)
                        saveas(f12,char(filename2))
                        pause(0.1)
                        close(f12)


                        %%%%%%%%%%%%%%%Amount of Interference Over
                        %%%%%%%%%%%%%%%Threshold per Azimuth
                        max_agg_per=max(merged_agg_percentile)-radar_threshold;
                        max_miti_aggregate(miti_idx,1)=temp_miti;
                        max_miti_aggregate(miti_idx,2)=max(max_agg_per);

                        f10=figure;
                        hold on;
                        plot(array_sim_azimuth,max_agg_per)                      
                        grid on;
                        title(strcat('Aggregate Over Threshold'))
                        xlabel('Radar Azimuth [Deg]')
                        ylabel('Aggregate Over Threshold [dB]')
                        xlim([floor(min(array_sim_azimuth)) ceil(max(array_sim_azimuth))])
                        filename1=strcat(data_label1,'_',string_prop_model,'_',num2str(temp_miti),'dB_Agg_Over.png');
                        pause(0.1)
                        saveas(f10,char(filename1))
                        pause(0.1)
                        close(f10)


                        %%%%%%%%%%%%Find the percentile that is above/below the
                        %%%%%%%%%%%%radar threshold

                        agg_above_percentile=NaN(num_sim_azi,1);
                        [num_all_mc,~]=size(full_agg_data);
                        for i=1:1:num_sim_azi
                            temp_above_idx=find(full_agg_data(:,i)<radar_threshold);
                            agg_above_percentile(i)=length(temp_above_idx)/num_all_mc*100;
                        end

                        f13=figure;
                        hold on;
                        plot(array_sim_azimuth,agg_above_percentile)
                        grid on;
                        title(strcat('Aggregate Percentile Below Thresold'))
                        xlabel('Radar Azimuth [Deg]')
                        ylabel('Aggregate Percentile Below Threshold')
                        xlim([floor(min(array_sim_azimuth)) ceil(max(array_sim_azimuth))])
                        filename3=strcat(data_label1,'_',string_prop_model,'_',num2str(temp_miti),'dB_Agg_Per_Below_Threshold.png');
                        pause(0.1)
                        saveas(f13,char(filename3))
                        pause(0.1)
                        close(f13)


                        %%%%%%%%%%%%%%%%%%%%Full CDFs
                        f14=figure;
                        hold on;
                        cdfplot(reshape(full_agg_data,[],1))
                        xline(radar_threshold,'r','LineWidth',2)
                        grid on;
                        title(strcat('CDF Aggregate All Azimuths'))
                        filename4=strcat(data_label1,'_',string_prop_model,'_',num2str(temp_miti),'dB_CDF_All_Azi.png');
                        pause(0.1)
                        saveas(f14,char(filename4))
                        pause(0.1)
                        close(f14)

                    end

                            %%%%%%%%%%%%%%%%%%%%%Aggregate graphs

                        % figure;
                        %    hold on;
                        %    plot(array_agg_check_mc_dBm')
                        %    plot(array_agg_check_percentile,'-b','LineWidth',3)
                        %
                        %    max(array_agg_check_percentile)
                        %      grid on;

                        %
                        % figure;
                        % hold on;
                        % plot(agg_check_med_dBm')
                        % plot(array_check_med_per,'-b','LineWidth',3)


                        %%%%%%%%%%%%CDF plots
                        % figure;
                        % hold on;
                        % cdfplot(reshape(array_agg_check_mc_dBm,[],1))
                        % xline(radar_threshold,'r','LineWidth',2)
                        % grid on;
                        %
                        %     %%%%Need to calculate the number of
                        % %%%%azimuths under/over the radar_threshold
                        % over_idx=find(array_agg_check_percentile>radar_threshold);
                        % figure;
                        % hold on;
                        % plot(array_agg_check_percentile,'-b','LineWidth',1)
                        % plot(over_idx,array_agg_check_percentile(over_idx),'or')
                        % yline(radar_threshold,'r','LineWidth',2)
                        % grid on;

                        % %%%%%%Make a polar plot of the
                        % %%%%%%array_agg_check_percentile that is
                        % %%%%%%over a google map plot.
                        %
                        %    [array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth);
                        % figure;
                        % %%%Need to make normalize the
                        % %%%array_agg_check_percentile to the
                        % %%%distance of the simulated area
                        % [x_pol,y_pol]=pol2cart(deg2rad(array_sim_azimuth),array_agg_check_percentile);
                        % x_pol_shift=x_pol+base_protection_pts(2);
                        % y_pol_shift=y_pol+base_protection_pts(1);
                        % %%%%%Shift it to the center
                        % plot(x_pol_shift,y_pol_shift,'-r','LineWidth',2)
                        % %%%%
                        % hold on;
                        % plot(base_protection_pts(2),base_protection_pts(1),'xb')

                    retry_save=1;
                    while(retry_save==1)
                        try
                            save(file_name_cc_miti_aggregate,'cell_cell_miti_aggregate')
                            save(file_name_max_miti_agg,'max_miti_aggregate')
                            pause(0.1);
                            retry_save=0;
                        catch
                            retry_save=1;
                            pause(0.1)
                        end
                    end
                end
                delete(hWaitbarMsgQueue_agg);
                close(hWaitbar_agg);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End of Miti Loop
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%Save
                retry_save=1;
                while(retry_save==1)
                    try
                        comp_list=NaN(1);
                        save(complete_filename,'comp_list')
                        pause(0.1);
                        retry_save=0;
                    catch
                        retry_save=1;
                        pause(0.1)
                    end
                end

                retry_cd=1;
                while(retry_cd==1)
                    try
                        cd(rev_folder)
                        pause(0.1);
                        retry_cd=0;
                    catch
                        retry_cd=1;
                        pause(0.1)
                    end
                end
                [cell_status]=update_generic_status_cell_rev1(app,folder_names,sim_folder,cell_status_filename);
            end
        end
        multi_hWaitbarMsgQueue.send(0);
        server_status_rev2(app,tf_server_status)
    end
    delete(multi_hWaitbarMsgQueue);
    close(multi_hWaitbar);
    server_status_rev2(app,tf_server_status)
end