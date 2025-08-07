function part2_neigh_calc_rev5_azi_geoplots_custant_excel(app,parallel_flag,rev_folder,workers,move_list_reliability,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,sim_radius_km,min_binaray_spacing,margin,maine_exception,tf_full_binary_search,agg_check_reliability,tf_opt,tf_recalculate,tf_server_status,tf_print_excel)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check for the Number of Folders to Sim
[sim_number,folder_names,~]=check_rev_folders(app,rev_folder);

%%%%%%%%%%%%%'If you get an error here, move the Tirem dlls to here'
[tf_tirem_error]=check_tirem_rev1(app,string_prop_model)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function:
cell_status_filename=strcat('cell_',string_prop_model,'_',num2str(sim_number),'_Neighborhood_status.mat')
label_single_filename=strcat(string_prop_model,'_',num2str(sim_number),'_Neighborhood_status')
checkout_filename=strcat('TF_checkout_',string_prop_model,'_',num2str(sim_number),'_dll_status.mat')
%location_table=table([1:1:length(folder_names)]',folder_names)

%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
tf_update_cell_status=0;
sim_folder='';  %%%%%Empty sim_folder to not update.
[cell_status]=checkout_cell_status_rev1(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status);
if tf_recalculate==1
    cell_status(:,2)=num2cell(0);
end
zero_idx=find(cell2mat(cell_status(:,2))==0);
cell_status

if ~isempty(zero_idx)==1
    temp_folder_names=folder_names(zero_idx)
    num_folders=length(temp_folder_names);

    %%%%%%%%Pick a random folder and go to the folder to do the sim
    disp_progress(app,strcat('Neighborhood Calc 1: Line 18:',string_prop_model))
    reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.

    [tf_ml_toolbox]=check_ml_toolbox(app);
    if tf_ml_toolbox==1
        array_rand_folder_idx=randsample(num_folders,num_folders,false);
    else
        array_rand_folder_idx=randperm(num_folders);
    end

    temp_folder_names(array_rand_folder_idx)
    disp_randfolder(app,num2str(array_rand_folder_idx'))
    %%%%%pause;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder Binary Search: ',num_folders);    %%%%%%% Create ParFor Waitbar

    for folder_idx=1:1:num_folders
        server_status_rev2(app,tf_server_status)
        disp_progress(app,strcat('Neighborhood Calc 1: Line 37: folder_idx: ',num2str(folder_idx)))
        %%%%%%%%Before going to the sim folder, check one last time if we
        %%%%%%%%need to go to it, since another server may have already
        %%%%%%%%checked.

        %%%%%%%%%%%%%%Check cell_status
        tf_update_cell_status=0;
        sim_folder='';
        [cell_status]=checkout_cell_status_rev1(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status);
        disp_TextArea_PastText(app,strcat('neighborhood_calc_rev4_azimuths_geoplots_custant: After Checkout: Line 64'))

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

            %%%%%%Check for the tf_complete_ITM file
            complete_filename=strcat(data_label1,'_',label_single_filename,'.mat'); %%%This is a marker for me
            [var_exist]=persistent_var_exist_with_corruption(app,complete_filename);
            if tf_recalculate==1
                var_exist=0
            end

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
                tf_update_cell_status=1;
                tic;
                [~]=checkout_cell_status_rev1(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status);
                toc;
            else
                server_status_rev2(app,tf_server_status)
                disp_progress(app,strcat('Neighborhood Calc 1: Line 97: Loading Data . . . '))
                %%%%%%%%%%%%%%%%CBSD Neighborhood Search Parameters
                %%%%%Persistent Load the other variables
                retry_load=1;
                while(retry_load==1)
                    try
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

                        load(strcat(data_label1,'_ant_beamwidth.mat'),'ant_beamwidth')
                        temp_data=ant_beamwidth;
                        clear ant_beamwidth;
                        ant_beamwidth=temp_data;
                        clear temp_data;
                        radar_beamwidth=ant_beamwidth;

                        load(strcat(data_label1,'_min_ant_loss.mat'),'min_ant_loss')
                        temp_data=min_ant_loss;
                        clear min_ant_loss;
                        min_ant_loss=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_dpa_threshold.mat'),'dpa_threshold')
                        temp_data=dpa_threshold;
                        clear dpa_threshold;
                        dpa_threshold=temp_data;
                        clear temp_data;
                        radar_threshold=dpa_threshold;

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

                        load(strcat(data_label1,'_custom_antenna_pattern.mat'),'custom_antenna_pattern')
                        temp_data=custom_antenna_pattern;
                        clear custom_antenna_pattern;
                        custom_antenna_pattern=temp_data;
                        clear temp_data;

                        retry_load=0;
                    catch
                        retry_load=1;
                        pause(0.1)
                        'custom_antenna_pattern may not exist'
                    end
                end


                % % fig1=figure;
                % % hold on;
                % % plot(custom_antenna_pattern(:,1),custom_antenna_pattern(:,2),'-b')
                % % xlabel('Azimuth [Degree]')
                % % ylabel('Antenna Gain')
                % % grid on;


                %%%%%%%%%%Binary Search
                [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                [num_ppts,~]=size(base_protection_pts);
                max_number_calc=sim_radius_km/min_binaray_spacing
                disp_progress(app,strcat('Neighborhood Calc 1: Line 172: ', num2str(max_number_calc)))

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                [hWaitbar_binary,hWaitbarMsgQueue_binary]= ParForWaitbarCreateMH_time('Binary Search: ',max_number_calc);    %%%%%%% Create ParFor Waitbar, this one covers points and chunks

                binary_dist_array=[1,2,4,8,16,32,64,128,256,512,1024];
                CBSD_label='BaseStation';
                [nn_idx]=nearestpoint_app(app,sim_radius_km,binary_dist_array,'next');
                bs_neighborhood=binary_dist_array(nn_idx);
                search_dist_array=horzcat(0:min_binaray_spacing:bs_neighborhood);


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Start of Binary Search
                %%%%%%%Check for all_data_stats_binary, if none, initialize it.
                [all_data_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,CBSD_label);
                disp_progress(app,strcat('Neighborhood Calc 1: Line 178: loaded all_data_stats_binary'))


                binary_marker=0;
                tf_search=1;
                while(tf_search==1)
                    server_status_rev2(app,tf_server_status)
                    disp_progress(app,strcat('Neighborhood Calc 1: Line 184: Top of While Loop: tf_search:',num2str(tf_search)))
                    binary_marker=binary_marker+1;
                    if binary_marker==1
                        single_search_dist=max(search_dist_array)
                        temp_data=all_data_stats_binary{1}; %%%%%Check if that distance is in the all_data_stats_binary
                        if isempty(temp_data)==1 %%%%%%%%Because if this is the first time, it will be empty
                            temp_data_dist=NaN(1);
                        else
                            temp_data_dist=temp_data(:,1);
                        end
                    elseif binary_marker==2
                        single_search_dist=min(search_dist_array)
                        temp_data=all_data_stats_binary{1}; %%%%Check if that distance is in the all_data_stats_binary
                        temp_data_dist=temp_data(:,1);
                    else
                        single_search_dist=next_single_search_dist
                        temp_data=all_data_stats_binary{1}; %%%%%Check if that distance is in the all_data_stats_binary
                        temp_data_dist=temp_data(:,1);
                    end
                    disp_progress(app,strcat('Neighborhood Calc 1: Line 205: Search Distance:',num2str(single_search_dist),'km'))

                    if any(temp_data_dist==single_search_dist)==1
                        %%%%%%%%Already calculated
                    else
                        %%%%%%%%Calculate
                        disp_progress(app,strcat('Neighborhood Calc 1: Line 210: Search Distance:',num2str(single_search_dist),'km'))

                        file_name_single_scrap_data=strcat(CBSD_label,'_',data_label1,'_',num2str(sim_number),'_single_scrap_data_',num2str(single_search_dist),'.mat'); %%%%%%First Check for an array file, named with the single_search_dist and has all the aggregate checks for each protection point.
                        [var_exist_single_scrap_data]=persistent_var_exist_with_corruption(app,file_name_single_scrap_data);

                        if var_exist_single_scrap_data==2
                            disp_progress(app,strcat('Neighborhood Calc 1: Line 216: Loading single_scrap_data:',num2str(single_search_dist),'km'))
                            retry_load=1;
                            while(retry_load==1)
                                try
                                    load(file_name_single_scrap_data,'single_scrap_data')
                                    retry_load=0;
                                catch
                                    retry_load=1;
                                    pause(1)
                                end
                            end
                        else %%%%if var_exist_single_scrap_data==0 %%%%%%%%Calculate move list, union, agg check, scrap agg
                            server_status_rev2(app,tf_server_status)
                            disp_progress(app,strcat('Neighborhood Calc 1: Line 216: Calculating  union_turn_off_list_data:',num2str(single_search_dist),'km'))

                            %%%%%%%%%%First check for the union move list
                            %%%%%%%%%First, check to see if the union of the move list exists
                            file_name_union_move=strcat(CBSD_label,'_union_turn_off_list_data_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
                            [file_union_move_exist]=persistent_var_exist_with_corruption(app,file_name_union_move);

                            if file_union_move_exist==2
                                disp_progress(app,strcat('Neighborhood Calc Rev1: Line 237: Loading Union:',num2str(single_search_dist),'km'))
                                retry_load=1;
                                while(retry_load==1)
                                    try
                                        load(file_name_union_move,'union_turn_off_list_data')
                                        retry_load=0;
                                    catch
                                        retry_load=1;
                                        pause(1)
                                    end
                                end
                            else %%%%if file_union_move_exist==0 %%%The File Does not exist, we will calculate it
                                disp_progress(app,strcat('Neighborhood Calc Rev1 Line 249: Calculating Union, First ParFor Movelist:',num2str(single_search_dist),'km'))


                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate first-->Parfor --> No data load
                                if parallel_flag==1
                                    [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                                    parfor point_idx=1:num_ppts  %%%%Change to parfor
                                        %%%%%%%pre_sort_movelist_rev9_neigh_cut_azimuths_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,tf_opt,min_azimuth,max_azimuth);
                                        pre_sort_movelist_rev20_cust_ant_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,tf_opt,min_azimuth,max_azimuth,custom_antenna_pattern);
                                    end
                                end

                                %%%%%%%%%%%Then for each point, scrap the data and save to excel. Only hold onto 1 point data at a time.
                                %%%%%%%%For this case (1 Monte Carlo Iteration), we really don't need to save most of the data, only the optimized move list order.
                                %%%%%%%%%Keep the move list flexible with the reliability inputs, so we can have multiple move lists.
                                %%%%%%%%%%In the next revision, do the full ITM reliability and do the aggregate check of the 50% ITM with the full 1-99%. (1000 MC and 95th Percentile)


                                disp_progress(app,strcat('Neighborhood Calc Rev1 Line 263: Loading Move List with For Loop:',num2str(single_search_dist),'km'))
                                server_status_rev2(app,tf_server_status)
                                cell_move_list_turn_off_data=cell(num_ppts,1);
                                for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
                                    point_idx
                                    %%%%%%%[move_sort_sim_array_list_bs]=pre_sort_movelist_rev9_neigh_cut_azimuths_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,tf_opt,min_azimuth,max_azimuth);
                                    [move_sort_sim_array_list_bs]=pre_sort_movelist_rev20_cust_ant_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,tf_opt,min_azimuth,max_azimuth,custom_antenna_pattern);
                                    if ~isnan(move_sort_sim_array_list_bs(1,1))
                                        cell_move_list_turn_off_data{point_idx}=move_sort_sim_array_list_bs;
                                    end
                                end
                                toc;

                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Create Union Move List
                                'cell_move_list_turn_off_data'
                                cell_move_list_turn_off_data
                                union_turn_off_list_data=unique(vertcat(cell_move_list_turn_off_data{:}),'rows');
                                size(union_turn_off_list_data)

                                'union_turn_off_list_data1'
                                union_turn_off_list_data
                                'is empty'
                                isempty(union_turn_off_list_data)
                                % if isempty(union_turn_off_list_data)
                                %     union_turn_off_list_data=NaN(1,15);
                                % end

                                %   union_turn_off_list_data
                                if ~isempty(union_turn_off_list_data)
                                    union_turn_off_list_data=union_turn_off_list_data(~isnan(union_turn_off_list_data(:,1)),:);
                                end
                                size(union_turn_off_list_data)
                                'union_turn_off_list_data2'
                                union_turn_off_list_data

                                % if isempty(union_turn_off_list_data)
                                %     union_turn_off_list_data=NaN(1,15);
                                % end


                                disp_progress(app,strcat('Neighborhood Calc Rev1 Line 277: Saving Union Move List :',num2str(single_search_dist),'km'))
                                retry_save=1;
                                while(retry_save==1)
                                    try
                                        save(file_name_union_move,'union_turn_off_list_data')
                                        retry_save=0;
                                    catch
                                        retry_save=1;
                                        pause(1)
                                    end
                                end
                            end
                            disp_progress(app,strcat('Neighborhood Calc Rev1 Line 289: Union Move List --> Creating the Keep On List :',num2str(single_search_dist),'km'))

                            size(union_turn_off_list_data)

                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%First create the keep_on list
                            on_list_bs=sim_array_list_bs;
                            if isempty(union_turn_off_list_data)
                                off_idx=[];
                            else
                                [C_on,off_idx,ib_on]=intersect(sim_array_list_bs,union_turn_off_list_data,'rows');
                                %off_idx(1:10)
                            end
                            off_idx=sort(off_idx);
                            on_list_bs(off_idx,:)=[];  %%%%%%%Cut off_idx from A

                            size(on_list_bs)
                            size(sim_array_list_bs)

                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Aggregate Check

                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate first-->Parfor --> No data load
                            disp_progress(app,strcat('Neighborhood Calc Rev1 Line 309: Parfor Aggregate Check :',num2str(single_search_dist),'km'))
                            server_status_rev2(app,tf_server_status)
                            if parallel_flag==1
                                [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                                parfor point_idx=1:num_ppts  %%%%Change to parfor
                                    %%%%agg_check_rev2_string_prop_model_azimuths_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth);
                                    agg_check_rev3_string_prop_model_azimuths_custant_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth,custom_antenna_pattern);
                                end
                            end

                            %%%%%%%%%%%Then for each point, scrap the data and save to excel. Only hold onto 1 point data at a time.
                            %%%%%%%%For this case (1 Monte Carlo Iteration), we really don't need to save most of the data, only the optimized move list order.
                            %%%%%%%%%Keep the move list flexible with the reliability inputs, so we can have multiple move lists.
                            %%%%%%%%%%In the next revision, do the full ITM reliability and do the aggregate check of the 50% ITM with the full 1-99%. (1000 MC and 95th Percentile)
                            cell_agg_check_data=cell(num_ppts,1);
                            %%%cell_move_list_idx=cell(num_ppts,1);  %%%%%%%%%%This is used as a way to check.
                            single_scrap_data=NaN(num_ppts,2); %%%%Aggregate, Move List Size
                            disp_progress(app,strcat('Neighborhood Calc Rev1 Line 325: Loading Aggregate Check in For Loop :',num2str(single_search_dist),'km'))
                            server_status_rev2(app,tf_server_status)
                            for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
                                point_idx

                                %%%%%%%[array_agg_check_95]=agg_check_rev2_string_prop_model_azimuths_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth);
                               [array_agg_check_95]=agg_check_rev3_string_prop_model_azimuths_custant_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth,custom_antenna_pattern);

                                cell_agg_check_data{point_idx}=array_agg_check_95;
                                single_scrap_data(point_idx,1)=max(array_agg_check_95); %%%%%%Aggregate
                                if isempty(off_idx)
                                    single_scrap_data(point_idx,2)=0; %%%%%Length of Move List
                                else
                                    single_scrap_data(point_idx,2)=length(off_idx); %%%%%Length of Move List
                                end
                            end
                            toc;

                          

                            %%%%%%%%%%%%%%%%Make the Red/Green/Blue Graph for illustrative reasons.
                            %%%%%%%First make the single_search_dist circle(purple)
                            single_search_dist
                            if single_search_dist>0
                                [search_dist_bound]=calc_sim_bound(app,base_polygon,single_search_dist,data_label1);

                                %%%%%%%Find the "on" inside of search_dist_boudn
                                [inside_idx]=find_points_inside_contour(app,search_dist_bound,on_list_bs(:,[1,2]));
                            end
                            % size(inside_idx)
                            % on_list_bs([1:10],[1,2])

                            single_scrap_data
                            temp_max_agg=max(single_scrap_data(:,1))
                            [sim_bound]=calc_sim_bound(app,base_polygon,sim_radius_km,data_label1);


                            f1=figure;
                            geoplot(base_protection_pts(:,1),base_protection_pts(:,2),'xk','LineWidth',3,'DisplayName','Federal System')
                            hold on;
                            geoplot(sim_bound(:,1),sim_bound(:,2),'--','Color','b','LineWidth',3,'DisplayName',strcat(num2str(single_search_dist),'km'))
                            if single_search_dist>0
                                geoplot(search_dist_bound(:,1),search_dist_bound(:,2),'-','Color',[255/256 51/256 255/256] ,'LineWidth',3,'DisplayName',strcat(num2str(single_search_dist),'km'))
                            end
                            geoscatter(on_list_bs(:,1),on_list_bs(:,2),1,'b','filled')
                            if single_search_dist>0
                                geoscatter(on_list_bs(inside_idx,1),on_list_bs(inside_idx,2),2,'g','filled')
                            end
                            if ~isempty(union_turn_off_list_data)
                                geoscatter(union_turn_off_list_data(:,1),union_turn_off_list_data(:,2),3,'r','filled')
                            end
                            grid on;
                            geoplot(base_protection_pts(:,1),base_protection_pts(:,2),'xk','LineWidth',3,'DisplayName','Federal System')
                            title(strcat(num2str(single_search_dist),'km--Maximum Aggregate:',num2str(temp_max_agg)))
                            pause(0.1)
                            geobasemap streets-light%landcover
                            f1.Position = [100 100 1200 900];
                            pause(1)
                            filename1=strcat('SearchDist_',data_label1,'_',num2str(single_search_dist),'km.png');
                            saveas(gcf,char(filename1))
                            pause(0.1);
                            close(f1)

                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            disp_progress(app,strcat('Neighborhood Calc Rev1 Line 336: Saving single_scrap_data :',num2str(single_search_dist),'km'))
                            retry_save=1;
                            while(retry_save==1)
                                try
                                    save(file_name_single_scrap_data,'single_scrap_data')
                                    retry_save=0;
                                catch
                                    retry_save=1;
                                    pause(1)
                                end
                            end
                        end

                        server_status_rev2(app,tf_server_status)
                        disp_progress(app,strcat('Neighborhood Calc Rev1 Line 350: Putting single_scrap_data into the array :',num2str(single_search_dist),'km'))
                        single_scrap_data

                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 'Put it into the data array'
                        %%%%%%%%Distribute single_scrap_data to all_data_stats_binary
                        [all_data_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,CBSD_label);

                        %%%%Distance, Aggregate, Move List Size
                        %%%%Distance, Aggregate, Move List Size
                        for point_idx=1:1:length(all_data_stats_binary)
                            temp_data=all_data_stats_binary{point_idx};
                            new_temp_data=vertcat(temp_data,horzcat(single_search_dist,single_scrap_data(point_idx,:)));
                            [uni_dist,uni_idx]=unique(new_temp_data(:,1));
                            uni_new_temp_data=new_temp_data(uni_idx,:);

                            %%%%Sort the Data
                            [check_sort,sort_idx]=sort(uni_new_temp_data(:,1)); %%%%%%Sorting by Distance just in case
                            all_data_stats_binary{point_idx}=uni_new_temp_data(sort_idx,:);
                        end
                        %%%%%Save the Cell
                        pre_label=CBSD_label;
                        file_name_cell=strcat(pre_label,'_',data_label1,'_',num2str(sim_number),'_all_data_stats_binary.mat');
                        retry_save=1;
                        while(retry_save==1)
                            try
                                save(file_name_cell,'all_data_stats_binary')
                                retry_save=0;
                            catch
                                retry_save=1;
                                pause(0.1)
                            end
                        end
                    end

                    server_status_rev2(app,tf_server_status)
                    disp_progress(app,strcat('Neighborhood Calc Rev1 Line 385: Trying to Find the Next Distance to calculate :',num2str(single_search_dist),'km'))

                    %%%%%%%%%%%%%%%%Reload and plots
                    [all_data_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,CBSD_label);

                    all_data_stats_binary
                    all_data_stats_binary{:}

                    %%%%%%%%Need to have a check after the max distance is checked. If
                    %%%%%%%%the aggregate is greater than the radar_threshold, there is
                    %%%%%%%%a problem and the sim needs to stop.

                    %%%%%%%Find the Next Search Dist and if to continue with the all_data_stats_binary
                    if binary_marker>1
                        disp_progress(app,strcat('Neighborhood Calc Rev1 Line 399: Before  calc_next_search_dist'))
                        [next_single_search_dist,tf_search,temp_bs_dist_data,array_searched_dist]=calc_next_search_dist(app,all_data_stats_binary,radar_threshold,margin,maine_exception,tf_full_binary_search,min_binaray_spacing);
                        disp_progress(app,strcat('Neighborhood Calc Rev1 Line 401: After calc_next_search_dist'))
                        next_single_search_dist
                        %%%disp_progress(app,strcat('Max-',CBSD_label,'-Distance:',num2str(max(temp_bs_dist_data))))
                    end
                    hWaitbarMsgQueue_binary.send(0);
                end

                disp_progress(app,strcat('Neighborhood Calc Rev1 Line 408: Outside of While Loop'))
                server_status_rev2(app,tf_server_status)


                %%%%%%%%%%%%%%%%Reload and plots
                [all_data_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,CBSD_label);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Graph the Data


                disp_progress(app,strcat('Neighborhood Calc Rev1 Line 415: Plotting the Data'))
                tf_catb=1;
                single_mod_plateau_alg_rev6_geoplot_name(app,data_label1,sim_number,radar_threshold,margin,maine_exception,CBSD_label,base_polygon,base_protection_pts,tf_catb)
                disp_progress(app,strcat('Neighborhood Calc Rev1 Line 418: Data Plotted --> Moving to Next Location'))
                delete(hWaitbarMsgQueue_binary);
                close(hWaitbar_binary);

                cell2mat(all_data_stats_binary)
                table_stats=array2table(cell2mat(all_data_stats_binary))
                retry_save=1;
                while(retry_save==1)
                    try
                        writetable(table_stats,strcat('Stats_Neighborhood_',data_label1,'_',string_prop_model,'_Rev',num2str(sim_number),'.xlsx'));
                        pause(0.1);
                        retry_save=0;
                    catch
                        retry_save=1;
                        pause(0.1)
                    end
                end


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Before we mark it complete, print the excel
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if tf_print_excel==1
                    num_rel=length(reliability)
                    if num_rel>1
                        'Need to update this with multiple reliabilities'
                        pause;
                    end
                 
                    %%%%%%%%%%%%Pull the neighborhood radius--> Union Move list --> Pathloss --> Excel
                    retry_load=1;
                    while(retry_load==1)
                        try
                            CBSD_label='BaseStation';
                            load(strcat(CBSD_label,'_',data_label1,'_catb_neighborhood_radius.mat'),'catb_neighborhood_radius')
                            temp_data=catb_neighborhood_radius;
                            clear catb_neighborhood_radius;
                            neighborhood_radius=temp_data;
                            clear temp_data;

                            retry_load=0;
                        catch
                            retry_load=1;
                            pause(0.1)
                        end
                    end

                    file_name_union_move=strcat(CBSD_label,'_union_turn_off_list_data_',num2str(mc_size),'_',num2str(neighborhood_radius),'km.mat');
                    [file_union_move_exist]=persistent_var_exist_with_corruption(app,file_name_union_move);
                    if file_union_move_exist==2
                        disp_progress(app,strcat('Neighborhood Calc Rev1: Line 237: Loading Union:',num2str(neighborhood_radius),'km'))
                        retry_load=1;
                        while(retry_load==1)
                            try
                                load(file_name_union_move,'union_turn_off_list_data')
                                retry_load=0;
                            catch
                                retry_load=1;
                                pause(1)
                            end
                        end
                    else
                        'Error: NO Union turn off list'
                        pause;
                    end
                    

                    %%%Export the pathloss data, 1 sheet for each point
                    [num_sim_pts,~]=size(base_protection_pts)
                    if num_sim_pts>1
                        'More than 1 sim pts'
                        pause;
                    end
                    [num_tx,~]=size(sim_array_list_bs);
                    for point_idx=1:1:num_sim_pts

                        %%%%%%Load all the pathloss data
                        %%%%%%%%%'Load all the point pathloss calculations'
                        %%%%%%Persistent Load
                        file_name_pathloss=strcat(string_prop_model,'_pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
                        retry_load=1;
                        while(retry_load==1)
                            try
                                load(file_name_pathloss,'pathloss')
                                retry_load=0;
                            catch
                                retry_load=1;
                                'Having trouble loading pathloss . . .'
                                pause(1)
                            end
                        end

                        %%%%%%%Calculate Distance
                        sim_pt=base_protection_pts(point_idx,:);
                        bs_distance_km=deg2km(distance(sim_pt(1),sim_pt(2),sim_array_list_bs(:,1),sim_array_list_bs(:,2)));

                        [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'Calculate the antenna gain at Rx'
                        %%%%%%%%%%%%%%%%Calculate the simualation azimuths
                        [array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth);
                        % % if num_sim_azi>1
                        % %     'Need to expand the spreadsheet for multiple rx antenna rotations'
                        % %     pause;
                        % % end


                        [mid_idx]=nearestpoint_app(app,50,move_list_reliability);
                        mid_pathloss_dB=pathloss(:,mid_idx);
                        temp_pr_dbm=sim_array_list_bs(:,4)-mid_pathloss_dB+bs_azi_gain;  %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System
                        %%%%%%Need to do it twice, once for the sim
                        %%%%%%distance and another for the neighbohrood
                        %%%%%%distance (neighborhood_radius)

                        %%%%%%%%First for the sim_radius_km
                        tf_calc_opt_sort=0%1%0%1%0  %%%%%%%Load if it's been calculated before
                        [opt_sort_bs_idx,array_max_agg]=near_opt_sort_idx_string_prop_model_custant_rev4_agg_output(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,sim_radius_km,sim_array_list_bs,base_protection_pts,temp_pr_dbm,string_prop_model,custom_antenna_pattern,min_azimuth,max_azimuth);


                        figure;
                        hold on;
                        plot(array_max_agg,'-ok')
                        grid on;
                        pause(0.1)

                        delta_agg=diff(array_max_agg);
                        if max(delta_agg)>0
                            'Not optimum'
                            pause;
                        end

                        % figure;
                        % hold on;
                        % plot(delta_agg,'-ok')
                        % grid on;
                        % pause(0.1)

                        'Need to update for multiple azimuths'
                        pause;
                        'pull tf_opt_idx and then just take the max of all azimuths for the excel'
                        pause;

                        'old code below'
                        pause;


                        for azimuth_idx=1:1:num_sim_azi
                            %%%Find CBSD azimuths outside of +/- of half_ant_hor_deg of temp_azimuth
                            sim_azimuth=array_sim_azimuth(azimuth_idx);
                            circshift_antpat=custom_antenna_pattern;
                            circshift_antpat(:,1)=custom_antenna_pattern(:,1)+sim_azimuth; %%%%%%%Add the azimuth, then we don't have to worry about azimuth spacing on pattern
                            %%%%Then Mod
                            mod_ant_pat=mod(circshift_antpat(:,1),360);
                            circshift_antpat(:,1)=mod_ant_pat;

                            %%%%%%Now find the 0
                            nn_zero_azi_idx=nearestpoint_app(app,0,circshift_antpat(:,1));
                            [num_ele,~]=size(circshift_antpat);
                            shift_antpat=circshift(circshift_antpat,num_ele-nn_zero_azi_idx+1);
                            shift_antpat=table2array(unique(array2table(shift_antpat),'rows')); %%%%%%Only keep unique azimuth rows

                            %%%%%%Test to make sure 0 is first in array
                            nn_check_idx=nearestpoint_app(app,0,shift_antpat(:,1));
                            if nn_check_idx~=1
                                'Circ shift error'
                                pause;
                            end

                            bs_azimuth=azimuth(sim_pt(1),sim_pt(2),sim_array_list_bs(:,1),sim_array_list_bs(:,2));
                            [ant_deg_idx]=nearestpoint_app(app,bs_azimuth,shift_antpat(:,1));
                            off_axis_gain=shift_antpat(ant_deg_idx,2);
                        end

                        %%%%%%%%%%%%%%%%%%%%%Calculate Power Received;
                        array_rx_pwr=sim_array_list_bs(:,4)-pathloss+off_axis_gain+bs_azi_gain;
                        % horzcat(array_rx_pwr(1:10),sim_array_list_bs(1:10,4),pathloss(1:10),off_axis_gain(1:10),bs_azi_gain(1:10))
                        % 'check'
                        % pause;

                        %%%%%%%%%%Make a table:
                        % %%%%%%%%1) Uni_Id
                        % %%%%%%%%2) BS_Latitude_DD
                        % %%%%%%%%3) BS_Longitude_DD
                        % %%%%%%%%4) BS_Height_m
                        % %%%%%%%%5) Fed_Latitude_DD
                        % %%%%%%%%6) Fed_Longitude_DD
                        % %%%%%%%%7) Fed_Height_m
                        % %%%%%%%%8) BS_EIRP_dBm
                        %%%%%%%%%%9) Path_Loss_dB
                        %%%%%%%%%10) Distance km
                        %%%%%%%%%11) Rx Ant Gain (dBi)
                        %%%%%%%%%12) Power Received dBm
                        %%%%%%%%%13) TF_off
                        %%%%%%%%%14) Aggregate
          
                        array_excel_data=horzcat(sim_array_list_bs(:,5),sim_array_list_bs(:,[1,2,3]),sim_pt.*ones(num_tx,1),sim_array_list_bs(:,[4]),pathloss,bs_distance_km,off_axis_gain,array_rx_pwr);
                        %array_excel_data(off_idx,end+1)=1;  %%%%%%%%%%%Inside the coordination Zone


                        %%%%%%%%%%Now find the turnoff
                        bs_turnoff_idx=union_turn_off_list_data(:,5);
                        nn_off_idx=nearestpoint_app(app,bs_turnoff_idx,sim_array_list_bs(:,5));

                        if all(bs_turnoff_idx==nn_off_idx)==0
                            horzcat(bs_turnoff_idx,nn_off_idx)
                            'matching error'
                            pause;
                        end
                        on_idx=setxor(nn_off_idx,sim_array_list_bs(:,5));

                        %%%%%%%Break into two: on/off, sort each group and piece back together.
                        off_array_excel_data=array_excel_data(nn_off_idx,:);
                        on_array_excel_data=array_excel_data(on_idx,:);

                        off_array_excel_data(:,13)=1;
                        on_array_excel_data(:,13)=0;

                        [~,sort_off_idx]=sort(off_array_excel_data(:,12),'descend');
                        [~,sort_on_idx]=sort(on_array_excel_data(:,12),'descend');
                        sort_array_excel_data=vertcat(off_array_excel_data(sort_off_idx,:),on_array_excel_data(sort_on_idx,:));

                        %%%%%%%If we made it here, there is only 1 azimuth,so just aggregate from the bottom up

                        %%%%%%Convert to Watts, Sum, and Find Aggregate
                        %%%pow2db(0.1*1000)=20, 0.1 Watts = 20dBm
                        %%%db2pow(20)/1000=0.1, 20dBm = 0.1 Watts
                        sort_rx_watts=db2pow(sort_array_excel_data(:,12))/1000; %%%%%%To be used for the binary search
                        [num_rows,~]=size(sort_array_excel_data)
                        array_agg_dBm=NaN(num_rows,1);
                        for n=num_rows:-1:1
                            array_agg_dBm(n)=pow2db(sum(sort_rx_watts(n:end),"omitnan")*1000);
                        end

                        % % % % figure;
                        % % % % hold on;
                        % % % % plot(array_agg_dBm)
                        % % % % grid on;

                        full_excel_data=horzcat(sort_array_excel_data,array_agg_dBm,dpa_threshold.*ones(num_tx,1));

                        %%%%%%%%%%%%%%%%%%Now cut all that are outside the neighborhood
                        keep_idx=find(full_excel_data(:,10)<=neighborhood_radius);
                        keep_full_excel_data=full_excel_data(keep_idx,:);

                        %%%%%%%Recalculate the aggregate
                        keep_rx_watts=db2pow(keep_full_excel_data(:,12))/1000; %%%%%%To be used for the binary search
                        [num_rows,~]=size(keep_full_excel_data)
                        keep_array_agg_dBm=NaN(num_rows,1);
                        for n=num_rows:-1:1
                            keep_array_agg_dBm(n)=pow2db(sum(keep_rx_watts(n:end),"omitnan")*1000);
                        end
                        keep_full_excel_data(:,14)=keep_array_agg_dBm;

                        % % % figure;
                        % % % hold on;
                        % % % plot(keep_array_agg_dBm)
                        % % % grid on;

                        table_excel_data=array2table(full_excel_data);
                        table_excel_data.Properties.VariableNames={'Uni_Id' 'BS_Latitude_DD' 'BS_Longitude_DD' 'BS_Height_m' 'Fed_Latitude_DD' 'Fed_Longitude_DD' 'Fed_Height_m' 'BS_EIRP_dBm' 'Path_Loss_dB' 'Distance_km' 'Rx_Ant_Gain' 'Rx_Pwr_dBm' 'TF_off' 'Aggregate_dBm' 'Interference_Threshold'}
                        disp_progress(app,strcat('Writing Excel File . . . '))
                        tic;
                        retry_save=1;
                        while(retry_save==1)
                            try
                                writetable(table_excel_data,strcat('FULL_',data_label1,'_Point',num2str(point_idx),'_',string_prop_model,'_Rev',num2str(sim_number),'.xlsx'));
                                pause(0.1);
                                retry_save=0;
                            catch
                                retry_save=1;
                                pause(0.1)
                            end
                        end
                        toc;  %%%%%%A few seconds

                        table_excel_keep_data=array2table(keep_full_excel_data);
                        table_excel_keep_data.Properties.VariableNames={'Uni_Id' 'BS_Latitude_DD' 'BS_Longitude_DD' 'BS_Height_m' 'Fed_Latitude_DD' 'Fed_Longitude_DD' 'Fed_Height_m' 'BS_EIRP_dBm' 'Path_Loss_dB' 'Distance_km' 'Rx_Ant_Gain' 'Rx_Pwr_dBm' 'TF_off' 'Aggregate_dBm' 'Interference_Threshold'}
                        disp_progress(app,strcat('Writing Excel File . . . '))
                        tic;
                        retry_save=1;
                        while(retry_save==1)
                            try
                                writetable(table_excel_keep_data,strcat('Neighborhood_',data_label1,'_Point',num2str(point_idx),'_',string_prop_model,'_Rev',num2str(sim_number),'.xlsx'));
                                pause(0.1);
                                retry_save=0;
                            catch
                                retry_save=1;
                                pause(0.1)
                            end
                        end
                        toc;  %%%%%%A few seconds
                    end
                end

                % % 'before the comp_list'
                % % pause;


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


                tf_update_cell_status=1;
                tic;
                [~]=checkout_cell_status_rev1(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status);
                toc;
                disp_TextArea_PastText(app,strcat('neighborhood_calc_rev4_azimuths_geoplots_custant: After Checkout: Line 457'))
                server_status_rev2(app,tf_server_status)
            end
        end
        multi_hWaitbarMsgQueue.send(0);
    end
    delete(multi_hWaitbarMsgQueue);
    close(multi_hWaitbar);
end
server_status_rev2(app,tf_server_status)

