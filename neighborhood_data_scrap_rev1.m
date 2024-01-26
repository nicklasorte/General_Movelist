function neighborhood_data_scrap_rev1(app,folder_names,rev_folder,sim_number,string_prop_model)



cell_status_filename=strcat('cell_neighborhood_data',string_prop_model,'_',num2str(sim_number),'.mat')
location_table=table([1:1:length(folder_names)]',folder_names)

%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
%%%%%[cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
[cell_status]=initialize_or_load_neighborhood_data_rev1(app,folder_names,cell_status_filename);
zero_idx=find(cell2mat(cell_status(:,2))==0);


%%%%%%%%%%%%%%%%%%%%Instead of status file, the data with the neighborhood
%%%%%%%%%%%%%%%%%%%%distance will be the status file
%%%% 1) Name and 2)0/1 3)Neighborhood Distnace 4)Move List Size 5)All Binary Data


if ~isempty(zero_idx)==1
    temp_folder_names=folder_names(zero_idx)
    num_folders=length(temp_folder_names);

    %%%%%%%%Pick a random folder and go to the folder to do the sim
    %%%reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.

    [tf_ml_toolbox]=check_ml_toolbox(app);
    if tf_ml_toolbox==1
        array_rand_folder_idx=randsample(num_folders,num_folders,false);
    else
        array_rand_folder_idx=randperm(num_folders);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder Scrap Data: ',num_folders);    %%%%%%% Create ParFor Waitbar

    for folder_idx=1:1:num_folders
        %%%%%%%%Before going to the sim folder, check one last time if we
        %%%%%%%%need to go to it, since another server may have already
        %%%%%%%%checked.

        %%%%%%%Load
        %%%%%[cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
        [cell_status]=initialize_or_load_neighborhood_data_rev1(app,folder_names,cell_status_filename);
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


            %%%%%Persistent Load the other variables
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

                    retry_load=0;
                catch
                    retry_load=1;
                    pause(0.1)
                end
            end

            CBSD_label='BaseStation';
            pre_label=CBSD_label;



            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load the Data
            file_name_cell=strcat(pre_label,'_',data_label1,'_',num2str(sim_number),'_all_data_stats_binary.mat');
            [var_exist_cell]=persistent_var_exist(app,file_name_cell);
            if var_exist_cell==2 %%%%%%%%Load
                retry_load=1;
                while(retry_load==1)
                    try
                        load(file_name_cell,'all_data_stats_binary')
                        retry_load=0;
                    catch
                        retry_load=1;
                        pause(0.1)
                    end
                end
            else
                disp_progress(app,strcat('Error: No Data all_data_stats_binary'))
                pause;
            end


            %%%%%%First Check to See if we Processed It
            temp_catb_filename=strcat(CBSD_label,'_',data_label1,'_catb_neighborhood_radius.mat');
            [var_exist_radius]=persistent_var_exist(app,temp_catb_filename);
            if var_exist_radius==2
                retry_load=1;
                while(retry_load==1)
                    try
                        load(temp_catb_filename,'catb_neighborhood_radius')
                        retry_load=0;
                    catch
                        retry_load=1;
                        pause(0.1)
                    end
                end
            else
                disp_progress(app,strcat('Error: No Data catb_neighborhood_radius'))
                pause;
            end

            single_data=all_data_stats_binary{1}
            catb_neighborhood_radius

            dist_idx=find(single_data(:,1)==catb_neighborhood_radius)
            move_list_size=single_data(dist_idx,3)


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
            %%%%[cell_status]=update_generic_status_cell_rev1(app,folder_names,sim_folder,cell_status_filename);


            %%%%%%%Load
            %%%%[cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename)
            [cell_status]=initialize_or_load_neighborhood_data_rev1(app,folder_names,cell_status_filename);

            %%%%%Find the idx
            temp_cell_idx=find(strcmp(cell_status(:,1),sim_folder)==1);

            %%%%%%%Update the Cell
            cell_status{temp_cell_idx,2}=1;
            cell_status{temp_cell_idx,3}=catb_neighborhood_radius;
            cell_status{temp_cell_idx,4}=move_list_size;
            cell_status{temp_cell_idx,5}=all_data_stats_binary;
           
            %%%% 1) Name and 2)0/1 3)Neighborhood Distance 4)Move List Size 5)All Binary Data

            %%%%%Save the Cell
            retry_save=1;
            while(retry_save==1)
                try
                    save(cell_status_filename,'cell_status')
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(0.1)
                end
            end

        end
        multi_hWaitbarMsgQueue.send(0);
    end
    delete(multi_hWaitbarMsgQueue);
    close(multi_hWaitbar);
end