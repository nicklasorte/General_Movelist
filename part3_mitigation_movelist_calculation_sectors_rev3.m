function part3_mitigation_movelist_calculation_sectors_rev3(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function:
cell_status_filename=strcat('cell_',string_prop_model,'_',num2str(sim_number),'_MitigationML_status.mat')
label_single_filename=strcat(string_prop_model,'_',num2str(sim_number),'_MitigationML_status')
location_table=table([1:1:length(folder_names)]',folder_names)

%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
[cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
zero_idx=find(cell2mat(cell_status(:,2))==0);

if ~isempty(zero_idx)==1
    temp_folder_names=folder_names(zero_idx)
    num_folders=length(temp_folder_names);

    %%%%%%%%Pick a random folder and go to the folder to do the sim
    disp_progress(app,strcat('Starting the Sims (Mitigation ML). . .',string_prop_model))
    reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.

    [tf_ml_toolbox]=check_ml_toolbox(app);
    if tf_ml_toolbox==1
        array_rand_folder_idx=randsample(num_folders,num_folders,false);
    else
        array_rand_folder_idx=randperm(num_folders);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder Mitigation ML: ',num_folders);    %%%%%%% Create ParFor Waitbar

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
                disp_progress(app,strcat('Starting the Move List . . . '))
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

                [hWaitbar_movelist,hWaitbarMsgQueue_movelist]= ParForWaitbarCreateMH_time('Mitigation Move List: ',num_ppts);    %%%%%%% Create ParFor Waitbar

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%First check if there are mitigation EIRPs (column 8)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%If there is no mitigation EIRPs, all of these will be NaNs (column 8)
                %%%%%%%%%%I don't know what we will do if they are all nan,
                %%%%%%%%%%will cross that bridge when we get there.
                if any(isnan(sim_array_list_bs(:,8)))
                    'There is no mitigation and so its a straight move list'
                    pause;

                elseif  ~all(isnan(sim_array_list_bs(:,8)))
                    file_name_union_move_miti_off=strcat(data_label1,'_',string_prop_model,'_mitigation_union_turn_off_list_data_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(sim_number),'_',num2str(mc_size),'.mat');
                    file_name_union_move_miti_miti=strcat(data_label1,'_',string_prop_model,'_mitigation_union_mitigation_list_data_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(sim_number),'_',num2str(mc_size),'.mat');
                    [file_union_move_exist_mit1]=persistent_var_exist_with_corruption(app,file_name_union_move_miti_off);
                    [file_union_move_exist_mit2]=persistent_var_exist_with_corruption(app,file_name_union_move_miti_off);

                    if file_union_move_exist_mit1==2 && file_union_move_exist_mit2==2

                    else
                        %%%The File Does not exist, we will calculate it
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Move List
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate first-->Parfor --> No data load
                        if parallel_flag==1
                            disp_progress(app,strcat('Starting the Parfor Mitigation Move List'))
                            parfor point_idx=1:num_ppts
                                pre_sort_mitigation_movelist_new_AAS_rev8_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model);
                                hWaitbarMsgQueue_movelist.send(0);
                            end

                        end

                        %%%%%%%%%Keep the move list flexible with the reliability inputs, so we can have multiple move lists.
                        %%%%%%%%%%In the next revision, do the full ITM reliability and do the aggregate check of the 50% ITM with the full 1-99%. (1000 MC and 95th Percentile)
                        cell_mitigation_move_list_turn_off_data=cell(num_ppts,1);  %%%%%%%%%Off
                        cell_mitigation_move_list_mitigation_data=cell(num_ppts,1);    %%%%%%Mitigations
                        for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
                            point_idx
                            [off_list_bs,mitigation_list_bs,mitigation_sort_sim_array_list_bs,mitigation_sort_bs_idx]=pre_sort_mitigation_movelist_new_AAS_rev8_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model);

                            cell_mitigation_move_list_turn_off_data{point_idx}=off_list_bs;
                            cell_mitigation_move_list_mitigation_data{point_idx}=mitigation_list_bs;
                            if parallel_flag==0
                                %%%%%%%Decrement the waitbar
                                hWaitbarMsgQueue_movelist.send(0);
                            end
                        end
                        toc;

                        delete(hWaitbarMsgQueue_movelist);
                        close(hWaitbar_movelist);

                        mitigation_union_turn_off_list_data=unique(vertcat(cell_mitigation_move_list_turn_off_data{:}),'rows');
                        mitigation_union_mitigation_list_data=unique(vertcat(cell_mitigation_move_list_mitigation_data{:}),'rows');

                        %%%%%%%%First check if there are any overlap between the off and mitigation list.
                        %%%%%%%%%Change them to just the off list
                        [C,ia,ib]=intersect(mitigation_union_turn_off_list_data,mitigation_union_mitigation_list_data,'rows');

                        %%%%%%%%%C = A(ia) and C = B(ib).
                        all(mitigation_union_turn_off_list_data(ia,5)==mitigation_union_mitigation_list_data(ib,5))

                        %%%%%%Cut ib from B
                        size(mitigation_union_mitigation_list_data)
                        mitigation_union_mitigation_list_data(ib,:)=[];
                        size(mitigation_union_mitigation_list_data)


                        %%%%%%%%'Export the union move List of the Base Stations'
                        mitigation_union_turn_off_list_data(1,:)
                        [~,sort_union_idx]=sort(mitigation_union_turn_off_list_data(:,5));
                        table_union_move_list_off=array2table(mitigation_union_turn_off_list_data(sort_union_idx,[1,2,3,5,6,7,8]));
                        table_union_move_list_off.Properties.VariableNames={'BS_Latitude' 'BS_Longitude' 'BS_Height' 'Uni_Id' 'NLCD' 'Sector_Azi' 'EIRP'};
                        tic;
                        writetable(table_union_move_list_off,strcat(data_label1,'_',string_prop_model,'_Union_Move_List_Mitigation.xlsx'),'Sheet','Turn_Off');
                        toc;


                        %%%%%%%%'Export the union move List of the Base Stations'
                        mitigation_union_mitigation_list_data(1,:)
                        [~,sort_union_idx]=sort(mitigation_union_mitigation_list_data(:,5));
                        table_union_move_list_miti=array2table(mitigation_union_mitigation_list_data(sort_union_idx,[1,2,3,5,6,7,8]));
                        table_union_move_list_miti.Properties.VariableNames={'BS_Latitude' 'BS_Longitude' 'BS_Height' 'Uni_Id' 'NLCD' 'Sector_Azi' 'EIRP'};
                        tic;
                        writetable(table_union_move_list_miti,strcat(data_label1,'_',string_prop_model,'_Union_Move_List_Mitigation.xlsx'),'Sheet','Mitigation');
                        toc;


                        %%%%%%%%%%Maybe add those still on, but don't show the entire 600km radius
                        miti_off_data=unique(vertcat(mitigation_union_turn_off_list_data,mitigation_union_mitigation_list_data),'rows');
                        [C_on,ia_on,ib_on]=intersect(sim_array_list_bs,miti_off_data,'rows');
                        on_list_bs=sim_array_list_bs;
                        on_list_bs(ia_on,:)=[];  %%%%%%%Cut ia from A

                        size(sim_array_list_bs)
                        size(on_list_bs)
                        size(miti_off_data)

                        % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %                     %%%%%%%%%Make some graphics
                        %%%%%%%%%%%%%%Calculate the Max Turn Off Distance
                        [knn_dist_bound_off,max_knn_dist_off]=calc_knn_dist_rev1(app,base_polygon,mitigation_union_turn_off_list_data);

                        %%%%%%%%%%%%%%Calculate the Max Mitigation Distance
                        [knn_dist_bound_miti,max_knn_dist_miti]=calc_knn_dist_rev1(app,base_polygon,mitigation_union_mitigation_list_data);

                        %%%%%%%%%%%%%%Calculate the knn ON distance
                        [knn_dist_bound_on,max_knn_dist_on]=calc_knn_dist_rev1(app,base_polygon,on_list_bs);

                        max_dist=max(horzcat(max_knn_dist_off,max_knn_dist_miti,max_knn_dist_on))


                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Plot
                        tic;
                        plot_miti_sectors_rev1_app(app,data_label1,string_prop_model,mitigation_union_mitigation_list_data,mitigation_union_turn_off_list_data,base_polygon,on_list_bs,max_knn_dist_off,max_knn_dist_miti)
                        toc;

                        %%%%%%%%%%Plot the bar graph, x-axis knn distance,
                        %%%%%%%%%%with Red/Yellow/Green as on/miti/off
                    
                        %%%%%%%%%Need to find the knndistance for each sector
                        %%%%%'Bar graph'
                        plot_stacked_bar_on_off_miti_rev1(app,knn_dist_bound_off,knn_dist_bound_miti,knn_dist_bound_on,data_label1,string_prop_model)


                        retry_save=1;
                        while(retry_save==1)
                            try
                                save(file_name_union_move_miti_off,'mitigation_union_turn_off_list_data')
                                save(file_name_union_move_miti_miti,'mitigation_union_mitigation_list_data')
                                retry_save=0;
                            catch
                                retry_save=1;
                                pause(0.1)
                            end
                        end
                    end
                else
                    'Some other logic to figure out.'
                    pause;
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End of the mitigations (COA 1 & 2) Move List/Union Function


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





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


