function part2_neigh_calc_rev14_multi_server(app,parallel_flag,rev_folder,workers,move_list_reliability,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,sim_radius_km,min_binaray_spacing,margin,maine_exception,tf_full_binary_search,agg_check_reliability,tf_opt,tf_recalculate,tf_server_status,tf_print_excel,bs_eirp_dist,cell_aas_dist_data,move_list_margin,cell_sim_data,tf_full_turnoff)
%
% part2_neigh_calc_rev14_multi_server
%
% Rev14 vs Rev13: replaces parfor-based intra-server parallelism with a
% file-based claim-then-compute pattern so that N uncoordinated servers
% sharing the same rev_folder can each contribute work.
%
% Multi-server distribution framework per binary-search distance step:
%   Phase 1 — Pre-sort  : each server claims unclaimed point_idx slots and
%              calls pre_sort_movelist_rev20f (saves per-point .mat files).
%   Phase 2 — Wait      : poll until every point's pre-sort file exists.
%   Phase 3 — Union     : one server (via collection lock) assembles the
%              union move list and saves file_name_union_move.
%              Others poll for that file.
%   Phase 4 — Agg-check : same claim pattern for agg_check_rev6_clutter_app
%              (saves per-point .mat files).
%   Phase 5 — Wait      : poll until every point's agg-check file exists.
%   Phase 6 — Scrap     : one server (via collection lock) assembles
%              single_scrap_data and saves file_name_single_scrap_data.
%              Others poll for that file.
%
% All checkout_cell_status calls use checkout_cell_status_GPT_rev2 (atomic
% directory-lock; safe for concurrent multi-server access).
%
% Local helpers (end of file): try_claim_work_unit, release_work_unit,
% poll_until_file_exists_rev1.

%%%%%Input validation
if isempty(rev_folder) || ~(ischar(rev_folder) || isstring(rev_folder))
    disp_progress(app,'ERROR PAUSE: part2_neigh_calc_rev14_multi_server: rev_folder is empty or not a string')
    pause;
end
if isempty(reliability) || ~isnumeric(reliability)
    disp_progress(app,'ERROR PAUSE: part2_neigh_calc_rev14_multi_server: reliability is empty or non-numeric')
    pause;
end
if isempty(move_list_reliability) || ~isnumeric(move_list_reliability)
    disp_progress(app,'ERROR PAUSE: part2_neigh_calc_rev14_multi_server: move_list_reliability is empty or non-numeric')
    pause;
end
if isempty(agg_check_reliability) || ~isnumeric(agg_check_reliability)
    disp_progress(app,'ERROR PAUSE: part2_neigh_calc_rev14_multi_server: agg_check_reliability is empty or non-numeric')
    pause;
end
if isempty(cell_aas_dist_data) || ~iscell(cell_aas_dist_data)
    disp_progress(app,'ERROR PAUSE: part2_neigh_calc_rev14_multi_server: cell_aas_dist_data is empty or not a cell')
    pause;
end
if isempty(cell_sim_data) || ~iscell(cell_sim_data)
    disp_progress(app,'ERROR PAUSE: part2_neigh_calc_rev14_multi_server: cell_sim_data is empty or not a cell')
    pause;
end
if ~isnumeric(mc_size) || ~isscalar(mc_size) || mc_size<1
    disp_progress(app,'ERROR PAUSE: part2_neigh_calc_rev14_multi_server: mc_size is invalid')
    pause;
end
if ~isnumeric(sim_radius_km) || ~isscalar(sim_radius_km) || sim_radius_km<=0
    disp_progress(app,'ERROR PAUSE: part2_neigh_calc_rev14_multi_server: sim_radius_km is invalid')
    pause;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check for the Number of Folders to Sim
[sim_number,folder_names,~]=check_rev_folders(app,rev_folder);

