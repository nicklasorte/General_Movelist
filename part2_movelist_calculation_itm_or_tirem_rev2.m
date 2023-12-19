function part2_movelist_calculation_itm_or_tirem_rev2(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function: 
cell_status_filename=strcat('cell_',string_prop_model,'_',num2str(sim_number),'_MoveList_status.mat')  
label_single_filename=strcat(string_prop_model,'_',num2str(sim_number),'_MoveList_status')
location_table=table([1:1:length(folder_names)]',folder_names)

%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
[cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename);
zero_idx=find(cell2mat(cell_status(:,2))==0);

if ~isempty(zero_idx)==1
    temp_folder_names=folder_names(zero_idx)
    num_folders=length(temp_folder_names);
    
    %%%%%%%%Pick a random folder and go to the folder to do the sim
    disp_progress(app,strcat('Starting the Sims (Move List). . .',string_prop_model))
    %%reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.
    
    [tf_ml_toolbox]=check_ml_toolbox(app);
    if tf_ml_toolbox==1
        array_rand_folder_idx=randsample(num_folders,num_folders,false);
    else
        array_rand_folder_idx=randperm(num_folders);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder Move List: ',num_folders);    %%%%%%% Create ParFor Waitbar
        
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

                [hWaitbar_movelist,hWaitbarMsgQueue_movelist]= ParForWaitbarCreateMH_time('Move List: ',num_ppts);    %%%%%%% Create ParFor Waitbar

                %%%%%%%%%%First check for the union move list
                %%%%%%%%%First, check to see if the union of the move list exists
                file_name_union_move=strcat(string_prop_model,'_',data_label1,'_union_turn_off_list_data_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(sim_number),'_',num2str(mc_size),'.mat');
                [file_union_move_exist]=persistent_var_exist_with_corruption(app,file_name_union_move);
                if file_union_move_exist==0 %%%The File Does not exist, we will calculate it
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Move List

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate first-->Parfor --> No data load
                    if parallel_flag==1
                        parfor point_idx=1:num_ppts
                            pre_sort_movelist_rev6_string_prop_model_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model);
                            hWaitbarMsgQueue_movelist.send(0);
                        end
                    end

                    %%%%%%%%%%%Then for each point, scrap the data and save to excel. Only hold onto 1 point data at a time.
                    %%%%%%%%For this case (1 Monte Carlo Iteration), we really don't need to save most of the data, only the optimized move list order.
                    %%%%%%%%%Keep the move list flexible with the reliability inputs, so we can have multiple move lists.
                    %%%%%%%%%%In the next revision, do the full ITM reliability and do the aggregate check of the 50% ITM with the full 1-99%. (1000 MC and 95th Percentile)
                    cell_move_list_turn_off_data=cell(num_ppts,1);
                    cell_move_list_idx=cell(num_ppts,1);  %%%%%%%%%%This is used as a way to check.
                    for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
                        point_idx
                        [move_list_turn_off_idx,sort_sim_array_list_bs,sort_bs_idx,~,~,~,~]=pre_sort_movelist_rev6_string_prop_model_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model);
                        %%%%%%%%%%%%%%%%%%pre_sort_movelist_rev5_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data);
                        cell_move_list_turn_off_data{point_idx}=sort_sim_array_list_bs(move_list_turn_off_idx,:);
                        cell_move_list_idx{point_idx}=unique(sim_array_list_bs(sort_bs_idx(move_list_turn_off_idx),5));
                        %%%%'To prevent the possibility of memory issues, may need to write the excel file right here after each point. But then we cant parfor the calculation. Just load in all the data after the calculation.'

                        if parallel_flag==0
                            %%%%%%%Decrement the waitbar
                            hWaitbarMsgQueue_movelist.send(0);
                        end
                    end
                    toc;

                    delete(hWaitbarMsgQueue_movelist);
                    close(hWaitbar_movelist);

                    array_uni_nick_id_move_list_idx=unique(vertcat(cell_move_list_idx{:}));
                    union_turn_off_list_data=unique(vertcat(cell_move_list_turn_off_data{:}),'rows');

                    if ~all(unique(union_turn_off_list_data(:,5))==array_uni_nick_id_move_list_idx)
                        'Might need to check the move list idx'
                        pause;
                    end

                    %%%%%%%%'Export the union move List of the Base Stations'
                    union_turn_off_list_data(1,:)
                    [~,sort_union_idx]=sort(union_turn_off_list_data(:,5));
                    table_union_move_list=array2table(union_turn_off_list_data(sort_union_idx,[1,2,3,5,6,7,9]));
                    table_union_move_list.Properties.VariableNames={'BS_Latitude' 'BS_Longitude' 'BS_Height' 'Uni_Id' 'NLCD' 'Sector_Azi' 'EIRP'};
                    tic;
                    writetable(table_union_move_list,strcat(data_label1,'_',string_prop_model,'_Union_Move_List_OFF.xlsx'));
                    toc;

