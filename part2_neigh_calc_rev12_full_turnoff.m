function part2_neigh_calc_rev12_full_turnoff(app,parallel_flag,rev_folder,workers,move_list_reliability,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,sim_radius_km,min_binaray_spacing,margin,maine_exception,tf_full_binary_search,agg_check_reliability,tf_opt,tf_recalculate,tf_server_status,tf_print_excel,bs_eirp_dist,cell_aas_dist_data,move_list_margin,cell_sim_data,tf_full_turnoff)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check for the Number of Folders to Sim
[sim_number,folder_names,~]=check_rev_folders(app,rev_folder);

%%%%%%%%%%%%%'If you get an error here, move the Tirem dlls to here'
[tf_tirem_error]=check_tirem_rev1(app,string_prop_model);

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
    [multi_hWaitbar,multi_hWaitbarMsgQueue]=ParForWaitbarCreateMH_time('Multi-Folder Binary Search: ',num_folders);    %%%%%%% Create ParFor Waitbar

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
            retry_cd_folder_rev1(app,rev_folder)
            sim_folder=temp_folder_names{array_rand_folder_idx(folder_idx)};
            retry_cd_folder_rev1(app,sim_folder)
            disp_multifolder(app,sim_folder)
            data_label1=sim_folder;

            %%%%%%Check for the tf_complete_ITM file
            complete_filename=strcat(data_label1,'_',label_single_filename,'.mat'); %%%This is a marker for me
            %%%%%%%%%%%%%%%%[var_exist]=persistent_var_exist_with_corruption(app,complete_filename);
            [var_exist]=persistent_matfile_exists_with_corruption_GPT_rev2(app,complete_filename);
            if tf_recalculate==1
                var_exist=0
            end

            if var_exist==2
                retry_cd_folder_rev1(app,rev_folder)
                % retry_cd=1;
                % while(retry_cd==1)
                %     try
                %         cd(rev_folder)
                %         pause(0.1);
                %         retry_cd=0;
                %     catch
                %         retry_cd=1;
                %         pause(0.1)
                %     end
                % end

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

                base_polygon=load_variable_with_retry_GPT_rev2(app, data_label1+"_base_polygon.mat", "base_polygon");
                base_protection_pts=load_variable_with_retry_GPT_rev2(app, data_label1+"_base_protection_pts.mat", "base_protection_pts");
                sim_array_list_bs=load_variable_with_retry_GPT_rev2(app, data_label1+"_sim_array_list_bs.mat", "sim_array_list_bs");
                ant_beamwidth=load_variable_with_retry_GPT_rev2(app, data_label1+"_ant_beamwidth.mat", "ant_beamwidth");
                radar_beamwidth=ant_beamwidth;
                min_ant_loss=load_variable_with_retry_GPT_rev2(app, data_label1+"_min_ant_loss.mat", "min_ant_loss");
                min_azimuth=load_variable_with_retry_GPT_rev2(app, data_label1+"_min_azimuth.mat", "min_azimuth");
                max_azimuth=load_variable_with_retry_GPT_rev2(app, data_label1+"_max_azimuth.mat", "max_azimuth");
                dpa_threshold=load_variable_with_retry_GPT_rev2(app, data_label1+"_dpa_threshold.mat", "dpa_threshold");
                radar_threshold=dpa_threshold;
                custom_antenna_pattern=load_variable_with_retry_GPT_rev2(app, data_label1+"_custom_antenna_pattern.mat", "custom_antenna_pattern");  % e.g. stop if it truly doesn't exist

                %%%%%%%%%%Binary Search
                [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                [num_ppts,~]=size(base_protection_pts);
                if num_ppts==1
                    max_number_calc=ceil(log2(sim_radius_km))+3  %%%%%%%This assumes a 1km min_binaray_spacing and the 0 and max distance
                else
                    %max_number_calc=sim_radius_km/min_binaray_spacing
                    max_number_calc=(ceil(log2(sim_radius_km))+3)*num_ppts  %%%%%%%This assumes a 1km min_binaray_spacing and the 0 and max distance and that each distance search for a point is not applicable to the other points
                end
                disp_progress(app,strcat('Neighborhood Calc 1: Line 172: ', num2str(max_number_calc)))

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                [hWaitbar_binary,hWaitbarMsgQueue_binary]= ParForWaitbarCreateMH_time('Binary Search: ',max_number_calc);    %%%%%%% Create ParFor Waitbar, this one covers points and chunks

                binary_dist_array=[1,2,4,8,16,32,64,128,256,512,1024,2048];
                CBSD_label='BaseStation';
                [nn_idx]=nearestpoint_app(app,sim_radius_km,binary_dist_array,'next');
                bs_neighborhood=binary_dist_array(nn_idx);
                search_dist_array=horzcat(0:min_binaray_spacing:bs_neighborhood);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Start of Binary Search
                %%%%%%%Check for all_data_stats_binary, if none, initialize it.
                [all_data_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,CBSD_label);

                %%%%%%%%%%Find the secondary DPA Threshold and Percentiles,
                %%%%%%%%%%if so then another all_data_stats_binary
                data_header=cell_sim_data(1,:)';
                label_idx=find(matches(data_header,'data_label1'));
                row_folder_idx=find(matches(cell_sim_data(:,label_idx),sim_folder));

                %%%%%Need the secondary, if they are there
                dpa2thres_idx=find(matches(data_header,'dpa_second_threshold'));
                per2_idx=find(matches(data_header,'second_mc_percentile'));

                if ~isempty(dpa2thres_idx)
                    radar2threshold=cell_sim_data{row_folder_idx,dpa2thres_idx};
                else
                    radar2threshold=NaN(1,1);
                end
                if ~isempty(per2_idx)
                    mc_per2=cell_sim_data{row_folder_idx,per2_idx};
                else
                    mc_per2=NaN(1,1);
                end
                radar2threshold
                mc_per2

                if ~isnan(radar2threshold)
                    tf_second_data=1;
                else
                    tf_second_data=0;
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Secondary Data
                if tf_second_data==1
                    [all_secondary_stats_binary]=initialize_or_load_secondary_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,'secondary');
                end
                all_data_stats_binary
                all_secondary_stats_binary
                disp_progress(app,strcat('Neighborhood Calc 1: Line 178: loaded all_data_stats_binary'))

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Starting the Binary Search
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

                        if tf_second_data==1
                            file_name_second_scrap_data=strcat(CBSD_label,'_',data_label1,'_',num2str(sim_number),'_second_scrap_data_',num2str(single_search_dist),'.mat'); %%%%%%First Check for an array file, named with the single_search_dist and has all the aggregate checks for each protection point.
                            [var_exist_file_name_second_scrap_data]=persistent_var_exist_with_corruption(app,file_name_second_scrap_data);
                        end

                        if var_exist_single_scrap_data==2
                            disp_progress(app,strcat('Neighborhood Calc 1: Line 216: Loading single_scrap_data:',num2str(single_search_dist),'km'))
                            retry_load=1;
                            while(retry_load==1)
                                try
                                    load(file_name_single_scrap_data,'single_scrap_data')
                                    if tf_second_data==1
                                        load(file_name_second_scrap_data,'second_scrap_data')
                                    end
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
                                        %%%%%%%%pre_sort_movelist_rev20d_clutter_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,tf_opt,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,move_list_margin);
                                        pre_sort_movelist_rev20e_tf_full_turnoff_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,tf_opt,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,move_list_margin,tf_full_turnoff);
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
                                    %%%%%%%%[move_sort_sim_array_list_bs]=pre_sort_movelist_rev20d_clutter_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,tf_opt,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,move_list_margin);
                                    [move_sort_sim_array_list_bs]=pre_sort_movelist_rev20e_tf_full_turnoff_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,tf_opt,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,move_list_margin,tf_full_turnoff);
                                    if ~isnan(move_sort_sim_array_list_bs(1,1))
                                        cell_move_list_turn_off_data{point_idx}=move_sort_sim_array_list_bs;
                                    end
                                end
                                toc;

                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Create Union Move List
                                union_turn_off_list_data=unique(vertcat(cell_move_list_turn_off_data{:}),'rows');
                                isempty(union_turn_off_list_data)
                                % if isempty(union_turn_off_list_data)
                                %     union_turn_off_list_data=NaN(1,15);
                                % end

                                if ~isempty(union_turn_off_list_data)
                                    union_turn_off_list_data=union_turn_off_list_data(~isnan(union_turn_off_list_data(:,1)),:);
                                end
                                size(union_turn_off_list_data)

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

                            %union_turn_off_list_data
                            %size(union_turn_off_list_data)

                            % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%First create the keep_on list
                            % % % on_list_bs=sim_array_list_bs;
                            % % % if isempty(union_turn_off_list_data)
                            % % %     off_idx=[];
                            % % % else
                            % % %     [C_on,off_idx,ib_on]=intersect(sim_array_list_bs,union_turn_off_list_data,'rows');
                            % % %     %off_idx(1:10)
                            % % % end
                            % % % off_idx=sort(off_idx);
                            % % % on_list_bs(off_idx,:)=[];  %%%%%%%Cut off_idx from A
                            % % %
                            % % % size(on_list_bs)
                            % % % size(sim_array_list_bs)
                            [on_list_bs,off_idx] = create_on_list_bs_GPT_rev1(app,sim_array_list_bs,union_turn_off_list_data);



                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Aggregate Check
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate first-->Parfor --> No data load
                            disp_progress(app,strcat('Neighborhood Calc Rev1 Line 309: Parfor Aggregate Check :',num2str(single_search_dist),'km'))
                            server_status_rev2(app,tf_server_status)
                            if parallel_flag==1
                                [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                                parfor point_idx=1:num_ppts  %%%%Change to parfor
                                    agg_check_rev6_clutter_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth,custom_antenna_pattern,bs_eirp_dist,cell_aas_dist_data,cell_sim_data,sim_folder);
                                end
                            end

                            %%%%%%%%%%%Then for each point, scrap the data and save to excel. Only hold onto 1 point data at a time.
                            %%%%%%%%For this case (1 Monte Carlo Iteration), we really don't need to save most of the data, only the optimized move list order.
                            %%%%%%%%%Keep the move list flexible with the reliability inputs, so we can have multiple move lists.
                            %%%%%%%%%%In the next revision, do the full ITM reliability and do the aggregate check of the 50% ITM with the full 1-99%. (1000 MC and 95th Percentile)
                            cell_agg_check_data=cell(num_ppts,1);
                            single_scrap_data=NaN(num_ppts,2); %%%%Aggregate, Move List Size
                            disp_progress(app,strcat('Neighborhood Calc Rev1 Line 325: Loading Aggregate Check in For Loop :',num2str(single_search_dist),'km'))
                            server_status_rev2(app,tf_server_status)
                            second_scrap_data=NaN(num_ppts,2); %%%%Aggregate, Move List Size
                            for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
                                point_idx
                                [array_agg_check_95,array_agg_check_mc_dBm]=agg_check_rev6_clutter_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth,custom_antenna_pattern,bs_eirp_dist,cell_aas_dist_data,cell_sim_data,sim_folder);
                                cell_agg_check_data{point_idx}=array_agg_check_95;
                                single_scrap_data(point_idx,1)=max(array_agg_check_95); %%%%%%Aggregate
                                if isempty(off_idx)
                                    single_scrap_data(point_idx,2)=0; %%%%%Length of Move List
                                else
                                    single_scrap_data(point_idx,2)=length(off_idx); %%%%%Length of Move List
                                end

                                if isnan(single_scrap_data(point_idx,1))
                                    %'NaN aggregate'
                                    %'if its because of the max dist and tf_fullturnoff set to threshold -0.1dB'
                                    if bs_neighborhood==single_search_dist && tf_full_turnoff==1
                                        single_scrap_data(point_idx,1)=radar_threshold-0.1;
                                        % % % 'Open question, how does a NaN aggregate effect the next_single_search_dist and tf_search?'
                                        % % % 'Might need to update the calc_next_search_dist algorithm for a NaN at the end (or anywhere) '
                                        %%%%%%%%%%It does not like it
                                    else
                                        disp_progress(app,strcat('Pause Error Part 2, Still an aggegrate NaN Error'))
                                        pause;
                                    end
                                end
                                %%%%%%%%%%%The open question is how does a
                                %%%%%%%%%%%NaN in the data effect the
                                %%%%%%%%%%%binary search

                                if tf_second_data==1
                                    array_agg_check_second=prctile(sort(array_agg_check_mc_dBm),mc_per2);
                                    second_scrap_data(point_idx,1)=array_agg_check_second;
                                    if isempty(off_idx)
                                        second_scrap_data(point_idx,2)=0; %%%%%Length of Move List
                                    else
                                        second_scrap_data(point_idx,2)=length(off_idx); %%%%%Length of Move List
                                    end
                                    second_scrap_data
                                else
                                    'Need to check what happens'
                                    pause;
                                end

                                if tf_second_data==1
                                    if isnan(second_scrap_data(point_idx,1))
                                        %'NaN aggregate'
                                        %'if its because of the max dist and tf_fullturnoff set to threshold -0.1dB'
                                        if bs_neighborhood==single_search_dist && tf_full_turnoff==1
                                            second_scrap_data(point_idx,1)=radar2threshold-0.1;
                                            % % % 'Open question, how does a NaN aggregate effect the next_single_search_dist and tf_search?'
                                            % % % 'Might need to update the calc_next_search_dist algorithm for a NaN at the end (or anywhere) '
                                            %%%%%%%%%%It does not like it
                                        else
                                            disp_progress(app,strcat('Pause Error Part 2, Still an aggegrate NaN Error'))
                                            pause;
                                        end
                                    end
                                end
                            end
                            toc;

                            if single_search_dist>0
                                [search_dist_bound]=calc_sim_bound(app,base_polygon,single_search_dist,data_label1);
                                [inside_idx]=find_points_inside_contour(app,search_dist_bound,on_list_bs(:,[1,2]));
                            else
                                search_dist_bound=NaN(1,2);
                                inside_idx=NaN(1,1);
                                inside_idx=inside_idx(~isnan(inside_idx));
                            end

                            single_scrap_data
                            temp_max_agg=max(single_scrap_data(:,1))
                            [sim_bound]=calc_sim_bound(app,base_polygon,sim_radius_km,data_label1);
                            geo_plot_neighborhood_step_rev1(app,base_protection_pts,sim_bound,single_search_dist,on_list_bs,search_dist_bound,inside_idx,union_turn_off_list_data,temp_max_agg,data_label1)

                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            disp_progress(app,strcat('Neighborhood Calc Rev1 Line 336: Saving single_scrap_data :',num2str(single_search_dist),'km'))
                            retry_save=1;
                            while(retry_save==1)
                                try
                                    save(file_name_single_scrap_data,'single_scrap_data')
                                    if tf_second_data==1
                                        save(file_name_second_scrap_data,'second_scrap_data')
                                    end
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
                        second_scrap_data

                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 'Put it into the data array'
                        %%%%%%%%Distribute single_scrap_data to all_data_stats_binary
                        [all_data_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,CBSD_label);
                        [all_data_stats_binary]=update_all_data_distance_rev1(app,all_data_stats_binary,single_search_dist,single_scrap_data);

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

                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Secondary Data
                        if tf_second_data==1
                            %%%%%%[all_secondary_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,'secondary');
                            [all_secondary_stats_binary]=initialize_or_load_secondary_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,'secondary');
                            [all_secondary_stats_binary]=update_all_data_distance_rev1(app,all_secondary_stats_binary,single_search_dist,second_scrap_data);
                        end

                        all_secondary_stats_binary
                        all_secondary_stats_binary{:}

                        %%%%%Save the Cell
                        if tf_second_data==1
                            pre_label2='secondary'
                            file_name_cell2=strcat(pre_label2,'_',data_label1,'_',num2str(sim_number),'_all_secondary_stats_binary.mat');
                            retry_save=1;
                            while(retry_save==1)
                                try
                                    save(file_name_cell2,'all_secondary_stats_binary')
                                    retry_save=0;
                                catch
                                    retry_save=1;
                                    pause(0.1)
                                end
                            end
                        end
                    end

                    server_status_rev2(app,tf_server_status)
                    disp_progress(app,strcat('Neighborhood Calc Rev1 Line 385: Trying to Find the Next Distance to calculate :',num2str(single_search_dist),'km'))

                    %%%%%%%%%%%%%%%%Reload and plots
                    [all_data_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,CBSD_label);

                    if tf_second_data==1
                        %%%%%%[all_secondary_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,'secondary');
                        [all_secondary_stats_binary]=initialize_or_load_secondary_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,'secondary');
                    end

                    % all_data_stats_binary
                    % all_data_stats_binary{:}
                    % all_secondary_stats_binary
                    % all_secondary_stats_binary{:}

                    % 'check after each search'
                    % pause;

                    %%%%%%%%Need to have a check after the max distance is checked. If
                    %%%%%%%%the aggregate is greater than the radar_threshold, there is
                    %%%%%%%%a problem and the sim needs to stop.

                    %%%%%%%Find the Next Search Dist and if to continue with the all_data_stats_binary
                    if binary_marker>1
                        disp_progress(app,strcat('Neighborhood Calc Rev1 Line 399: Before  calc_next_search_dist'))
                        'Need to update calc_next_search_dist and remove the maine_exception'
                        [next_single_search_dist,tf_search,temp_bs_dist_data,array_searched_dist]=calc_next_search_dist(app,all_data_stats_binary,radar_threshold,margin,maine_exception,tf_full_binary_search,min_binaray_spacing)
                        disp_progress(app,strcat('Neighborhood Calc Rev1 Line 401: After calc_next_search_dist'))
                        next_single_search_dist

                        if tf_second_data==1
                            if tf_search==0
                                %next_single_search_dist
                                %%%'end of first search for the first i/n'
                                [next_single_search_dist,tf_search,temp_bs_dist_data,array_searched_dist]=calc_next_search_dist(app,all_secondary_stats_binary,radar2threshold,margin,maine_exception,tf_full_binary_search,min_binaray_spacing)
                            end
                        end
                    end                 
                    hWaitbarMsgQueue_binary.send(0);
                end
                tf_search

                disp_progress(app,strcat('Neighborhood Calc Rev1 Line 408: Outside of While Loop'))
                server_status_rev2(app,tf_server_status)

                %%%%%%%%%%%%%%%%Reload and plots
                [all_data_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,CBSD_label);
                %%%%%[all_data_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label_GPTrev2(app,data_label1,sim_number,base_protection_pts,CBSD_label);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Graph the Data

                if tf_second_data==1
                    %%%%%%[all_secondary_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,'secondary');
                    [all_secondary_stats_binary]=initialize_or_load_secondary_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,'secondary');
                end

                all_data_stats_binary{:}
                all_secondary_stats_binary{:}

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%Breaking single_mod_plateau_alg_rev6_geoplot_name into pieces
                catb_dist_data=calculate_neighborhood_dist_rev1(app,all_data_stats_binary,radar_threshold,margin);
                if tf_second_data==1
                    catb_dist_data2=calculate_neighborhood_dist_rev1(app,all_secondary_stats_binary,radar2threshold,margin);
                    % % % catb_dist_data2=ones(3,1)
                    % % % catb_dist_data=zeros(3,1)
                    horzcat(catb_dist_data,catb_dist_data2)
                    catb_dist_data=max(horzcat(catb_dist_data,catb_dist_data2),[],2);
                end

                %%%%%This is the dual neighbohrood distance.
                buffer_radius=max(catb_dist_data) %%%%Now we have an equivalent catb_dist_data
                if isnan(buffer_radius)==1 || buffer_radius==0
                    buffer_radius=1;
                end

                %%%%%%%%%%%%%Draw the Neighborhood around the base_polygon
                nnan_base_polygon=base_polygon(~isnan(base_polygon(:,1)),:);%%%%%%Remove NaN
                [neighborhood_bound]=calc_sim_bound(app,nnan_base_polygon,buffer_radius,data_label1);

                %%%%%%%%Save the CatB Neighborhood Polygon and other things
                retry_save=1;
                while(retry_save==1)
                    try
                        save(strcat(CBSD_label,'_',data_label1,'_neighborhood_bound.mat'),'neighborhood_bound')
                        pause(0.1);
                        retry_save=0;
                    catch
                        retry_save=1;
                        pause(0.1)
                    end
                end
                catb_neighborhood_radius=buffer_radius;
                retry_save=1;
                while(retry_save==1)
                    try
                        save(strcat(CBSD_label,'_',data_label1,'_catb_neighborhood_radius.mat'),'catb_neighborhood_radius')
                        pause(0.1);
                        retry_save=0;
                    catch
                        retry_save=1;
                        pause(0.1)
                    end
                end
                retry_save=1;
                while(retry_save==1)
                    try
                        save(strcat(CBSD_label,'_mod_',data_label1,'_',num2str(sim_number),'_catb_dist_data.mat'),'catb_dist_data')
                        pause(0.1);
                        retry_save=0;
                    catch
                        retry_save=1;
                        pause(0.1)
                    end
                end


                %%%%%'Need to update single_mod_plateau_alg_rev6_geoplot_name to remove maine_exception'
                %%%%%%'In the above code, broke the single_mod into pieces to accomodate for the double i/n threhsolds.'
                %single_mod_plateau_alg_rev6_geoplot_name(app,data_label1,sim_number,radar_threshold,margin,maine_exception,CBSD_label,base_polygon,base_protection_pts,tf_catb)


                %%%%%%%%%%%%%%%%%Plot single_mod_plateau_alg_rev6_geoplot_name
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%This one doesn't really seem to be good.
                %plot_neigh_point_dist_rev1(app,base_polygon,catb_dist_data,base_protection_pts,data_label1,CBSD_label,sim_number)
                plot_neigh_hist_rev1(app,catb_dist_data,data_label1,CBSD_label,sim_number)
                plot_neigh_map_rev1(app,nnan_base_polygon,base_polygon,neighborhood_bound,data_label1,CBSD_label,buffer_radius,sim_number)
                plot_neigh_binary_search_rev1(app,catb_dist_data,all_data_stats_binary,radar_threshold,margin,data_label1,CBSD_label,sim_number)
                if tf_second_data==1
                    plot_neigh_binary_search_rev1(app,catb_dist_data,all_secondary_stats_binary,radar2threshold,margin,data_label1,'secondary',sim_number)
                end

                disp_progress(app,strcat('Neighborhood Calc Rev1 Line 415: Plotting the Data'))
                tf_catb=1;

                disp_progress(app,strcat('Neighborhood Calc Rev1 Line 418: Data Plotted --> Moving to Next Location')) %%%Error after this location
                try
                    delete(hWaitbarMsgQueue_binary);
                catch
                end
                disp_progress(app,strcat('Neighborhood Calc Rev1 Line 562: Post delete(hWaitbarMsgQueue_binary);'))
                try
                    close(hWaitbar_binary);
                catch
                end
                disp_progress(app,strcat('Neighborhood Calc Rev1 Line 564: Post close(hWaitbar_binary);'))
                % % % 'Dont go past this point, check for the floating aggregate error'
                % % % pause;


                %cell2mat(all_data_stats_binary)

                %%%%%%%Distance will also be the same, and move list size
                %%%%%%%will always be the same, just the aggregate

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                temp_array=horzcat(all_data_stats_binary{:})
                [num_row,num_col]=size(temp_array)
                agg_col_idx=2:3:num_col
                table_stats=array2table(temp_array(:,[1,3,agg_col_idx]))
                retry_save=1;
                while(retry_save==1)
                    try
                        writetable(table_stats,strcat('Stats_Neighborhood_Primary_',data_label1,'_',string_prop_model,'_Rev',num2str(sim_number),'.xlsx'));
                        pause(0.1);
                        retry_save=0;
                    catch
                        retry_save=1;
                        pause(0.1)
                        disp_progress(app,strcat('Neighborhood Calc Rev1 Line 589: Cant Save Stats Table'))
                    end
                end
                disp_progress(app,strcat('Neighborhood Calc Rev1 Line 569: Stats Neighborhood Excel Saved'))

                %%%%%%%%%%%%%%%%
                if tf_second_data==1
                    temp_array=horzcat(all_secondary_stats_binary{:})
                    [num_row,num_col]=size(temp_array)
                    agg_col_idx=2:3:num_col
                    table_stats=array2table(temp_array(:,[1,3,agg_col_idx]))
                    retry_save=1;
                    while(retry_save==1)
                        try
                            writetable(table_stats,strcat('Stats_Neighborhood_Secondardy_',data_label1,'_',string_prop_model,'_Rev',num2str(sim_number),'.xlsx'));
                            pause(0.1);
                            retry_save=0;
                        catch
                            retry_save=1;
                            pause(0.1)
                            disp_progress(app,strcat('Neighborhood Calc Rev1 Line 589: Cant Save Stats Table'))
                        end
                    end
                    disp_progress(app,strcat('Neighborhood Calc Rev1 Line 569: Stats Neighborhood Excel Saved'))
                end


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Before we mark it complete, print the excel (Need to add clutter)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                excel_print_empty_union_bsidx_rev3(app,tf_print_excel,reliability,data_label1,mc_size,base_protection_pts,sim_array_list_bs,string_prop_model,sim_number,norm_aas_zero_elevation_data,radar_beamwidth,min_azimuth,max_azimuth,move_list_reliability,sim_radius_km,custom_antenna_pattern,dpa_threshold)

                disp_progress(app,strcat('Neighborhood Calc Rev1 Line 578: Aggregate Excel Saved'))

                [zone_dist_km]=calc_zone_distance_rev1(app, all_data_stats_binary, radar_threshold, margin)


                if num_ppts>1
                    'Need to put all distributions on a CDF plot.'
                    'Line 1240'
                    'This is where we put the graph at the end for the final aggregate check'
                    pause;
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


                tf_update_cell_status=1;
                tic;
                [~]=checkout_cell_status_rev1(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status);
                %%%%[~]=checkout_cell_status_GPT_rev2(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status);
                toc;
                disp_TextArea_PastText(app,strcat('neighborhood_calc_rev4_azimuths_geoplots_custant: After Checkout: Line 457'))
                server_status_rev2(app,tf_server_status)
            end
        end
        try
            multi_hWaitbarMsgQueue.send(0);
        catch
        end
    end
    try
        delete(multi_hWaitbarMsgQueue);
        close(multi_hWaitbar);
    catch
    end
end
server_status_rev2(app,tf_server_status)