%%%%%%%%%%%%%'If you get an error here, move the Tirem dlls to here'
[tf_tirem_error]=check_tirem_rev1(app,string_prop_model);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function:
cell_status_filename=strcat('cell_',string_prop_model,'_',num2str(sim_number),'_Neighborhood_status.mat')
label_single_filename=strcat(string_prop_model,'_',num2str(sim_number),'_Neighborhood_status')
checkout_filename=strcat('TF_checkout_',string_prop_model,'_',num2str(sim_number),'_dll_status.mat')

%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
tf_update_cell_status=0;
sim_folder='';  %%%%%Empty sim_folder to not update.
[cell_status]=checkout_cell_status_GPT_rev2(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status);
if tf_recalculate==1
    cell_status(:,2)=num2cell(0);
end
zero_idx=find(cell2mat(cell_status(:,2))==0);
cell_status

if ~isempty(zero_idx)==1
    temp_folder_names=folder_names(zero_idx)
    num_folders=length(temp_folder_names);

    %%%%%%%%Pick a random folder and go to the folder to do the sim
    disp_progress(app,strcat('Neighborhood Calc Rev14: Line 18:',string_prop_model))
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
    [multi_hWaitbar,multi_hWaitbarMsgQueue]=ParForWaitbarCreateMH_time('Multi-Folder Binary Search: ',num_folders);    %%%%%%% Create ParFor Waitbar

    for folder_idx=1:1:num_folders
        server_status_rev2(app,tf_server_status)
        disp_progress(app,strcat('Neighborhood Calc Rev14: folder_idx: ',num2str(folder_idx)))

        %%%%%%%%%%%%%%Check cell_status
        tf_update_cell_status=0;
        sim_folder='';
        [cell_status]=checkout_cell_status_GPT_rev2(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status);
        disp_TextArea_PastText(app,strcat('part2_neigh_calc_rev14_multi_server: After Checkout'))

        sim_folder=temp_folder_names{array_rand_folder_idx(folder_idx)};
        temp_cell_idx=find(strcmp(cell_status(:,1),sim_folder)==1);

        if cell_status{temp_cell_idx,2}==0
            %%%%%%%%%%Calculate
            retry_cd_folder_rev1(app,rev_folder)
            sim_folder=temp_folder_names{array_rand_folder_idx(folder_idx)};
            retry_cd_folder_rev1(app,sim_folder)
            disp_multifolder(app,sim_folder)
            data_label1=sim_folder;

            %%%%%%Check for the complete file
            complete_filename=strcat(data_label1,'_',label_single_filename,'.mat');
            [var_exist]=persistent_matfile_exists_with_corruption_GPT_rev2(app,complete_filename);
            if tf_recalculate==1
                var_exist=0
            end

            if var_exist==2
                retry_cd_folder_rev1(app,rev_folder)
                %%%%%%%%Update the Cell
                tf_update_cell_status=1;
                tic;
                [~]=checkout_cell_status_GPT_rev2(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status);
                toc;
            else
                server_status_rev2(app,tf_server_status)
                disp_progress(app,strcat('Neighborhood Calc Rev14: Loading Data . . . '))
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
                custom_antenna_pattern=load_variable_with_retry_GPT_rev2(app, data_label1+"_custom_antenna_pattern.mat", "custom_antenna_pattern");

                %%%%%%%%%%Binary Search
                [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                [num_ppts,~]=size(base_protection_pts);
                if num_ppts==1
                    max_number_calc=ceil(log2(sim_radius_km))+3
                else
                    max_number_calc=(ceil(log2(sim_radius_km))+3)*num_ppts
                end
                disp_progress(app,strcat('Neighborhood Calc Rev14: max_number_calc: ', num2str(max_number_calc)))

                [hWaitbar_binary,hWaitbarMsgQueue_binary]= ParForWaitbarCreateMH_time('Binary Search: ',max_number_calc);

                binary_dist_array=[1,2,4,8,16,32,64,128,256,512,1024,2048];
                CBSD_label='BaseStation';
                [nn_idx]=nearestpoint_app(app,sim_radius_km,binary_dist_array,'next');
                bs_neighborhood=binary_dist_array(nn_idx);
                search_dist_array=horzcat(0:min_binaray_spacing:bs_neighborhood);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Start of Binary Search
                [all_data_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,CBSD_label);

                %%%%%%%%%%Find the secondary DPA Threshold and Percentiles
                data_header=cell_sim_data(1,:)';
                label_idx=find(matches(data_header,'data_label1'));
                row_folder_idx=find(matches(cell_sim_data(:,label_idx),sim_folder));

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

                if tf_second_data==1
                    [all_secondary_stats_binary]=initialize_or_load_secondary_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,'secondary');
                end
                all_data_stats_binary
                all_secondary_stats_binary
                disp_progress(app,strcat('Neighborhood Calc Rev14: loaded all_data_stats_binary'))

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Starting the Binary Search
                binary_marker=0;
                tf_search=1;
                while(tf_search==1)
                    server_status_rev2(app,tf_server_status)
                    disp_progress(app,strcat('Neighborhood Calc Rev14: Top of While Loop: tf_search:',num2str(tf_search)))
                    binary_marker=binary_marker+1;
                    if binary_marker==1
                        single_search_dist=max(search_dist_array)
                        temp_data=all_data_stats_binary{1};
                        if isempty(temp_data)==1
                            temp_data_dist=NaN(1);
                        else
                            temp_data_dist=temp_data(:,1);
                        end
                    elseif binary_marker==2
                        single_search_dist=min(search_dist_array)
                        temp_data=all_data_stats_binary{1};
                        temp_data_dist=temp_data(:,1);
                    else
                        single_search_dist=next_single_search_dist
                        temp_data=all_data_stats_binary{1};
                        temp_data_dist=temp_data(:,1);
                    end
                    disp_progress(app,strcat('Neighborhood Calc Rev14: Search Distance:',num2str(single_search_dist),'km'))

                    if any(temp_data_dist==single_search_dist)==1
                        %%%%%%%%Already calculated
                    else
                        %%%%%%%%Calculate
                        disp_progress(app,strcat('Neighborhood Calc Rev14: Calculating distance:',num2str(single_search_dist),'km'))

                        file_name_single_scrap_data=strcat(CBSD_label,'_',data_label1,'_',num2str(sim_number),'_single_scrap_data_',num2str(single_search_dist),'.mat');
                        [var_exist_single_scrap_data]=persistent_var_exist_with_corruption(app,file_name_single_scrap_data);

                        if tf_second_data==1
                            file_name_second_scrap_data=strcat(CBSD_label,'_',data_label1,'_',num2str(sim_number),'_second_scrap_data_',num2str(single_search_dist),'.mat');
                            [var_exist_file_name_second_scrap_data]=persistent_var_exist_with_corruption(app,file_name_second_scrap_data);
                        end

                        if var_exist_single_scrap_data==2
                            disp_progress(app,strcat('Neighborhood Calc Rev14: Loading single_scrap_data:',num2str(single_search_dist),'km'))
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
                        else
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            %%%%% MULTI-SERVER PHASE 1: Distribute pre_sort across servers
                            %%%%%  Each server claims unclaimed point_idx slots and
                            %%%%%  calls pre_sort_movelist_rev20f (saves per-point files).
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            server_status_rev2(app,tf_server_status)
                            disp_progress(app,strcat('Neighborhood Calc Rev14: Phase 1 Pre-sort claims:',num2str(single_search_dist),'km'))

                            file_name_union_move=strcat(CBSD_label,'_union_turn_off_list_data_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
                            [file_union_move_exist]=persistent_var_exist_with_corruption(app,file_name_union_move);

                            if file_union_move_exist~=2
                                %%%%%Phase 1: claim-based pre-sort computation
                                for point_idx=1:1:num_ppts
                                    move_sort_file_name=strcat(string_prop_model,'_move_sort_sim_array_list_bs_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
                                    [presort_done]=persistent_var_exist_with_corruption(app,move_sort_file_name);
                                    if presort_done==2
                                        continue; %%%%Already computed by this or another server
                                    end
                                    %%%%Try to claim this point
                                    claim_dir=strcat('claim_presort_pt',num2str(point_idx),'_',num2str(single_search_dist),'km_',data_label1,'.lockdir');
                                    [tf_claimed]=try_claim_work_unit(claim_dir);
                                    if tf_claimed
                                        disp_progress(app,strcat('Neighborhood Calc Rev14: Claimed pre-sort pt',num2str(point_idx)))
                                        pre_sort_movelist_rev20f_dual_turnoff_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,tf_opt,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,move_list_margin,tf_full_turnoff,cell_sim_data,sim_folder);
                                        release_work_unit(claim_dir);
                                    end
                                    %%%%If not claimed, another server owns it — move on
                                end

                                %%%%%Phase 2: Poll until all pre-sort files exist
                                disp_progress(app,strcat('Neighborhood Calc Rev14: Phase 2 Waiting for all pre-sort pts:',num2str(single_search_dist),'km'))
                                poll_until_all_presort_done(app,num_ppts,string_prop_model,move_list_reliability,sim_number,mc_size,single_search_dist,tf_server_status);

                                %%%%%Phase 3: One server assembles union; others poll
                                disp_progress(app,strcat('Neighborhood Calc Rev14: Phase 3 Union collection:',num2str(single_search_dist),'km'))
                                collect_union_dir=strcat('collect_union_',num2str(single_search_dist),'km_',data_label1,'.lockdir');
                                [tf_union_collector]=try_claim_work_unit(collect_union_dir);

                                if tf_union_collector
                                    %%%%This server assembles the union move list
                                    cell_move_list_turn_off_data=cell(num_ppts,1);
                                    for point_idx=1:1:num_ppts
                                        point_idx
                                        [move_sort_sim_array_list_bs]=pre_sort_movelist_rev20f_dual_turnoff_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,tf_opt,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,move_list_margin,tf_full_turnoff,cell_sim_data,sim_folder);
                                        if ~isnan(move_sort_sim_array_list_bs(1,1))
                                            cell_move_list_turn_off_data{point_idx}=move_sort_sim_array_list_bs;
                                        end
                                    end
                                    toc;

                                    union_turn_off_list_data=unique(vertcat(cell_move_list_turn_off_data{:}),'rows');
                                    if ~isempty(union_turn_off_list_data)
                                        union_turn_off_list_data=union_turn_off_list_data(~isnan(union_turn_off_list_data(:,1)),:);
                                    end
                                    size(union_turn_off_list_data)

                                    disp_progress(app,strcat('Neighborhood Calc Rev14: Saving Union Move List:',num2str(single_search_dist),'km'))
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
                                    release_work_unit(collect_union_dir);
                                else
                                    %%%%Poll until union file exists
                                    disp_progress(app,strcat('Neighborhood Calc Rev14: Waiting for union file:',num2str(single_search_dist),'km'))
                                    poll_until_file_exists_rev1(app,file_name_union_move,tf_server_status);
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
                                end
                            else
                                disp_progress(app,strcat('Neighborhood Calc Rev14: Loading existing Union:',num2str(single_search_dist),'km'))
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
                            end

                            disp_progress(app,strcat('Neighborhood Calc Rev14: Union done, building on_list_bs:',num2str(single_search_dist),'km'))
                            [on_list_bs,off_idx] = create_on_list_bs_GPT_rev1(app,sim_array_list_bs,union_turn_off_list_data);

                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            %%%%% MULTI-SERVER PHASE 4: Distribute agg-check across servers
                            %%%%%  Each server claims unclaimed point_idx slots and
                            %%%%%  calls agg_check_rev6_clutter_app (saves per-point files).
                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            disp_progress(app,strcat('Neighborhood Calc Rev14: Phase 4 Agg-check claims:',num2str(single_search_dist),'km'))
                            server_status_rev2(app,tf_server_status)

                            for point_idx=1:1:num_ppts
                                agg_check_file_name=strcat(string_prop_model,'_array_agg_check_95_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
                                [aggcheck_done]=persistent_var_exist_with_corruption(app,agg_check_file_name);
                                if aggcheck_done==2
                                    continue; %%%%Already computed
                                end
                                %%%%Try to claim this point
                                claim_dir=strcat('claim_aggcheck_pt',num2str(point_idx),'_',num2str(single_search_dist),'km_',data_label1,'.lockdir');
                                [tf_claimed]=try_claim_work_unit(claim_dir);
                                if tf_claimed
                                    disp_progress(app,strcat('Neighborhood Calc Rev14: Claimed agg-check pt',num2str(point_idx)))
                                    agg_check_rev6_clutter_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth,custom_antenna_pattern,bs_eirp_dist,cell_aas_dist_data,cell_sim_data,sim_folder);
                                    release_work_unit(claim_dir);
                                end
                            end

                            %%%%%Phase 5: Poll until all agg-check files exist
                            disp_progress(app,strcat('Neighborhood Calc Rev14: Phase 5 Waiting for all agg-check pts:',num2str(single_search_dist),'km'))
                            poll_until_all_aggcheck_done(app,num_ppts,string_prop_model,agg_check_reliability,sim_number,mc_size,single_search_dist,tf_server_status);

                            %%%%%Phase 6: One server assembles scrap_data; others poll
                            disp_progress(app,strcat('Neighborhood Calc Rev14: Phase 6 Scrap collection:',num2str(single_search_dist),'km'))
                            collect_scrap_dir=strcat('collect_scrap_',num2str(single_search_dist),'km_',data_label1,'.lockdir');
                            [tf_scrap_collector]=try_claim_work_unit(collect_scrap_dir);

                            if tf_scrap_collector
                                %%%%This server assembles scrap_data
                                cell_agg_check_data=cell(num_ppts,1);
                                single_scrap_data=NaN(num_ppts,2);
                                second_scrap_data=NaN(num_ppts,2);
                                disp_progress(app,strcat('Neighborhood Calc Rev14: Collecting scrap_data:',num2str(single_search_dist),'km'))
                                server_status_rev2(app,tf_server_status)

                                for point_idx=1:1:num_ppts
                                    point_idx
                                    [array_agg_check_95,array_agg_check_mc_dBm]=agg_check_rev6_clutter_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth,custom_antenna_pattern,bs_eirp_dist,cell_aas_dist_data,cell_sim_data,sim_folder);
                                    cell_agg_check_data{point_idx}=array_agg_check_95;
                                    single_scrap_data(point_idx,1)=max(array_agg_check_95);
                                    if isempty(off_idx)
                                        single_scrap_data(point_idx,2)=0;
                                    else
                                        single_scrap_data(point_idx,2)=length(off_idx);
                                    end

                                    if isnan(single_scrap_data(point_idx,1))
                                        if bs_neighborhood==single_search_dist && tf_full_turnoff==1
                                            single_scrap_data(point_idx,1)=radar_threshold-0.1;
                                        else
                                            disp_progress(app,strcat('ERROR PAUSE: part2_neigh_calc_rev14: aggregate NaN at pt',num2str(point_idx)))
                                            pause;
                                        end
                                    end

                                    if tf_second_data==1
                                        array_agg_check_second=prctile(sort(array_agg_check_mc_dBm),mc_per2);
                                        second_scrap_data(point_idx,1)=array_agg_check_second;
                                        if isempty(off_idx)
                                            second_scrap_data(point_idx,2)=0;
                                        else
                                            second_scrap_data(point_idx,2)=length(off_idx);
                                        end
                                        second_scrap_data
                                    else
                                        'Need to check what happens'
                                        pause;
                                    end

                                    if tf_second_data==1
                                        if isnan(second_scrap_data(point_idx,1))
                                            if bs_neighborhood==single_search_dist && tf_full_turnoff==1
                                                second_scrap_data(point_idx,1)=radar2threshold-0.1;
                                            else
                                                disp_progress(app,strcat('ERROR PAUSE: part2_neigh_calc_rev14: secondary aggregate NaN at pt',num2str(point_idx)))
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

                                disp_progress(app,strcat('Neighborhood Calc Rev14: Saving single_scrap_data:',num2str(single_search_dist),'km'))
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
                                release_work_unit(collect_scrap_dir);
                            else
                                %%%%Poll until scrap_data file exists
                                disp_progress(app,strcat('Neighborhood Calc Rev14: Waiting for scrap_data file:',num2str(single_search_dist),'km'))
                                poll_until_file_exists_rev1(app,file_name_single_scrap_data,tf_server_status);
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
                            end
                        end

                        server_status_rev2(app,tf_server_status)
                        disp_progress(app,strcat('Neighborhood Calc Rev14: Updating all_data_stats_binary:',num2str(single_search_dist),'km'))
                        single_scrap_data
                        second_scrap_data

                        [all_data_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,CBSD_label);
                        [all_data_stats_binary]=update_all_data_distance_rev1(app,all_data_stats_binary,single_search_dist,single_scrap_data);

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

                        if tf_second_data==1
                            [all_secondary_stats_binary]=initialize_or_load_secondary_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,'secondary');
                            [all_secondary_stats_binary]=update_all_data_distance_rev1(app,all_secondary_stats_binary,single_search_dist,second_scrap_data);
                        end

                        all_secondary_stats_binary
                        all_secondary_stats_binary{:}

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
                    disp_progress(app,strcat('Neighborhood Calc Rev14: Trying to Find the Next Distance:',num2str(single_search_dist),'km'))

                    [all_data_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,CBSD_label);

                    if tf_second_data==1
                        [all_secondary_stats_binary]=initialize_or_load_secondary_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,'secondary');
                    end

                    if binary_marker>1
                        disp_progress(app,strcat('Neighborhood Calc Rev14: Before calc_next_search_dist'))
                        [next_single_search_dist,tf_search,temp_bs_dist_data,array_searched_dist]=calc_next_search_dist(app,all_data_stats_binary,radar_threshold,margin,maine_exception,tf_full_binary_search,min_binaray_spacing)
                        disp_progress(app,strcat('Neighborhood Calc Rev14: After calc_next_search_dist'))
                        next_single_search_dist

                        if tf_second_data==1
                            if tf_search==0
                                [next_single_search_dist,tf_search,temp_bs_dist_data,array_searched_dist]=calc_next_search_dist(app,all_secondary_stats_binary,radar2threshold,margin,maine_exception,tf_full_binary_search,min_binaray_spacing)
                            end
                        end
                    end
                    hWaitbarMsgQueue_binary.send(0);
                end
                tf_search

                disp_progress(app,strcat('Neighborhood Calc Rev14: Outside of While Loop'))
                server_status_rev2(app,tf_server_status)

                [all_data_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,CBSD_label);

                if tf_second_data==1
                    [all_secondary_stats_binary]=initialize_or_load_secondary_data_stats_binary_pre_label(app,data_label1,sim_number,base_protection_pts,'secondary');
                end

                all_data_stats_binary{:}
                all_secondary_stats_binary{:}

                catb_dist_data=calculate_neighborhood_dist_rev1(app,all_data_stats_binary,radar_threshold,margin);
                if tf_second_data==1
                    catb_dist_data2=calculate_neighborhood_dist_rev1(app,all_secondary_stats_binary,radar2threshold,margin);
                    horzcat(catb_dist_data,catb_dist_data2)
                    catb_dist_data=max(horzcat(catb_dist_data,catb_dist_data2),[],2);
                end

                buffer_radius=max(catb_dist_data)
                if isnan(buffer_radius)==1 || buffer_radius==0
                    buffer_radius=1;
                end

                nnan_base_polygon=base_polygon(~isnan(base_polygon(:,1)),:);
                [neighborhood_bound]=calc_sim_bound(app,nnan_base_polygon,buffer_radius,data_label1);

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

                plot_neigh_hist_rev1(app,catb_dist_data,data_label1,CBSD_label,sim_number)
                plot_neigh_map_rev1(app,nnan_base_polygon,base_polygon,neighborhood_bound,data_label1,CBSD_label,buffer_radius,sim_number)
                plot_neigh_binary_search_rev1(app,catb_dist_data,all_data_stats_binary,radar_threshold,margin,data_label1,CBSD_label,sim_number)
                if tf_second_data==1
                    plot_neigh_binary_search_rev1(app,catb_dist_data,all_secondary_stats_binary,radar2threshold,margin,data_label1,'secondary',sim_number)
                end

                disp_progress(app,strcat('Neighborhood Calc Rev14: Plotting the Data'))
                tf_catb=1;

                try
                    delete(hWaitbarMsgQueue_binary);
                catch
                end
                try
                    close(hWaitbar_binary);
                catch
                end

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
                        disp_progress(app,strcat('Neighborhood Calc Rev14: Cant Save Stats Table'))
                    end
                end

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
                            disp_progress(app,strcat('Neighborhood Calc Rev14: Cant Save Secondary Stats Table'))
                        end
                    end
                end

                excel_print_empty_union_bsidx_rev3(app,tf_print_excel,reliability,data_label1,mc_size,base_protection_pts,sim_array_list_bs,string_prop_model,sim_number,norm_aas_zero_elevation_data,radar_beamwidth,min_azimuth,max_azimuth,move_list_reliability,sim_radius_km,custom_antenna_pattern,dpa_threshold)

                [zone_dist_km]=calc_zone_distance_rev1(app, all_data_stats_binary, radar_threshold, margin)

                if num_ppts>1
                    'Need to put all distributions on a CDF plot.'
                    pause;
                end

                %%%%%%%%%%%Save completion marker
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
                [~]=checkout_cell_status_GPT_rev2(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status);
                toc;
                disp_TextArea_PastText(app,strcat('part2_neigh_calc_rev14_multi_server: After Checkout update'))
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
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Local helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [tf_claimed]=try_claim_work_unit(lock_dir)
%try_claim_work_unit  Atomically claim a work unit via mkdir.
%  Returns true if this server created the directory (claim succeeded),
%  false if the directory already existed (another server owns it).
%  Uses mkdir atomicity — safe for concurrent multi-server access.
%
%  Input validation
if isempty(lock_dir) || ~(ischar(lock_dir) || isstring(lock_dir))
    tf_claimed=false;
    return;
