function neighborhood_wrapper_rev6_miti_geoplots_pea_custant_excel(app,rev_folder,parallel_flag,tf_server_status,workers,tf_recalculate,tf_rescrap_rev_data,tf_print_excel)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Now running the simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%App Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

RandStream('mt19937ar','Seed','shuffle')
%%%%%%Create a random number stream using a generator seed based on the current time.
%%%%%%It is usually not desirable to do this more than once per MATLAB session as it may affect the statistical properties of the random numbers MATLAB produces.
%%%%%%%%We do this because the compiled app sets all the random number stream to the same, as it's running on different servers. Then the servers hop to each folder at the same time, which is not what we want.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load all the mat files in the main folder
[reliability]=load_data_reliability(app);
[move_list_reliability]=load_data_move_list_reliability(app);
[agg_check_reliability]=load_data_agg_check_reliability(app);
[confidence]=load_data_confidence(app);
[FreqMHz]=load_data_FreqMHz(app);
[Tpol]=load_data_Tpol(app);
[mitigation_dB]=load_data_mitigation_dB(app);
[bs_eirp_reductions]=load_data_bs_eirp_reductions(app);
array_mitigation=mitigation_dB;
[sim_number]=get_rev_folder_number(app,rev_folder);
[cell_sim_data]=load_data_cell_sim_data(app);
[tf_clutter]=load_data_tf_clutter(app);
[building_loss]=load_data_building_loss(app);
[mc_percentile]=load_data_mc_percentile(app);
[mc_size]=load_data_mc_size(app);
[sim_radius_km]=load_data_sim_radius_km(app);
[norm_aas_zero_elevation_data]=load_data_norm_aas_zero_elevation_data(app);
[margin]=load_data_margin(app);
[tf_full_binary_search]=load_data_tf_full_binary_search(app);
[min_binaray_spacing]=load_data_min_binaray_spacing(app);
[tf_opt]=load_data_tf_opt(app);
[maine_exception]=load_data_maine_exception(app);
[deployment_percentage]=load_data_deployment_percentage(app);
[base_station_latlonheight]=load_data_base_station_latlonheight(app);
server_status_rev2(app,tf_server_status)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Step 0: Make the grid points
disp_TextArea_PastText(app,strcat('Entering into Part0: Creating Grid Points'))
part0_deployment_pts_folders_cust_ant_rev2(app,sim_number,bs_eirp_reductions,rev_folder,tf_server_status,cell_sim_data,base_station_latlonheight,sim_radius_km,FreqMHz)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Step 1: Propagation Loss (ITM)
string_prop_model='ITM'
tf_recalc_pathloss=0
if tf_recalc_pathloss==1
    tf_recalculate=1
end
disp_TextArea_PastText(app,strcat('Entering into Part1'))
part1_calc_pathloss_clutter2108_max64_rev13(app,rev_folder,parallel_flag,reliability,confidence,FreqMHz,Tpol,workers,string_prop_model,tf_recalc_pathloss,tf_server_status,tf_clutter)
server_status_rev2(app,tf_server_status)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Step 2: Neighborhood Sim
%neighborhood_calc_rev4_azimuths_geoplots_custant(app,parallel_flag,rev_folder,workers,move_list_reliability,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,sim_radius_km,min_binaray_spacing,margin,maine_exception,tf_full_binary_search,agg_check_reliability,tf_opt,tf_recalc_pathloss,tf_server_status)
part2_neigh_calc_rev5_azi_geoplots_custant_excel(app,parallel_flag,rev_folder,workers,move_list_reliability,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,sim_radius_km,min_binaray_spacing,margin,maine_exception,tf_full_binary_search,agg_check_reliability,tf_opt,tf_recalculate,tf_server_status,tf_print_excel)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'Now do the mitigation move list within the neighborhood.'
part3_neighborhood_miti_movelist_geoplots_custant_rev6(app,parallel_flag,rev_folder,workers,move_list_reliability,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,tf_opt,tf_server_status,tf_recalculate,array_mitigation)


% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%part 4 Census Pop Impact
tf_convex=1
scrap_data_pop_geo_id_pea_rev8(app,tf_rescrap_rev_data,sim_number,string_prop_model,array_mitigation,rev_folder,tf_server_status,reliability,tf_convex)


%%'Uncomment these for the final version.'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Scrap the Data for each DPA: Neighborhood Distance and Move List size
[sim_number,folder_names,~]=check_rev_folders(app,rev_folder);
neighborhood_data_scrap_rev1(app,folder_names,rev_folder,sim_number,string_prop_model)

%%%%%%%%%Load the
cell_status_filename=strcat('cell_neighborhood_data',string_prop_model,'_',num2str(sim_number),'.mat')
[cell_status]=initialize_or_load_neighborhood_data_rev1(app,folder_names,cell_status_filename);

%%%%%%%%%%%%'Now write an excel table'
%%%%%%%%Keep the Same Order as the Raw GMF
table_neighborhood_data=cell2table(cell_status(:,[1,3,4]));
table_neighborhood_data.Properties.VariableNames={'DPA_Name' 'Neighborhood_km' 'Move_List_Size'}
%%%%%Save 
retry_save=1;
while(retry_save==1)
    try
        writetable(table_neighborhood_data,strcat('Neighborhood_data_',num2str(sim_number),'.xlsx'));
        pause(0.1)
        retry_save=0;
    catch
        retry_save=1;
        pause(2)
    end
end


if  parallel_flag==1
    poolobj=gcp('nocreate');
    delete(poolobj);
end

disp_TextArea_PastText(app,strcat('Sim Done'))
disp_progress(app,strcat('Sim Done'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%