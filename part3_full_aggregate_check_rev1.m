function part3_full_aggregate_check_rev1(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,mitigation,tf_calc_opt_sort,agg_check_reliability)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function:
cell_status_filename=strcat('cell_',string_prop_model,'_',num2str(sim_number),'_FullAggCheck_status.mat')
label_single_filename=strcat(string_prop_model,'_',num2str(sim_number),'_FullAggCheck_status')
location_table=table([1:1:length(folder_names)]',folder_names)

%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
[cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
zero_idx=find(cell2mat(cell_status(:,2))==0);

if ~isempty(zero_idx)==1
    temp_folder_names=folder_names(zero_idx)
    num_folders=length(temp_folder_names);

    %%%%%%%%Pick a random folder and go to the folder to do the sim
    disp_progress(app,strcat('Starting the Sims (Aggregate Check). . .',string_prop_model))
    %%reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.

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

                        load(strcat(data_label1,'_radar_height.mat'),'radar_height')
                        temp_data=radar_height;
                        clear radar_height;
                        radar_height=temp_data;
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

                        % % %      tic;
                        % % %      load(strcat(data_label1,'_sim_cell_bs_data.mat'),'sim_cell_bs_data')
                        % % %      toc; %%%%%%%%%3 seconds
                        %%%1) LaydownID
                        %%%2) FCCLicenseID
                        %%%3) SiteID
                        %%%4) SectorID
                        %%%5) SiteLatitude_decDeg
                        %%%6) SiteLongitude_decDeg
                        %%%7) SE_BearingAngle_deg
                        %%%8) SE_AntennaAzBeamwidth_deg
                        %%%9) SE_DownTilt_deg  %%%%%%%%%%%%%%%%%(Check for Blank)
                        %%%10) SE_AntennaHeight_m
                        %%%11) SE_Morphology
                        %%%12) SE_CatAB
                        %%%%%%%%%%13) NLCD idx
                        %%%%%%%%%14) EIRP (no mitigations)
                        %%%%%%%%%15) EIRP (mitigations)

                        retry_load=0;
                    catch
                        retry_load=1;
                        pause(0.1)
                    end
                end

                sim_array_list_bs(:,7)=NaN(1,1);  %%%%%%%%Setting the azimuths to NaN assumes worst-case.

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Sequential Aggregate Check
                disp_progress(app,strcat('Starting the Aggregate Check . . . '))
                [num_ppts,~]=size(base_protection_pts)

                if parallel_flag==1  %%%%%%%%%%%%Double Check to start the parpool
                    [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                end

                if strcmp(string_prop_model,'TIREM')
                    if length(move_list_reliability)>1
                        %%%%%%%%%TIREM only does single "reliability"
                        %%%%%This will make it so we aren't doing duplicate
                        %%%%%calculations and thinking that we are doing a
                        %%%%%calculation that really isn't being done.
                        move_list_reliability=50;
                    end
                    if move_list_reliability~=50
                        %%%%%TIREM only does "50", can't do 10% or 1%, etc.
                        move_list_reliability=50;
                    end
                end

                num_miti=length(mitigation);
                [hWaitbar_movelist,hWaitbarMsgQueue_movelist]= ParForWaitbarCreateMH_time('Aggregate Check: ',num_ppts*num_miti);    %%%%%%% Create ParFor Waitbar

                %%%%'Do the mitigiation loop over the aggregate check, will need to add a label to the aggcheck files.'
                %%%%%%%Parfor the miti loop, but this is not a large computational load, so it might not be worth it.
                for miti_idx=1:1:num_miti
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Aggregate Check
                    temp_miti=mitigation(miti_idx)

                    %%%%%%%%%%First Load the union move list
                    %%%%%%%%%First, check to see if the union of the move list exists
                    file_name_union_move=strcat(string_prop_model,'_',data_label1,'_union_turn_off_list_data_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(temp_miti),'dB.mat');
                    [file_union_move_exist]=persistent_var_exist_with_corruption(app,file_name_union_move);

                    %%%%%%%I don't think we will need the union turn off list.
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
                        'No Union Move List'
                        pause;
                    end

                    if num_ppts>1
                        'Need to check the function below for multiple points'
                        pause;
                    end

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate the near-optimal move list order for all the points/azimuths
                    %%%%%%%The hard part is that if we have more than 1
                    %%%%%%%point, then the list to turn off devices will
                    %%%%%%%need to take into consideration all the pathloss
                    %%%%%%%for all the points, and then do the larger
                    %%%%%%%calculation similar to the "optimized" move
                    %%%%%%%list. For now, since there is only one point, we
                    %%%%%%%can keep pushing forward for now.
                    [opt_multi_point_idx]=multi_point_near_opt_idx_rev1(app,temp_miti,string_prop_model,data_label1,sim_array_list_bs,radar_beamwidth,min_ant_loss,base_protection_pts,tf_calc_opt_sort,sim_number,reliability);
                    size(opt_multi_point_idx)

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate first-->Parfor --> No data load
                    if parallel_flag==1
                        parfor point_idx=1:num_ppts
                            full_sequential_agg_check_rev1(app,string_prop_model,mc_percentile,agg_check_reliability,point_idx,sim_number,mc_size,temp_miti,sim_array_list_bs,reliability,base_protection_pts,radar_beamwidth,min_ant_loss,data_label1,norm_aas_zero_elevation_data,opt_multi_point_idx);
                            hWaitbarMsgQueue_movelist.send(0);
                        end
                    end


                    if num_ppts>1
                        'Need to figure out excel spread sheets'
                        pause;
                    end

                    %%%%%%%%%%%%%%%For the full 95th, 1000 MC Iterations
                    for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
                        point_idx
                        %%%%%%%%%%First try with inner Tx Loop, extremely fast, but memory intensive.
                        tic;
                        [full_agg_check_dBm]=full_sequential_agg_check_rev1(app,string_prop_model,mc_percentile,agg_check_reliability,point_idx,sim_number,mc_size,temp_miti,sim_array_list_bs,reliability,base_protection_pts,radar_beamwidth,min_ant_loss,data_label1,norm_aas_zero_elevation_data,opt_multi_point_idx);
                        toc;

                        if parallel_flag==0
                            %%%%%%%Decrement the waitbar
                            hWaitbarMsgQueue_movelist.send(0);
                        end
                    end
                    toc;

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Aggregate with 1 MC Iteration and 50th/%
% % % % % % %                     agg_check_reliability=50
% % % % % % %                     mc_size=1
% % % % % % %                     mc_percentile=100
                    for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
                        point_idx
                        [median_full_agg_check_dBm]=full_sequential_agg_check_rev1(app,string_prop_model,100,50,point_idx,sim_number,1,temp_miti,sim_array_list_bs,reliability,base_protection_pts,radar_beamwidth,min_ant_loss,data_label1,norm_aas_zero_elevation_data,opt_multi_point_idx);
                    end

                    delta_dB_agg_check=full_agg_check_dBm-median_full_agg_check_dBm;

% % %                     figure;
% % %                     hold on;
% % %                     histogram(delta_dB_agg_check)
% % % % 
% % % %                     figure;
% % % %                     hold on;
% % % %                     plot(full_agg_check_dBm,'-b')
% % % %                     plot(median_full_agg_check_dBm,'-g')
% % % %                     grid on;

                                
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Data for Excel
                                tic;
                                point_idx=1
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

                                %%%%%%%Take into consideration the sector/azimuth off-axis gain
                                [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev2_no_bs_azi(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
                                %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel

                                [mid_idx]=nearestpoint_app(app,50,reliability);
                                mid_pathloss_dB=pathloss(:,mid_idx);
                                median_pr_dbm=sim_array_list_bs(:,4)-mid_pathloss_dB+bs_azi_gain-temp_miti;  %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System

                                sort_mid_pathloss_dB=mid_pathloss_dB(opt_multi_point_idx);
                                sort_median_pr_dbm=median_pr_dbm(opt_multi_point_idx,:);
                                sort_sim_array_list_bs=sim_array_list_bs(opt_multi_point_idx,:);

                 

                        [num_tx,~]=size(sort_sim_array_list_bs)
                        array_excel_data=horzcat(sort_sim_array_list_bs(:,5),sort_sim_array_list_bs(:,[1,2,3]),base_protection_pts.*ones(num_tx,1),radar_height.*ones(num_tx,1),sort_sim_array_list_bs(:,[4]),sort_mid_pathloss_dB,sort_median_pr_dbm,median_full_agg_check_dBm,full_agg_check_dBm,delta_dB_agg_check);

                        table_move_list=array2table(array_excel_data);
                        table_move_list.Properties.VariableNames={'Uni_Id' 'BS_Latitude_DD' 'BS_Longitude_DD' 'BS_Height_m' 'Fed_Latitude_DD' 'Fed_Longitude_DD' 'Fed_Height_m' 'BS_EIRP_dBm'  'Path_Loss_dB'  'PowerReceived_dBm' 'Median_Aggregate_dBm' '95th_Aggregate_dBm' 'Aggregate_delta_dB'}

                        tic;
                        writetable(table_move_list,strcat(data_label1,'_Point',num2str(point_idx),'_Link_Budget.xlsx'));
                        toc;
                         
                        close all;
                        figure;
                        scatter(sort_median_pr_dbm,delta_dB_agg_check)
                        xlabel('Single Power Received [dBm]')
                        ylabel('delta dB ')
                        grid on;
                              

                        diff_median_pr_dbm=abs(diff(sort_median_pr_dbm));
                        figure;
                        %scatter(diff_median_pr_dbm,delta_dB_agg_check(1:end-1))
                        scatter(diff_median_pr_dbm,delta_dB_agg_check(2:end))
                         set(gca,'Xscale','log')
                        xlabel('Difference Nearest Single Power Received [dBm]')
                        ylabel('delta dB [Agg 95th vs Agg 50th]')
                        grid on;
                        filename1=strcat('Scatter1_',data_label1,'_',string_prop_model,'_',num2str(temp_miti),'dB_Off.png');
                        pause(0.1)
                        saveas(gcf,char(filename1))
                        pause(0.1)


                        
                        diff_agg_median_pr_dbm=abs(diff(median_full_agg_check_dBm));
                        figure;
                        scatter(diff_agg_median_pr_dbm,delta_dB_agg_check(1:end-1))
                        set(gca,'Xscale','log')
                        xlabel('Difference Agg Power Received 50th [dBm]')
                        ylabel('delta dB [Agg 95th vs Agg 50th]')
                        grid on;


                        figure;
                        hold on;
                        histogram(delta_dB_agg_check)
                        xlabel('delta dB [Aggregate 95th vs Aggregate 50th]')
                        ylabel('Number of Occurences')
                        grid on;
                        filename1=strcat('Agg95th_vs_Agg50th_Histogram_',data_label1,'_',string_prop_model,'_',num2str(temp_miti),'dB_Off.png');
                        pause(0.1)
                        saveas(gcf,char(filename1))
                        pause(0.1)
                    


                        %%%%%%%%%%%Try to find the Aggregate Factor
                        single_agg_delta_dB=median_full_agg_check_dBm-sort_median_pr_dbm;
                        diff_median_pr_dbm=abs(diff(sort_median_pr_dbm));
                        figure;
                        scatter(diff_median_pr_dbm,single_agg_delta_dB(1:end-1))
                         set(gca,'Xscale','log')
                        xlabel('Difference Single Power Received [dBm]')
                        ylabel('Aggregate Factor dB ')
                        grid on;
                          filename1=strcat('Scatter3_Aggregate_Factor_',data_label1,'_',string_prop_model,'_',num2str(temp_miti),'dB_Off.png');
                        pause(0.1)
                        saveas(gcf,char(filename1))
                        pause(0.1)


                        %%%%%%%%%%%Try to find the Aggregate Factor
                        single_agg_delta_dB=median_full_agg_check_dBm-sort_median_pr_dbm;
                        figure;
                        hold on;
                        histogram(single_agg_delta_dB)
                        grid on;
                         xlabel('Aggregate Factor [dB]')
                        ylabel('Number of Occurences')
                        filename1=strcat('Histogram1_Aggregate_Factor_',data_label1,'_',string_prop_model,'_',num2str(temp_miti),'dB_Off.png');
                        pause(0.1)
                        saveas(gcf,char(filename1))
                        pause(0.1)



                        %%%%%%%%%%%Try to find the Aggregate Factor
                        single_agg_delta_dB=median_full_agg_check_dBm-sort_median_pr_dbm;
                        figure;
                        scatter(sort_median_pr_dbm,single_agg_delta_dB)
                        set(gca,'Xscale','log')
                        xlabel('Single Power Received [dBm]')
                        ylabel('Aggregate Factor [dB]')
                        grid on;
                        filename1=strcat('Scatter2_Aggregate_Factor_',data_label1,'_',string_prop_model,'_',num2str(temp_miti),'dB_Off.png');
                        pause(0.1)
                        saveas(gcf,char(filename1))
                        pause(0.1)


% % % % % % % % % % % % % % % % % % % % % % %                         %%%%%%%%%The aggregate factor might be the number
% % % % % % % % % % % % % % % % % % % % % % %                         %%%%%%%%%of base stations within 1dB of it.
                        [num_tx]=length(sort_median_pr_dbm);
                        width_dB=1;
                        count_width=NaN(num_tx,1);
                        tic;
                        for i=1:1:num_tx
                            temp_pr=sort_median_pr_dbm(i);
                            above_idx=find(temp_pr+width_dB>sort_median_pr_dbm);
                            below_idx=find(temp_pr-width_dB<sort_median_pr_dbm);
                            int_idx=intersect(above_idx,below_idx);
                            count_width(i)=length(int_idx);
                        end
                        toc;

                        figure;
                        hold on;
                        histogram(count_width)

                        %%%%%%%%%%%Try to find the Aggregate Factor
                        single_agg_delta_dB=median_full_agg_check_dBm-sort_median_pr_dbm;
                        %%%%%single_agg_delta_dB=full_agg_check_dBm-sort_median_pr_dbm;

                        figure;
                        hold on;
                        scatter(count_width,single_agg_delta_dB)
                        set(gca,'Xscale','log')
                        xlabel('Number of Base Stations within 1dB')
                        ylabel('Aggregate Factor [dB] (50th Percentile)')
                        grid on;
                          filename1=strcat('Scatter4_Aggregate_Factor_',data_label1,'_',string_prop_model,'_',num2str(temp_miti),'dB_Off.png');
                        pause(0.1)
                        saveas(gcf,char(filename1))
                        pause(0.1)

                        
                   'Having a hard time trying to make sense of some of the plots'

   
                    'Start here with agg, look at plots'
                    %%%%pause;


                end

                delete(hWaitbarMsgQueue_movelist);
                close(hWaitbar_movelist);

                

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Can make this the simple move list/union Function (non-mitigations)

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%Save
                retry_save=1;
                while(retry_save==1)
                    try
                        comp_list=NaN(1);
                        %save(complete_filename,'comp_list')
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
                %[cell_status]=update_generic_status_cell_rev1(app,folder_names,sim_folder,cell_status_filename);
            end
        end
        multi_hWaitbarMsgQueue.send(0);
    end
    delete(multi_hWaitbarMsgQueue);
    close(multi_hWaitbar);
end