% %                     %%%%%%%%%Output the Excel Table Link Budgets
% %                     'Need to update the type of data written into the excel files'
% %                     'We may also want to make a separate function, like the prop clean up, that just focuses on writing the excel files'
% % 
% %                     if tf_write_movelist_excel==1
% %                         write_excel_movelist_rev1(app,num_ppts,move_list_reliability,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,radar_height)
% %                     end

                    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %                     %%%%%%%%%Make some graphics
                    nnan_base_polygon=base_polygon(~isnan(base_polygon(:,1)),:);
                    [tf_ml_toolbox]=check_ml_toolbox(app);
                    if tf_ml_toolbox==1
                        [idx_knn]=knnsearch(nnan_base_polygon,union_turn_off_list_data(:,[1:2]),'k',1); %%%Find Nearest Neighbor
                    else
                        [idx_knn]=nick_knnsearch(union_turn_off_list_data(:,[1:2]),nnan_base_polygon,1); %%%Find Nearest Neighbor
                    end

                    base_knn_array=nnan_base_polygon(idx_knn,:);
                    knn_dist_bound=deg2km(distance(base_knn_array(:,1),base_knn_array(:,2),union_turn_off_list_data(:,1),union_turn_off_list_data(:,2)));%%%%Calculate Distance
                    max_knn_dist=ceil(max(knn_dist_bound))

                    %%%%%%%%%%Maybe add those still on, but don't show the entire 600km radius
                    [C_on,ia_on,ib_on]=intersect(sim_array_list_bs,union_turn_off_list_data,'rows');
                    on_list_bs=sim_array_list_bs;
                    on_list_bs(ia_on,:)=[];  %%%%%%%Cut ia from A


                    %%%%%%%%%%%Find those base stations to be kept on
                    %%close all; %%%%%%%%%%%This is closing the waitbar.
                    f1=figure;
                    hold on;
                    plot(union_turn_off_list_data(:,2),union_turn_off_list_data(:,1),'sr','LineWidth',2)
                    if num_ppts>1
                        plot(base_polygon(:,2),base_polygon(:,1),'-b','LineWidth',3)
                    else
                        plot(base_polygon(:,2),base_polygon(:,1),'ob','LineWidth',3)
                    end
                    title(strcat('Max Turn Off Distance:',num2str(max_knn_dist),'km'))
                    grid on;
                    plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
                    temp_axis=axis;
                    xspan=temp_axis(2)-temp_axis(1);
                    yspan=temp_axis(4)-temp_axis(3);

% %                     temp_axis(1)=temp_axis(1)-1;
% %                     temp_axis(3)=temp_axis(3)-1;
% %                     temp_axis(2)=temp_axis(2)+1;
% %                     temp_axis(4)=temp_axis(4)+1;

                     temp_axis(1)=temp_axis(1)-0.1*xspan;
                    temp_axis(3)=temp_axis(3)-0.1*yspan;
                    temp_axis(2)=temp_axis(2)+0.1*xspan;
                    temp_axis(4)=temp_axis(4)+0.1*yspan;

                    %%%%%%%%%%Replot for the right "layering"
                    plot(on_list_bs(:,2),on_list_bs(:,1),'og','LineWidth',2)
                    plot(union_turn_off_list_data(:,2),union_turn_off_list_data(:,1),'sr','LineWidth',2)
                    if num_ppts>1
                        plot(base_polygon(:,2),base_polygon(:,1),'-b','LineWidth',3)
                    else
                        plot(base_polygon(:,2),base_polygon(:,1),'ob','LineWidth',3)
                    end
                    axis(temp_axis)
                    plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
                    filename1=strcat(data_label1,'_',string_prop_model,'_Off.png');
                    pause(0.1)
                    saveas(gcf,char(filename1))
                    pause(0.1)
                    close(f1)


                    f2=figure;
                    hold on;
                    histogram(knn_dist_bound)
                    grid on;
                    xlabel('Turn Off Distance [km]')
                    ylabel('Number of Occurrences')
                    filename1=strcat(data_label1,'_',string_prop_model,'_Histogram_Turn_Off_Distance.png');
                    pause(0.1)
                    saveas(gcf,char(filename1))
                    pause(0.1)
                    close(f2)

                    %%%%%%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation
                    retry_save=1;
                    while(retry_save==1)
                        try
                            save(file_name_union_move,'union_turn_off_list_data')
                            retry_save=0;
                        catch
                            retry_save=1;
                            pause(0.1)
                        end
                    end
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Can make this the simple move list/union Function (non-mitigations)
  

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



end