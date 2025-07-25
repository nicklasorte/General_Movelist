function part0_deployment_pts_folders_rev1(app,sim_number,bs_eirp_reductions,rev_folder,tf_server_status,cell_sim_data,base_station_latlonheight,sim_radius_km)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function:
server_status_rev2(app,tf_server_status)
cell_status_filename=strcat('cell_',num2str(sim_number),'_grid_points_status.mat')
label_single_filename=strcat('file_',num2str(sim_number),'_grid_points_status')
checkout_filename=strcat('TF_checkout',num2str(sim_number),'_grid_points_status.mat')


%%%%%%%%%%%%%Need to feed in the the folder names we need
data_label_idx=find(matches(cell_sim_data(1,:),'data_label1'));
create_folder_names=cell_sim_data(2:end,data_label_idx);

tf_update_cell_status=0;
sim_folder='';  %%%%%Empty sim_folder to not update.
[cell_status]=checkout_cell_status_rev1(app,checkout_filename,cell_status_filename,sim_folder,create_folder_names,tf_update_cell_status);

%%%[cell_status]=initialize_or_load_generic_status_expand_rev3(app,cell_status_filename,create_folder_names);
zero_idx=find(cell2mat(cell_status(:,2))==0);
size(create_folder_names)
size(cell_status)
size(zero_idx)


