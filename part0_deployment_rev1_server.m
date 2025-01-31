function part0_deployment_rev1_server(app,sim_number,folder_names,array_bs_latlon,sim_radius_km,deployment_percentage,rev_folder,tf_server_status)

disp_progress(app,strcat('Part0: Deployment: Line 3 . . .'))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function:
cell_status_filename=strcat('cell_',num2str(sim_number),'_deployment_status.mat')
label_single_filename=strcat('file_',num2str(sim_number),'_deployment_status')
location_table=table([1:1:length(folder_names)]',folder_names)

%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
[cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
zero_idx=find(cell2mat(cell_status(:,2))==0);
cell_status


if ~isempty(zero_idx)==1
    temp_folder_names=folder_names(zero_idx)
    num_folders=length(temp_folder_names);

    disp_progress(app,strcat('Part0: Deployment: Line 19 . . .'))
    %%%%%%%%Pick a random folder and go to the folder to do the sim
    reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.
    disp_progress(app,strcat('Part0: Deployment: Line 22 . . .'))
    [tf_ml_toolbox]=check_ml_toolbox(app);
    if tf_ml_toolbox==1
        array_rand_folder_idx=randsample(num_folders,num_folders,false);
    else
        array_rand_folder_idx=randperm(num_folders);
    end

    disp_progress(app,strcat('Part0: Deployment: Line 30 . . .'))
    temp_folder_names(array_rand_folder_idx)
    disp_randfolder(app,num2str(array_rand_folder_idx'))
    disp_progress(app,strcat('Part0: Deployment: Line 33 . . .'))
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder Deployment: ',num_folders);    %%%%%%% Create ParFor Waitbar
    disp_progress(app,strcat('Part0: Deplyoment: Line 36 . . .'))
    for folder_idx=1:1:num_folders
        %%%%%%%%Before going to the sim folder, check one last time if we
        %%%%%%%%need to go to it, since another server may have already
        %%%%%%%%checked.
        disp_progress(app,strcat('Part0: Deployment: Line 41 . . .'))
        %%%%%%%Load
        [cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
        sim_folder=temp_folder_names{array_rand_folder_idx(folder_idx)};
        temp_cell_idx=find(strcmp(cell_status(:,1),sim_folder)==1);

        if cell_status{temp_cell_idx,2}==0
            disp_progress(app,strcat('Part0: Deployment: Line 48 . . .'))
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
            data_label1=sim_folder

            disp_progress(app,strcat('Part0: Deployment: Line 79:',data_label1))

            %%%%%%Check for the tf_complete_ITM file
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
                disp_progress(app,strcat('Part0: Deployment: Line 95:',data_label1))
                %%%%%%%%Update the Cell
                [cell_status]=update_generic_status_cell_rev1(app,folder_names,sim_folder,cell_status_filename);
            else
                %%%%%Persistent Load the other variables
                disp_progress(app,strcat('Part0 Deployment: Loading Sim Data: Line 100  . . .'))
                retry_load=1;
                while(retry_load==1)
                    try
                        %%%%disp_progress(app,strcat('Loading Sim Data . . . '))
                        load(strcat(data_label1,'_base_polygon.mat'),'base_polygon')
                        temp_data=base_polygon;
                        clear base_polygon;
                        base_polygon=temp_data;
                        clear temp_data;

                        retry_load=0;
                    catch
                        retry_load=1;
                        pause(0.1)
                    end
                end


                %%%array_bs_latlon%%%%%%%%%%%%%Nationwide: %%%%%%%1)Lat, 2)Lon, 3)Azimuth, 4)Height, 5)EIRP, 6)Mitigation EIRP
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Sim Bound/contour_latlon
                if any(isnan(base_polygon))
                    nan_base_polygon=base_polygon(~isnan(base_polygon(:,1)),:);
                else
                    nan_base_polygon=base_polygon;
                end
                [contour_latlon]=calc_sim_bound(app,nan_base_polygon,sim_radius_km,data_label1);

                %%%%%%%Filter Base Stations that are within sim_bound/contour_latlon
                tic;
                [inside_idx]=find_points_inside_contour(app,contour_latlon,array_bs_latlon(:,[1,2]));
                toc;
                temp_sim_bs_data=array_bs_latlon(inside_idx,:);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Downsample deployment
                if deployment_percentage==100
                    %%%%%%%%Nothing
                else
                    [num_inside,~]=size(inside_idx)
                    sample_num=ceil(num_inside*deployment_percentage/100)
                    rng(sim_number+folder_idx); %%%%%%%For Repeatibility
                    rand_sample_idx=datasample(1:num_inside,sample_num,'Replace',false);
                    size(temp_sim_bs_data)
                    temp_sim_bs_data=temp_sim_bs_data(rand_sample_idx,:);
                    size(temp_sim_bs_data)
                    'Need to check without ML toolbox'
                    pause;
                end

                f1=figure;
                AxesH = axes;
                hold on;
                scatter(temp_sim_bs_data(:,2),temp_sim_bs_data(:,1),1,'b')
                plot(contour_latlon(:,2),contour_latlon(:,1),':r','LineWidth',3)
                plot(base_polygon(:,2),base_polygon(:,1),'dm','Linewidth',4)
                grid on;
                plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
                filename1=strcat('Sim_Area_Deployment1_',data_label1,'.png');
                pause(0.1)
                saveas(gcf,char(filename1))
                pause(0.1)
                close(f1)

                %%%array_bs_latlon%%%%%%%%%%%%%Nationwide: %%%%%%%1)Lat, 2)Lon, 3)Azimuth, 4)Height, 5)EIRP, 6)Mitigation EIRP, 7)NLCD
                %%%%%%%sim_array_list_bs %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP Adjusted 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation
                %%%%%%%%If there is no mitigation EIRPs, make all of these NaNs (column 8)
                %%%%%%%%%%%%%%%%%%%%Column #6  is used to correlate for the aas norm data


                [num_tx,~]=size(temp_sim_bs_data)
                sim_array_list_bs=NaN(1,1);
                sim_array_list_bs=temp_sim_bs_data(:,[1,2]);
                sim_array_list_bs(:,7)=temp_sim_bs_data(:,3);
                sim_array_list_bs(:,3)=temp_sim_bs_data(:,4);
                sim_array_list_bs(:,4)=temp_sim_bs_data(:,5);
                sim_array_list_bs(:,8)=temp_sim_bs_data(:,6);
                sim_array_list_bs(:,6)=temp_sim_bs_data(:,7);
                sim_array_list_bs(:,5)=[1:1:num_tx];

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
                server_status_rev2(app,tf_server_status)
            end
        end
        multi_hWaitbarMsgQueue.send(0);
    end
    delete(multi_hWaitbarMsgQueue);
    close(multi_hWaitbar);
end

end
