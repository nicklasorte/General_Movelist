function part0_deployment_pts_folders_cust_ant_rev2(app,sim_number,bs_eirp_reductions,rev_folder,tf_server_status,cell_sim_data,base_station_latlonheight,sim_radius_km,FreqMHz)


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

  

                f1=figure;
                geoscatter(sim_array_list_bs(:,1),sim_array_list_bs(:,2),1,'b')
                hold on;
                geoplot(sim_bound(:,1),sim_bound(:,2),'-g','LineWidth',4)
                geoplot(base_polygon(:,1),base_polygon(:,2),'or','LineWidth',3)
                grid on;
                pause(0.1)
                %%%%geobasemap landcover
                geobasemap streets-light%landcover
                f1.Position = [100 100 1200 900];
                pause(1)
                filename1=strcat('Sim_Area','_',data_label1,'.png');
                saveas(gcf,char(filename1))
                pause(0.1);
                close(f1)

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

                tf_cust_ant_idx=find(matches(data_header,'TF_Custom_Ant_Pattern'));
                tf_custom_ant_pat=temp_single_cell_sim_data{tf_cust_ant_idx}

                if tf_custom_ant_pat==1
                    col_ant_pat_str_idx=find(matches(data_header,'Antenna_Pattern_Str'));
                    temp_str_ant_pattern=temp_single_cell_sim_data{col_ant_pat_str_idx};
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Antenna Pattern
                    if matches(temp_str_ant_pattern,'itu_antenna_appendix8_annex3')
                        %%%%%%%%%ITU_AP8_AN3 %%%%2020 Appendix 8, Annex 3
                        col_ant_dia_idx=find(matches(data_header,'ant_diamter_m'));
                        temp_ant_diamter=temp_single_cell_sim_data{col_ant_dia_idx};
                        ant_diamter_m=temp_ant_diamter %%%%%meters
                        col_ant_gain_idx=find(matches(data_header,'rx_ant_gain_mb'));
                        temp_ant_gain=temp_single_cell_sim_data{col_ant_gain_idx};
                        ant_gain_dBi=temp_ant_gain; %%%%%%%%dBi
                        array_ant_phi=0:0.1:180; %%%%%%%The steps to calculate antenna pattern
                        [array_ant_gain]=itu_antenna_appendix8_annex3(app,FreqMHz,ant_diamter_m,ant_gain_dBi,array_ant_phi);

                  
                        %%%%%%%%%%%%%%Plot and Save
                        fig1=figure;
                        hold on;
                        plot(array_ant_gain(:,1),array_ant_gain(:,2),'-b')
                        xlabel('Elevation [Degree]')
                        ylabel('Antenna Gain')
                        grid on;
                        title({strcat(data_label1,': itu antenna appendix8 annex3')})
                        filename1=strcat(data_label1,'_itu_antenna_appendix8_annex3.png');
                        retry_save=1;
                        while(retry_save==1)
                            try
                                saveas(gcf,char(filename1))
                                pause(0.1);
                                retry_save=0;
                            catch
                                retry_save=1;
                                pause(0.1)
                            end
                        end
                        pause(0.1)
                        close(fig1)
                       

                        % % % % % % % % % %%%%%%%%%%%This should probably be done on the server, since the
                        % % % % % % % % % %%%%%%%%%%%antenna patterns will increase the cell_sim_data to a large
                        % % % % % % % % % %%%%%%%%%%%size

                        col_gs_azimuth_idx=find(matches(data_header,'gs_azimuth'));
                        gs_azimuth=temp_single_cell_sim_data{col_gs_azimuth_idx};
                        col_gs_elevation_idx=find(matches(data_header,'gs_elevation'));
                        gs_elevation=temp_single_cell_sim_data{col_gs_elevation_idx};

                        array_azi=0:1:360;
                        num_azi=length(array_azi);
                        array_azi_gain=NaN(num_azi,1);
                        for i=1:1:num_azi
                            temp_azi=array_azi(i);

                            %%%Find the deltas in azimuth and elevation
                            delta_azi=abs(gs_azimuth-temp_azi);
                            delta_ele=abs(gs_azimuth-gs_elevation);

                            %%%%%%%%%%%%%A simplified, worst-case calculation.
                            if delta_azi<gs_elevation
                                min_azi=gs_elevation;
                            else
                                min_azi=min(horzcat(delta_ele,delta_azi));
                            end

                            nn_idx=nearestpoint_app(app,min_azi,array_ant_gain(:,1));
                            array_azi_gain(i)=array_ant_gain(nn_idx,2);
                        end
                        custom_antenna_pattern=horzcat(array_azi',array_azi_gain);

                          %%%%%%%%%%%%%%Plot and Save
                        fig1=figure;
                        hold on;
                        plot(array_azi,array_azi_gain,'-b')
                        xlabel('Azimuth [Degree]')
                        ylabel('Antenna Gain')
                        grid on;
                        title({strcat(data_label1,':  gs azimuth:',num2str(round(gs_azimuth)),':  gs elevation:',num2str(round(gs_elevation)))})
                        filename1=strcat(data_label1,'_custom_ant_gain.png');
                        retry_save=1;
                        while(retry_save==1)
                            try
                                saveas(gcf,char(filename1))
                                pause(0.1);
                                retry_save=0;
                            catch
                                retry_save=1;
                                pause(0.1)
                            end
                        end
                        pause(0.1)
                        close(fig1)
                    else
                        'Need to add another pattern'
                        pause;
                    end
                else
                    %%%%%%%%%%Add Radar Antenna Pattern: Offset from 0 degrees and loss in dB
                    array_azi=0:1:360;
                    if ant_beamwidth==360
                        custom_antenna_pattern=array_azi';
                        custom_antenna_pattern(:,2)=0;
                    else
                         %%%%%%%%%%%Note, this is not STATGAIN
                        [radar_ant_array]=horizontal_antenna_loss_app(app,ant_beamwidth,min_ant_loss);
                        neg_ant_array=flipud(radar_ant_array([2:end],:));
                        neg_ant_array(:,1)=-1*neg_ant_array(:,1);
                        mod_neg_ant_array=neg_ant_array;
                        mod_neg_ant_array(:,1)=mod(neg_ant_array(:,1),360);

                        min_neg_azi=min(mod_neg_ant_array(:,1));
                        neg_nn1_idx=nearestpoint_app(app,min_neg_azi,array_azi,'previous'); %%%%Use this one
                        %%%%neg_nn2_idx=nearestpoint_app(app,min_neg_azi,array_azi,'next');
                        %%%%horzcat(min_neg_azi,array_azi(neg_nn1_idx),array_azi(neg_nn2_idx))

                        max_pos_azi=max(radar_ant_array(:,1));
                        pos_nn1_idx=nearestpoint_app(app,max_pos_azi,array_azi,'next'); %%%%Use this one
                        %%%%%%horzcat(max_pos_azi,array_azi(pos_nn1_idx))

                        if neg_nn1_idx<pos_nn1_idx
                            'Error on the non-custom ant pattern'
                            pause;
                        end
                        middle_piece=array_azi([pos_nn1_idx:1:neg_nn1_idx])';
                        middle_piece(:,2)=-1*min_ant_loss;
                        custom_antenna_pattern=vertcat(radar_ant_array,middle_piece,mod_neg_ant_array);                       
                    end


                    %%%%%%%%%%%%%%Plot and Save
                    fig1=figure;
                    hold on;
                    plot(custom_antenna_pattern(:,1),custom_antenna_pattern(:,2),'-b')
                    xlabel('Azimuth [Degree]')
                    ylabel('Antenna Gain')
                    grid on;
                    filename1=strcat(data_label1,'_custom_ant_gain.png');
                    retry_save=1;
                    while(retry_save==1)
                        try
                            saveas(gcf,char(filename1))
                            pause(0.1);
                            retry_save=0;
                        catch
                            retry_save=1;
                            pause(0.1)
                        end
                    end
                    pause(0.1)
                    close(fig1)
                end

                retry_save=1;
                while(retry_save==1)
                    try
                        save(strcat(data_label1,'_custom_antenna_pattern.mat'),'custom_antenna_pattern')
                        retry_save=0;
                    catch
                        retry_save=1;
                        pause(1)
                    end
                end

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
