function neighborhood_wrapper_rev1(app,rev_folder,parallel_flag)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%App Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RandStream('mt19937ar','Seed','shuffle')
%%%reset(RandStream.getGlobalStream,sum(100*clock))
%%%%%%Create a random number stream using a generator seed based on the current time.
%%%%%%It is usually not desirable to do this more than once per MATLAB session as it may affect the statistical properties of the random numbers MATLAB produces.
%%%%%%%%We do this because the compiled app sets all the random number stream to the same, as it's running on different servers. Then the servers hop to each folder at the same time, which is not what we want.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Toolbox Check (Sims can run without the Parallel Toolbox)
[workers,parallel_flag]=check_parallel_toolbox(app,parallel_flag);

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
[confidence]=load_data_confidence(app);
[FreqMHz]=load_data_FreqMHz(app);
[Tpol]=load_data_Tpol(app);
[building_loss]=load_data_building_loss(app);
[mc_percentile]=load_data_mc_percentile(app);
[mc_size]=load_data_mc_size(app);
[sim_radius_km]=load_data_sim_radius_km(app);
[array_bs_eirp_reductions]=load_data_array_bs_eirp_reductions(app);
[norm_aas_zero_elevation_data]=load_data_norm_aas_zero_elevation_data(app);
[margin]=load_data_margin(app);
[tf_full_binary_search]=load_data_tf_full_binary_search(app);
[min_binaray_spacing]=load_data_min_binaray_spacing(app);
[tf_opt]=load_data_tf_opt(app);
[maine_exception]=load_data_maine_exception(app);
[deployment_percentage]=load_data_deployment_percentage(app);
[agg_check_reliability]=load_data_agg_check_reliability(app);
server_status_rev1(app)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Step 1: Propagation Loss (ITM)
%%%%%%%We've created a folder with all the code for the propagation loss
%addpath('C:\Local Matlab Data\General_Terrestrial_Pathloss')  %%%%%%%%Where we will put the pathloss functions.
string_prop_model='ITM'

num_chunks=24;  %%%%%%%%%This number needs to be set right here to not create possible mismatch error.
% %%%%The idea is to set the num_chunks to the maximum number of cores for one server.
%%%%%%But the number can't be based on the actual number of cores for the
%%%%%%server it is running on, because some servers have a different number
%%%%%%of cores, which would change the number of chunks.

part1_calc_pathloss_itm_or_tirem_rev4(app,rev_folder,folder_names,parallel_flag,sim_number,reliability,confidence,FreqMHz,Tpol,workers,string_prop_model,num_chunks)
propagation_clean_up_rev1(app,rev_folder,folder_names,parallel_flag,sim_number,workers,string_prop_model,num_chunks)

%%%%%%neighborhood_calc_rev1(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,sim_radius_km,min_binaray_spacing,margin,maine_exception,tf_full_binary_search,agg_check_reliability,tf_opt)
neighborhood_calc_rev2_azimuths(app,folder_names,parallel_flag,rev_folder,workers,move_list_reliability,sim_number,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,sim_radius_km,min_binaray_spacing,margin,maine_exception,tf_full_binary_search,agg_check_reliability,tf_opt)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Scrap the Data for each DPA: Neighborhood Distance and Move List size
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


if  parallel_flag==1
    poolobj=gcp('nocreate');
    delete(poolobj);
end

disp_progress(app,strcat('Sim Done'))


end