function neighborhood_wrapper_rev2_geoplots(app,rev_folder,parallel_flag,tf_server_status,workers)

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
%[array_bs_eirp_reductions]=load_data_array_bs_eirp_reductions(app);
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
%%%%%part0_grid_pts_azi_pathloss_folders_rev6(app,sim_number,tx_height_m,bs_eirp_reductions,grid_spacing,rev_folder,tf_server_status,cell_sim_data,array_dist_pl,sim_scale_factor,tf_clutter)
part0_deployment_pts_folders_rev1(app,sim_number,bs_eirp_reductions,rev_folder,tf_server_status,cell_sim_data,base_station_latlonheight,sim_radius_km)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Step 1: Propagation Loss (ITM)
string_prop_model='ITM'
tf_recalc_pathloss=0
disp_TextArea_PastText(app,strcat('Entering into Part1'))
%part1_calc_pathloss_clutter2108_folders_rev12(app,rev_folder,parallel_flag,reliability,confidence,FreqMHz,Tpol,workers,string_prop_model,tf_recalc_pathloss,tf_server_status,tf_clutter)
part1_calc_pathloss_clutter2108_max64_rev13(app,rev_folder,parallel_flag,reliability,confidence,FreqMHz,Tpol,workers,string_prop_model,tf_recalc_pathloss,tf_server_status,tf_clutter)
server_status_rev2(app,tf_server_status)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%neighborhood_calc_rev2_azimuths(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,sim_radius_km,min_binaray_spacing,margin,maine_exception,tf_full_binary_search,agg_check_reliability,tf_opt)
neighborhood_calc_rev3_azimuths_geoplots(app,parallel_flag,rev_folder,workers,move_list_reliability,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,sim_radius_km,min_binaray_spacing,margin,maine_exception,tf_full_binary_search,agg_check_reliability,tf_opt,tf_recalc_pathloss,tf_server_status)


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
writetable(table_neighborhood_data,strcat('Neighborhood_data_',num2str(sim_number),'.xlsx'));
pause(0.1)




% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Bug splat code Make the map
% % % tf_tropo_cut=0;
% % % tf_calc_rx_angle=0
% % % tf_rescrap_pathloss=tf_recalc_pathloss
% % % disp_TextArea_PastText(app,strcat('Entering into Part2'))
% % % part2_bugsplat_maps_azimuth_radial_multi_pop_geoplot_rev13(app,rev_folder,reliability,string_prop_model,grid_spacing,array_reliability_check,tf_calc_rx_angle,tf_recalculate,tf_tropo_cut,tf_server_status,array_mitigation,tf_rescrap_pathloss)
% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % 
% % % 
% % % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Bugsplat part 4 Census Pop Impact
% % % scrap_data_excel_pop_geo_id_pea_rev6(app,tf_rescrap_rev_data,sim_number,string_prop_model,grid_spacing,array_mitigation,rev_folder,tf_server_status)


if  parallel_flag==1
    poolobj=gcp('nocreate');
    delete(poolobj);
end

disp_TextArea_PastText(app,strcat('Sim Done'))
disp_progress(app,strcat('Sim Done'))


end