end
tf_claimed=false;
try
    [success,~]=mkdir(lock_dir);
    tf_claimed=logical(success);
catch
    tf_claimed=false;
end
end


function release_work_unit(lock_dir)
%release_work_unit  Release a claimed work unit by removing its lockdir.
%  Safe to call even if the directory doesn't exist.
%
%  Input validation
if isempty(lock_dir) || ~(ischar(lock_dir) || isstring(lock_dir))
    return;
end
try
    rmdir(lock_dir,'s');
catch
end
end


function poll_until_file_exists_rev1(app,file_name,tf_server_status)
%poll_until_file_exists_rev1  Block until file_name exists (or 1-hour timeout).
%  Polls every 10 seconds. Calls server_status_rev2 and disp_progress
%  while waiting so the UI stays responsive.
%
%  Input validation
if isempty(file_name) || ~(ischar(file_name) || isstring(file_name))
    disp_progress(app,'ERROR PAUSE: poll_until_file_exists_rev1: file_name is empty or not a string')
    pause;
end

poll_timeout_s=3600; %%%%1-hour hard timeout
poll_interval_s=10;
elapsed_s=0;
while elapsed_s<poll_timeout_s
    [f_exist]=persistent_var_exist_with_corruption(app,file_name);
    if f_exist==2
        return; %%%%File ready
    end
    server_status_rev2(app,tf_server_status)
    disp_progress(app,strcat('poll_until_file_exists_rev1: waiting for ',file_name,' (',num2str(elapsed_s),'s)'))
    pause(poll_interval_s);
    elapsed_s=elapsed_s+poll_interval_s;