% % % %%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
% % % %[cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
% % % [cell_status,folder_names]=initialize_or_load_generic_status_expand_rev2(app,rev_folder,cell_status_filename);
% % % zero_idx=find(cell2mat(cell_status(:,2))==0);
% % % cell_status


if ~isempty(zero_idx)==1
    temp_folder_names=create_folder_names(zero_idx);
    num_folders=length(temp_folder_names);

    %%%%%%%%Pick a random folder and go to the folder to do the sim
    reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.
    [tf_ml_toolbox]=check_ml_toolbox(app);
    if tf_ml_toolbox==1
        array_rand_folder_idx=randsample(num_folders,num_folders,false);
    else
        array_rand_folder_idx=randperm(num_folders);
    end
    temp_folder_names(array_rand_folder_idx)
    disp_randfolder(app,num2str(array_rand_folder_idx'))
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder Grid Points: ',num_folders);    %%%%%%% Create ParFor Waitbar
    for folder_idx=1:1:num_folders
        disp_TextArea_PastText(app,strcat('Part0 Grid Points:',num2str(num_folders-folder_idx)))
        %%%%%%%%Before going to the sim folder, check one last time if we
        %%%%%%%%need to go to it, since another server may have already
        %%%%%%%%checked.
        %%%%%%%%%%%%%%%%%%%%%%This might be killing us with this cell_status check. 

         %%%%%%%%%%%%%%Check cell_status
        tf_update_cell_status=0;
        sim_folder='';
        [cell_status]=checkout_cell_status_rev1(app,checkout_filename,cell_status_filename,sim_folder,create_folder_names,tf_update_cell_status);

        sim_folder=temp_folder_names{array_rand_folder_idx(folder_idx)};
        temp_cell_idx=find(strcmp(cell_status(:,1),sim_folder)==1);

        % % %%%%%%%Load
        % % [cell_status]=initialize_or_load_generic_status_while_rev4_debug(app,create_folder_names,cell_status_filename);  
        % % sim_folder=temp_folder_names{array_rand_folder_idx(folder_idx)};
        % % temp_cell_idx=find(strcmp(cell_status(:,1),sim_folder)==1);

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

            %%%%%%Check to see if we need to make a new folder
            [~,folder_names,~]=check_rev_folders(app,rev_folder);
            folder_row_idx=find(matches(folder_names,sim_folder));
            if isempty(folder_row_idx)
                %%%%%'Create the folder'
                status=0;
                while status==0
                    [status,msg,msgID]=mkdir(sim_folder);
                end
            end

            %%%%%%%%%%%%%%Go to the folder
            retry_cd=1;
            while(retry_cd==1)
                try
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

            %%%%%%Check for the tf_complete file
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
                %%%%%%%%Update the cell_status
                %%%%[cell_status]=update_generic_status_cell_rev1(app,folder_names,sim_folder,cell_status_filename);
                %[~]=update_generic_status_cell_rev1_debug(app,create_folder_names,sim_folder,cell_status_filename); 

                %%%%%%%%Update the cell_status
                tf_update_cell_status=1;
                tic;
                [~]=checkout_cell_status_rev1(app,checkout_filename,cell_status_filename,sim_folder,create_folder_names,tf_update_cell_status);
                toc;
            else
                data_row_idx=find(matches(cell_sim_data(:,1),sim_folder));
                if isempty(data_row_idx)
                    disp_progress(app,strcat('Pause Error: Data is not there in the cell_sim_data. . . '))
                    pause;
                end
                temp_single_cell_sim_data=cell_sim_data(data_row_idx,:);
                data_header=cell_sim_data(1,:)';


                %%%%%%%%%%Check for data, at least save it.               
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                pp_pt_idx=find(matches(data_header,'base_protection_pts'))
                base_protection_pts=temp_single_cell_sim_data{pp_pt_idx}
                filename_base_protection_pts=strcat(data_label1,'_base_protection_pts.mat');
                [var_exist_pp_pts]=persistent_var_exist_with_corruption(app,filename_base_protection_pts);
                if var_exist_pp_pts~=2
                    retry_save=1;
                    while(retry_save==1)
                        try
                            save(filename_base_protection_pts,'base_protection_pts')
                            pause(0.1);
                            retry_save=0;
                        catch
                            retry_save=1;
                            pause(0.1)
                        end
                    end
                end

                poly_idx=find(matches(data_header,'base_polygon'))
                base_polygon=temp_single_cell_sim_data{poly_idx};
                filename_base_polygon=strcat(data_label1,'_base_polygon.mat');
                [var_exist_base_poly]=persistent_var_exist_with_corruption(app,filename_base_polygon);
                if var_exist_base_poly~=2
                    retry_save=1;
                    while(retry_save==1)
                        try
                            save(filename_base_polygon,'base_polygon')
                            pause(0.1);
                            retry_save=0;
                        catch
                            retry_save=1;
                            pause(0.1)
                        end
                    end
                end

            
                %%%%%%%%Sim Bound
                base_polygon=base_polygon(~isnan(base_polygon(:,1)),:);
                [sim_bound]=calc_sim_bound(app,base_polygon,sim_radius_km,data_label1);

                %%%%%%%Filter Base Stations that are within sim_bound
                tic;
                bs_inside_idx=find(inpolygon(base_station_latlonheight(:,2),base_station_latlonheight(:,1),sim_bound(:,2),sim_bound(:,1))); %Check to see if the points are in the polygon
                toc;
                size(bs_inside_idx)
                sim_array_list_bs=base_station_latlonheight(bs_inside_idx,:);
                [num_tx,~]=size(sim_array_list_bs)
                sim_array_list_bs(:,4)=bs_eirp_reductions;
                sim_array_list_bs(:,5)=1:1:num_tx;
                sim_array_list_bs(:,6)=1;
                sim_array_list_bs(:,7)=0;
                % % %      %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP Adjusted 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation

                retry_save=1;
                while(retry_save==1)
                    try
                        save(strcat(data_label1,'_sim_array_list_bs.mat'),'sim_array_list_bs')
                        retry_save=0;
                    catch
                        retry_save=1;
                        pause(1)
                    end
                end
           
                % % % % %%%%%%%%%%%%Downsample deployment
                % % % % [num_inside,~]=size(bs_inside_idx)
                % % % % sample_num=ceil(num_inside*deployment_percentage/100)
                % % % % rng(sim_number); %%%%%%%For Repeatibility
                % % % % rand_sample_idx=datasample(1:num_inside,sample_num,'Replace',false);
                % % % % size(temp_sim_cell_bs_data)
                % % % % temp_sim_cell_bs_data=temp_sim_cell_bs_data(rand_sample_idx,:);
                % % % % size(temp_sim_cell_bs_data)
                % % % % temp_lat_lon=cell2mat(temp_sim_cell_bs_data(:,[5,6]));


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%Step 0. Calculate the pathloss as a function of azimuth
                min_azi_idx=find(matches(data_header,'min_azimuth'));
                min_azimuth=temp_single_cell_sim_data{min_azi_idx}

                max_azi_idx=find(matches(data_header,'max_azimuth'));
                max_azimuth=temp_single_cell_sim_data{max_azi_idx}

                ant_bw_idx=find(matches(data_header,'ant_hor_beamwidth'));
                ant_beamwidth=temp_single_cell_sim_data{ant_bw_idx}

                min_ant_idx=find(matches(data_header,'min_ant_loss'));
                min_ant_loss=temp_single_cell_sim_data{min_ant_idx}%     % % 12) Main to side gain:

               dpa_threshold_idx=find(matches(data_header,'dpa_threshold'));
               dpa_threshold=temp_single_cell_sim_data{dpa_threshold_idx}

                retry_save=1;
                while(retry_save==1)
                    try
                        save(strcat(data_label1,'_dpa_threshold.mat'),'dpa_threshold')
                        save(strcat(data_label1,'_ant_beamwidth.mat'),'ant_beamwidth')
                        save(strcat(data_label1,'_min_ant_loss.mat'),'min_ant_loss')
                        save(strcat(data_label1,'_min_azimuth.mat'),'min_azimuth')
                        save(strcat(data_label1,'_max_azimuth.mat'),'max_azimuth')
                        retry_save=0;
                    catch
                        retry_save=1;
                        pause(1)
                    end
                end

    
                % % %      %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation         

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
                %%%%%%%%Update the cell_status
                %%%%[cell_status]=update_generic_status_cell_rev1(app,folder_names,sim_folder,cell_status_filename);
                %%%[~]=update_generic_status_cell_rev1_debug(app,create_folder_names,sim_folder,cell_status_filename); 
                 %%%%%%%%Update the cell_status
                tf_update_cell_status=1;
                tic;
                [~]=checkout_cell_status_rev1(app,checkout_filename,cell_status_filename,sim_folder,create_folder_names,tf_update_cell_status);
                toc;
                server_status_rev2(app,tf_server_status)
            end
        end
        multi_hWaitbarMsgQueue.send(0);
    end
    delete(multi_hWaitbarMsgQueue);
    close(multi_hWaitbar);


    %%%%%%%%%%If we make it here, just mark all the cell_status as complete
    finish_cell_status_rev1(app,rev_folder,cell_status_filename)
end
server_status_rev2(app,tf_server_status)