function wrapper_move_list_agg_check_rev2(app,parallel_flag,rev_folder,tf_server_status,workers)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%App Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RandStream('mt19937ar','Seed','shuffle')
%%%reset(RandStream.getGlobalStream,sum(100*clock))
%%%%%%Create a random number stream using a generator seed based on the current time.
%%%%%%It is usually not desirable to do this more than once per MATLAB session as it may affect the statistical properties of the random numbers MATLAB produces.
%%%%%%%%We do this because the compiled app sets all the random number stream to the same, as it's running on different servers. Then the servers hop to each folder at the same time, which is not what we want.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Toolbox Check (Sims can run without the Parallel Toolbox)
%[workers,parallel_flag]=check_parallel_toolbox(app,parallel_flag);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check for the Number of Folders to Sim
[sim_number,folder_names,num_folders]=check_rev_folders(app,rev_folder);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%If we have it, start the parpool.
disp_progress(app,strcat(rev_folder,'--> Starting Parallel Workers . . . [This usually takes a little time]'))
tic;
[poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
toc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load all the mat files in the main folder


[reliability]=load_data_reliability(app);
[move_list_reliability]=load_data_move_list_reliability(app);
[agg_check_reliability]=load_data_agg_check_reliability(app);
[confidence]=load_data_confidence(app);
[FreqMHz]=load_data_FreqMHz(app);
[Tpol]=load_data_Tpol(app);
[building_loss]=load_data_building_loss(app);
[mc_percentile]=load_data_mc_percentile(app);
[move_list_mc_percentile]=load_data_move_list_mc_percentile(app);
[agg_check_mc_percentile]=load_data_agg_check_mc_percentile(app);
[mc_size]=load_data_mc_size(app);
[move_list_mc_size]=load_data_move_list_mc_size(app);
[agg_check_mc_size]=load_data_agg_check_mc_size(app);
%[sim_radius_km]=load_data_sim_radius_km(app);
[array_bs_eirp_reductions]=load_data_array_bs_eirp_reductions(app);
[norm_aas_zero_elevation_data]=load_data_norm_aas_zero_elevation_data(app);
[margin]=load_data_margin(app);
[deployment_percentage]=load_data_deployment_percentage(app);
[tf_clutter]=load_data_tf_clutter(app);
[mitigation_dB]=load_data_mitigation_dB(app);
[tf_opt]=load_data_tf_opt(app);
server_status_rev2(app,tf_server_status)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Step 1: Propagation Loss (ITM)
string_prop_model='ITM'
num_chunks=24;  %%%%%%%%%This number needs to be set right here to not create possible mismatch error.
% %%%%The idea is to set the num_chunks to the maximum number of cores for one server.
%%%%%%But the number can't be based on the actual number of cores for the
%%%%%%server it is running on, because some servers have a different number
%%%%%%of cores, which would change the number of chunks.
tf_recalc_pathloss=0
part1_calc_pathloss_clutter2108_rev11(app,rev_folder,folder_names,parallel_flag,sim_number,reliability,confidence,FreqMHz,Tpol,workers,string_prop_model,tf_recalc_pathloss,tf_server_status,tf_clutter)
server_status_rev2(app,tf_server_status)



% % % % % % % % % % % % % % % % 'Step 1: Calculate pathloss for all reliability for DPA, larger than the CatB Neighborhood'
% % % % % % % % % % % % % % % % 'Step 2: Calculate the move list, 50% with the CBRS 2.0 edits and the CatB Neighborhood'
% % % % % % % % % % % % % % % % 'Step 3: Calculate the aggregate with all the reliability, minus the 50% move list'
part2_movelist_calculation_rev4_with_miti(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,move_list_mc_size,move_list_mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,mitigation_dB,tf_server_status,tf_opt)
part3_full_aggregate_check_rev2(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,agg_check_mc_size,agg_check_mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,mitigation_dB,agg_check_reliability,tf_server_status,move_list_mc_size,move_list_mc_percentile)


% % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Scrap the Data for each DPA:
 wrapper_scrap_agg_data_rev1(app,rev_folder,sim_number,folder_names,tf_server_status,string_prop_model,agg_check_reliability,agg_check_mc_size,agg_check_mc_percentile)




if  parallel_flag==1
    poolobj=gcp('nocreate');
    delete(poolobj);
end

disp_progress(app,strcat('Sim Done'))
end