end
disp_progress(app,strcat('ERROR PAUSE: poll_until_file_exists_rev1: timeout waiting for ',file_name))
pause;
end


function poll_until_all_presort_done(app,num_ppts,string_prop_model,move_list_reliability,sim_number,mc_size,single_search_dist,tf_server_status)
%poll_until_all_presort_done  Block until all num_ppts pre-sort files exist.
%  Polls every 10 seconds. Calls server_status_rev2 while waiting.
%
%  Input validation
if ~isnumeric(num_ppts) || ~isscalar(num_ppts) || num_ppts<1
    disp_progress(app,'ERROR PAUSE: poll_until_all_presort_done: num_ppts is invalid')
    pause;
end

poll_timeout_s=3600;
poll_interval_s=10;
elapsed_s=0;
all_done=false;
while ~all_done && elapsed_s<poll_timeout_s
    all_done=true;
    for point_idx=1:num_ppts
        move_sort_file_name=strcat(string_prop_model,'_move_sort_sim_array_list_bs_',num2str(min(move_list_reliability)),'_',num2str(max(move_list_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
        [f_exist]=persistent_var_exist_with_corruption(app,move_sort_file_name);
        if f_exist~=2
            all_done=false;
            break;
        end
    end
    if ~all_done
        server_status_rev2(app,tf_server_status)
        disp_progress(app,strcat('poll_until_all_presort_done: waiting at ',num2str(single_search_dist),'km (',num2str(elapsed_s),'s)'))
        pause(poll_interval_s);
        elapsed_s=elapsed_s+poll_interval_s;
    end
end
if ~all_done
    disp_progress(app,strcat('ERROR PAUSE: poll_until_all_presort_done: timeout at ',num2str(single_search_dist),'km'))
    pause;
end
end


function poll_until_all_aggcheck_done(app,num_ppts,string_prop_model,agg_check_reliability,sim_number,mc_size,single_search_dist,tf_server_status)
%poll_until_all_aggcheck_done  Block until all num_ppts agg-check files exist.
%  Polls every 10 seconds. Calls server_status_rev2 while waiting.
%
%  Input validation
if ~isnumeric(num_ppts) || ~isscalar(num_ppts) || num_ppts<1
    disp_progress(app,'ERROR PAUSE: poll_until_all_aggcheck_done: num_ppts is invalid')
    pause;
end

poll_timeout_s=3600;
poll_interval_s=10;
elapsed_s=0;
all_done=false;
while ~all_done && elapsed_s<poll_timeout_s
    all_done=true;
    for point_idx=1:num_ppts
        agg_check_file_name=strcat(string_prop_model,'_array_agg_check_95_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
        [f_exist]=persistent_var_exist_with_corruption(app,agg_check_file_name);
        if f_exist~=2
            all_done=false;
            break;
        end
    end
    if ~all_done
        server_status_rev2(app,tf_server_status)
        disp_progress(app,strcat('poll_until_all_aggcheck_done: waiting at ',num2str(single_search_dist),'km (',num2str(elapsed_s),'s)'))
        pause(poll_interval_s);
        elapsed_s=elapsed_s+poll_interval_s;
    end
end
if ~all_done
    disp_progress(app,strcat('ERROR PAUSE: poll_until_all_aggcheck_done: timeout at ',num2str(single_search_dist),'km'))
    pause;
end
end
