function part4_movelist_miti_EXCEL_rev4(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,reliability,norm_aas_zero_elevation_data,string_prop_model)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function:
cell_status_filename=strcat('cell_',string_prop_model,'_',num2str(sim_number),'_excel_status.mat')
label_single_filename=strcat(string_prop_model,'_',num2str(sim_number),'_excel_status')
location_table=table([1:1:length(folder_names)]',folder_names)

%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
[cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename)
zero_idx=find(cell2mat(cell_status(:,2))==0);

if ~isempty(zero_idx)==1
    temp_folder_names=folder_names(zero_idx)
    num_folders=length(temp_folder_names);

    %%%%%%%%Pick a random folder and go to the folder to do the sim
    disp_progress(app,strcat('Starting the Sims (Move List--Writing Excel). . .',string_prop_model))
    reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.


    [tf_ml_toolbox]=check_ml_toolbox(app);
    if tf_ml_toolbox==1
        array_rand_folder_idx=randsample(num_folders,num_folders,false);
    else
        array_rand_folder_idx=randperm(num_folders);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder Move List Excel: ',num_folders);    %%%%%%% Create ParFor Waitbar

    for folder_idx=1:1:num_folders
        %%%%%%%%Before going to the sim folder, check one last time if we
        %%%%%%%%need to go to it, since another server may have already
        %%%%%%%%checked.

        %%%%%%%Load
        [cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
        sim_folder=temp_folder_names{array_rand_folder_idx(folder_idx)};
        temp_cell_idx=find(strcmp(cell_status(:,1),sim_folder)==1);
        temp_cell_idx

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
                        % % %%%sim_array_list_bs %%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation

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

                        retry_load=0;
                    catch
                        retry_load=1;
                        pause(0.1)
                    end
                end


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Move list
                disp_progress(app,strcat('Starting the Move List Excel Writing. . . '))
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


                %%%%%%%%%%%Make a Table for each protection point
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate first-->Parfor --> No data load
                %%%%%%%%%%%Then for each point, scrap the data and save to excel. Only hold onto 1 point data at a time.
                %%%%%%%%For this case (1 Monte Carlo Iteration), we really don't need to save most of the data, only the optimized move list order.
                %%%'To prevent the possibility of memory issues, may need to write the excel file right here after each point. But then we cant parfor the calculation. Just load in all the data after the calculation.'
                for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
                    point_idx


                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load data and print excel


                    %%%%%%%%%%%%%%%%%%%%%%%%%%%Load propagation for the Output Excel File
                    [pathloss,cell_prop_mode]=load_pathloss_propmode_rev1(app,string_prop_model,point_idx,sim_number,data_label1);
                    %%%%%%%% Cut the reliabilities that we will use for the move list
                    size(pathloss)
                    [rel_first_idx]=nearestpoint_app(app,min(move_list_reliability),reliability);
                    [rel_second_idx]=nearestpoint_app(app,max(move_list_reliability),reliability);
                    if strcmp(string_prop_model,'TIREM')
                        % % % % if TIREM, we wont cut the reliabilites because there are none to cut.
                    else
                        pathloss=pathloss(:,[rel_first_idx:rel_second_idx]);
                    end
                    size(pathloss)



                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check for Move List File, if none, save place holder
                    off_list_bs_file_name=strcat(string_prop_model,'_miti_off_list_bs_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'.mat');
                    mitigation_list_bs_file_name=strcat(string_prop_model,'_miti_mitigation_list_bs_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'.mat');
                    mitigation_sort_bs_idx_file_name=strcat(data_label1,'_',string_prop_model,'_mitigation_sort_bs_idx_',num2str(point_idx),'.mat');

                    [var_exist_off_list]=persistent_var_exist(app,off_list_bs_file_name);
                    [var_exist_mitigation_list]=persistent_var_exist(app,mitigation_list_bs_file_name);
                    [var_exist_sort_idx]=persistent_var_exist(app,mitigation_sort_bs_idx_file_name);

                    if var_exist_off_list==2 && var_exist_mitigation_list==2 && var_exist_sort_idx==2
                        %%%%%%%%%%%load
                        retry_load=1;
                        while(retry_load==1)
                            try
                                load(mitigation_sort_bs_idx_file_name,'mitigation_sort_bs_idx')
                                load(off_list_bs_file_name,'off_list_bs')
                                load(mitigation_list_bs_file_name,'mitigation_list_bs')
                                retry_load=0;
                            catch
                                retry_load=1;
                                pause(1)
                            end
                        end
                    else
                        'Error: Not all the data is available'
                        pause;
                    end

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate the Pr_dBm

                    %%%%%%%Take into consideration the sector/azimuth off-axis gain
                    [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev2(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
                    %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel

                    sort_full_Pr_dBm=sim_array_list_bs(mitigation_sort_bs_idx,4)-pathloss(mitigation_sort_bs_idx,:)+bs_azi_gain(mitigation_sort_bs_idx);
                    mitigation_sort_full_Pr_dBm=sim_array_list_bs(mitigation_sort_bs_idx,8)-pathloss(mitigation_sort_bs_idx,:)+bs_azi_gain(mitigation_sort_bs_idx);
                    mitigation_sort_sim_array_list_bs=sim_array_list_bs(mitigation_sort_bs_idx,:);
                    sort_cell_prop_mode=cell_prop_mode(mitigation_sort_bs_idx);

                    temp_sort_pathloss=pathloss(mitigation_sort_bs_idx,:);
                    temp_sort_Pr_dBm=sort_full_Pr_dBm;
                    [~,pr_width]=size(sort_full_Pr_dBm);
                    if pr_width>1
                        'Error: Need to change how we save the Pr_dBm in the spreadsheet'
                        pause;
                    end


                    temp_sorted_list_data=mitigation_sort_sim_array_list_bs;
                    [num_tx,~]=size(temp_sorted_list_data);
                    sim_pt=base_protection_pts(point_idx,:);
                    sorted_array_bs_azi_data=array_bs_azi_data(mitigation_sort_bs_idx,:);
                    %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel
                    % % %      %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation
                    %%%%%%%9) EIRP dBm:         array_bs_eirp
                    %%%%%%%10) AAS (Vertical) dB Reduction: (Downtilt)   %%%%%%%%Downtilt dB Value for Rural/Suburban/Urban
                    %%%%%%%%%11)Clutter
                    %%%%%%%%%12)Network Loading and TDD (dB)
                    %%%%%%%%%13)FDR (dB)
                    %%%%%%%%%14)Polarization (dB)
                    %%%%%%%%%15)Mitigation Reduction (dB)


                    %%%%%%%%%%Make a table:
                    % %%%%%%%%1) Uni_Id
                    % %%%%%%%%2) BS_Latitude_DD
                    % %%%%%%%%3) BS_Longitude_DD
                    % %%%%%%%%4) BS_Height_m
                    % %%%%%%%%5) Fed_Latitude_DD
                    % %%%%%%%%6) Fed_Longitude_DD
                    % %%%%%%%%7) Fed_Height_m
                    % %%%%%%%%8) BS_EIRP_dBm
                    % %%%%%%%%9) BS_EIRP_dBm Mitigation
                    %%%%%%%%%% 10:BS_to_Fed_Azimuth_Degrees
                    %%%%%%%%%% 11: BS_Sector_Azi_Degrees
                    %%%%%%%%%% 12: BS_Azi_Diff_Degrees
                    %%%%%%%%%% 13: Mod_BS_Azi_Diff_Degrees
                    %%%%%%%%%% 14: BS_Horizonal_Off_Axis_Gain_dB
                    %%%%%%%%%% 15) Path_Loss_dB
                    % %%%%%%%% 16) PowerReceived_dBm_No_Fed_Ant
                    % %%%%%%%% 17) PowerReceived_dBm_No_Fed_Ant (mitigation)

                    array_excel_data=horzcat(temp_sorted_list_data(:,5),temp_sorted_list_data(:,[1,2,3]),sim_pt.*ones(num_tx,1),temp_sorted_list_data(:,[4,8]),sorted_array_bs_azi_data,temp_sort_pathloss,temp_sort_Pr_dBm,mitigation_sort_full_Pr_dBm);
                    %%%%%%%%%array_excel_data(move_list_turn_off_idx,end+1)=1;  %%%%%%%%%%%This is just the turn off idx for the single point calculated
                    array_excel_data([1:10],:)
                    size(array_excel_data)


                    %%%%%%%%'Need to add a column where we have the on/off/mitigation with a 0/1/2. 0==off, 1==mitigation, 2=on '
                    %%%%%%%%%%%%%%%%%%%%%%%%18) Off/Mitigation/On [0,1,2]
                    %%%%%%%%%%%Find in array_excel_data(:,1) the Nick Id in mitigation_list_bs(:,5)
                    [C_off,ia_off,ib_off]=intersect(off_list_bs(:,5),array_excel_data(:,1));
                    sort_ib_off=sort(ib_off);
                    off_miti_on=NaN(num_tx,1);
                    off_miti_on(:)=2; %%%%On (no mitigation)
                    off_miti_on(sort_ib_off)=0;  %%%%Off

                    [C_miti,ia_miti,ib_miti]=intersect(mitigation_list_bs(:,5),array_excel_data(:,1));
                    sort_ib_miti=sort(ib_miti);
                    off_miti_on(sort_ib_miti)=1;  %%%%Mitigation

                    %%%%%%%%Double check the Calculation
                    indy_Pr_dBm=temp_sorted_list_data(:,4)-temp_sort_pathloss+sorted_array_bs_azi_data(:,end);
                    horzcat(temp_sort_Pr_dBm(1),indy_Pr_dBm(1))

                    temp_sort_Pr_dBm(1)-indy_Pr_dBm(1)
                    if ~all(round(temp_sort_Pr_dBm,2)==round(indy_Pr_dBm,2))
                        mismatch_idx=find(temp_sort_Pr_dBm~=indy_Pr_dBm)
                        %horzcat(round(temp_sort_Pr_dBm(mismatch_idx),2),round(indy_Pr_dBm(mismatch_idx),2))
                        horzcat(temp_sort_Pr_dBm(mismatch_idx(1)),indy_Pr_dBm(mismatch_idx(1)))
                        'Double check link budget'
                        pause;
                    end



                    %%%%%%%%%%Make a table:
                    % %%%%%%%%1) Uni_Id
                    % %%%%%%%%2) BS_Latitude_DD
                    % %%%%%%%%3) BS_Longitude_DD
                    % %%%%%%%%4) BS_Height_m
                    % %%%%%%%%5) Fed_Latitude_DD
                    % %%%%%%%%6) Fed_Longitude_DD
                    % %%%%%%%%7) Fed_Height_m
                    % %%%%%%%%8) BS_EIRP_dBm
                    % %%%%%%%%9) BS_EIRP_dBm Mitigation
                    %%%%%%%%%% 10:BS_to_Fed_Azimuth_Degrees
                    %%%%%%%%%% 11: BS_Sector_Azi_Degrees
                    %%%%%%%%%% 12: BS_Azi_Diff_Degrees
                    %%%%%%%%%% 13: Mod_BS_Azi_Diff_Degrees
                    %%%%%%%%%% 14: BS_Horizonal_Off_Axis_Gain_dB
                    %%%%%%%%%% 15) Path_Loss_dB
                    % %%%%%%%% 16) PowerReceived_dBm_No_Fed_Ant
                    % %%%%%%%% 17) PowerReceived_dBm_No_Fed_Ant (mitigation)


                    table_move_list=horzcat(array2table(array_excel_data),array2table(off_miti_on),cell2table(sort_cell_prop_mode));
                    table_move_list.Properties.VariableNames={'Uni_Id' 'BS_Latitude_DD' 'BS_Longitude_DD' 'BS_Height_m' 'Fed_Latitude_DD' 'Fed_Longitude_DD' 'Fed_Height_m' 'BS_EIRP_dBm' 'BS_EIRP_dBm_miti' 'BS_to_Fed_Azimuth_Degrees' 'BS_Sector_Azi_Degrees' 'BS_Azi_Diff_Degrees' 'Mod_BS_Azi_Diff_Degrees' 'BS_Horizonal_Off_Axis_Gain_dB' 'Path_Loss_dB'  'PowerReceived_dBm_No_Fed_Ant' 'PowerReceivedMiti_dBm_No_Fed_Ant' 'Off_Miti_On' 'Propagation_Mode'};
                    disp_progress(app,strcat('2 minutes to write Excel Files . . . '))
                    %%%%table_move_list
                    tic;
                    writetable(table_move_list,strcat(data_label1,'_Point',num2str(point_idx),'_Link_Budget_',string_prop_model,'.xlsx'));
                    toc;

                end


                %%%%%%%%%%%%%%%%%%%%%%%%%%End of Write Excel
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
    end
    delete(multi_hWaitbarMsgQueue);
    close(multi_hWaitbar);
end

