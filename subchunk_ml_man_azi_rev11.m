function [sub_array_ml_turnoff_mc,sub_array_ml_turnoff_mc_secondary]=subchunk_ml_man_azi_rev11(app,sim_folder,sort_sim_array_list_bs,sort_full_Pr_dBm,super_array_bs_eirp_dist,cell_sim_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,cell_sim_chunk_idx,rand_seed1,sort_clutter_loss,custom_antenna_pattern,sub_point_idx,tf_man_azi_step,azimuth_step,move_list_reliability,radar_threshold,move_list_margin)

%%%%%%%%%%%%%%%%Similar to subchunk_agg_check_maxazi_man_azi_rev10

%%%%%%%%%%%%%%%%Calculate the simualation azimuths
[array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev4_man_azi_app(app,radar_beamwidth,min_azimuth,max_azimuth,tf_man_azi_step,azimuth_step); %%%Include manual azimuth set

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Each Base Station Azimuth
sim_pt=base_protection_pts(point_idx,:);
bs_azimuth=azimuth(sim_pt(1),sim_pt(2),sort_sim_array_list_bs(:,1),sort_sim_array_list_bs(:,2));

%%%%%%%%%%Find the secondary I/N and Percentiles and the
%%%%%Need the secondary, if they are there
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
%radar2threshold
%mc_per2

if ~isnan(radar2threshold)
    tf_second_data=1;
else
    tf_second_data=0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%All the things above could be pulled out of this subchunk.

%%%%%%%%%%%%%%Generate MC Iterations and Calculate Move List
sub_mc_idx=cell_sim_chunk_idx{sub_point_idx};
num_mc_idx=length(sub_mc_idx);
num_bs=length(bs_azimuth);
num_tx=num_bs
sub_array_ml_turnoff_mc=NaN(num_mc_idx,1);
sub_array_ml_turnoff_mc_secondary=NaN(num_mc_idx,1);


% % % % % % -------------------------------------------------------------------------
% % % % % % STEP 1: Deterministic MC random precompute (seed identity preserved)
% % % % % % rand_*_all dimensions: [num_bs x num_mc_idx]
% % % % % % -------------------------------------------------------------------------
% % % rel_min=min(move_list_reliability);
% % % rel_max=max(move_list_reliability);
% % % [num_bs,~]=size(sort_full_Pr_dBm);
% % % 
% % % if rel_min==rel_max
% % %     rand_pr_all=repmat(rel_min,num_bs,num_mc_idx);
% % %     rand_eirp_all=rand_pr_all;
% % %     rand_clutter_all=rand_pr_all;
% % % else
% % %     rand_pr_all=NaN(num_bs,num_mc_idx);
% % %     rand_eirp_all=NaN(num_bs,num_mc_idx);
% % %     rand_clutter_all=NaN(num_bs,num_mc_idx);
% % % 
% % %     for loop_idx=1:1:num_mc_idx
% % %         mc_iter=sub_mc_idx(loop_idx);
% % % 
% % %         rng(rand_seed1+mc_iter); % PR draw identity
% % %         rand_pr_all(:,loop_idx)=rand(num_bs,1)*(rel_max-rel_min)+rel_min;
% % % 
% % %         rng(rand_seed1+mc_iter+1); % EIRP draw identity
% % %         rand_eirp_all(:,loop_idx)=rand(num_bs,1)*(rel_max-rel_min)+rel_min;
% % % 
% % %         rng(rand_seed1+mc_iter+2); % Clutter draw identity
% % %         rand_clutter_all(:,loop_idx)=rand(num_bs,1)*(rel_max-rel_min)+rel_min;
% % %     end
% % % end
% % % % 'rand_pr_all'
% % % % rand_pr_all
% % % % rand_clutter_all
% % % % rel_min==rel_max
% % % % 'size rand_clutter_all'
% % % % size(rand_clutter_all)
% % % % 'check'
% % % % pause;


% % % % % % -------------------------------------------------------------------------
% % % % % % STEP 3/4: Compute MC terms with RNG-free rev helpers.
% % % % % % -------------------------------------------------------------------------
% % % sort_monte_carlo_pr_dBm_all=NaN(num_bs,num_mc_idx);
% % % for loop_idx=1:1:num_mc_idx
% % %     pre_sort_monte_carlo_pr_dBm=monte_carlo_Pr_dBm_rev2_app(app,move_list_reliability,sort_full_Pr_dBm,rand_pr_all(:,loop_idx));
% % %     rand_norm_eirp=monte_carlo_super_bs_eirp_dist_rev5(app,super_array_bs_eirp_dist,move_list_reliability,rand_eirp_all(:,loop_idx));
% % %     monte_carlo_clutter_loss=monte_carlo_clutter_rev3_app(app,move_list_reliability,sort_clutter_loss,rand_clutter_all(:,loop_idx));
% % %     sort_monte_carlo_pr_dBm_all(:,loop_idx)=pre_sort_monte_carlo_pr_dBm+rand_norm_eirp-monte_carlo_clutter_loss;
% % % end
[sort_monte_carlo_pr_dBm_all]=vector_mc_seed_pr_eirp_clutter_rev1(app,move_list_reliability,sort_full_Pr_dBm,super_array_bs_eirp_dist,sort_clutter_loss,sub_mc_idx,rand_seed1);


% %%%%%%%Generate 1 MC Iteration
% mc_iter=1
% %%%%%%%Generate 1 MC Iteration
% [sort_monte_carlo_pr_dBm_test]=monte_carlo_Pr_dBm_rev1_app(app,rand_seed1,mc_iter,move_list_reliability,sort_full_Pr_dBm);
% % % % % sort_monte_carlo_pr_dBm=monte_carlo_Pr_dBm_rev2_app(app,move_list_reliability,sort_full_Pr_dBm,rand_pr_all(:,mc_iter));
% % % % % 'compare sort_monte_carlo_pr_dBm'
% % % % % all(sort_monte_carlo_pr_dBm==sort_monte_carlo_pr_dBm_test)
% 
% %%%%%'interp super_array_bs_eirp_dist in the same way as bs_eirp_dist'
% [rand_norm_eirp_test]=monte_carlo_super_bs_eirp_dist_rev3(app,super_array_bs_eirp_dist,rand_seed1,mc_iter,num_tx,move_list_reliability);
% % % % rand_norm_eirp=monte_carlo_super_bs_eirp_dist_rev5(app,super_array_bs_eirp_dist,move_list_reliability,rand_eirp_all(:,mc_iter));
% % % % 'size rand_norm_eirp_test'
% % % % size(rand_norm_eirp_test)
% % % % 'size rand_norm_eirp'
% % % % size(rand_norm_eirp)
% % % % 'compare rand_norm_eirp'
% % % % all(rand_norm_eirp==rand_norm_eirp_test)
% 
% [monte_carlo_clutter_loss_test]=monte_carlo_clutter_rev1_app(app,rand_seed1,mc_iter,move_list_reliability,sort_clutter_loss);
% % % %  monte_carlo_clutter_loss=monte_carlo_clutter_rev3_app(app,move_list_reliability,sort_clutter_loss,rand_clutter_all(:,mc_iter));
% % % % 'compare MC clutter loss'
% % % % all(monte_carlo_clutter_loss_test==monte_carlo_clutter_loss)
% % 'size rand_clutter_all'
% % size(rand_clutter_all)
% 
% sort_monte_carlo_pr_dBm_test=sort_monte_carlo_pr_dBm_test+rand_norm_eirp_test-monte_carlo_clutter_loss_test;
% 
% 'check for sort_monte_carlo_pr_dBm_all'
% all(sort_monte_carlo_pr_dBm_test==sort_monte_carlo_pr_dBm_all)
% 
% 'Check for similarities, the same'
% pause;

% 'size sort_monte_carlo_pr_dBm_all'
% size(sort_monte_carlo_pr_dBm_all)

%all(all(sort_monte_carlo_pr_dBm_all==sort_monte_carlo_pr_dBm_all2))



% -------------------------------------------------------------------------
% STEP 2: Precompute off-axis gain matrix once for all (bs,sim_azimuth)
% off_axis_gain_matrix dimensions: [num_bs x num_sim_azi]
% -------------------------------------------------------------------------
% % % [n_pat_rows,~]=size(custom_antenna_pattern);
% % % pat_az=mod(custom_antenna_pattern(:,1),360);
% % % pat_gain=custom_antenna_pattern(:,2);
% % %
% % % [pat_az_unique,ia_unique]=unique(pat_az,'stable');
% % % pat_gain_unique=pat_gain(ia_unique);
% % %
% % % off_axis_gain_matrix=NaN(num_bs,num_sim_azi);
% % % for azimuth_idx=1:1:num_sim_azi
% % %     sim_azimuth=array_sim_azimuth(azimuth_idx);
% % %     rel_az=mod(bs_azimuth-sim_azimuth,360);
% % %     ant_deg_idx=nearestpoint_app(app,rel_az,pat_az_unique);
% % %     off_axis_gain_matrix(:,azimuth_idx)=pat_gain_unique(ant_deg_idx);
% % % end
[off_axis_gain_matrix]=vector_off_axis_gain_rev1(app,custom_antenna_pattern,bs_azimuth,array_sim_azimuth);

% 'size off_axis_gain_matrix'
% size(off_axis_gain_matrix)

% -------------------------------------------------------------------------
% STEP 5: Move List across azimuth in vectorized chunks (no inner azimuth loop)
% -------------------------------------------------------------------------
%%%%%%%%%%%%%%%%azi_chunk=32;%128; %%%%%%%32 is faster than 128
%%%%%%%%%%%%%%No azimuth chunks.
for loop_idx=1:1:num_mc_idx  %%%%%%%%For each Monte Carlo
    base_mc=sort_monte_carlo_pr_dBm_all(:,loop_idx);
    % 'size base_mc'
    % size(base_mc)

    %%%%%%%%%%%%%Azimuth chunk for loop removed
    chunk_gain=off_axis_gain_matrix;
    sort_temp_mc_dBm=base_mc+chunk_gain;

    % 'size sort_temp_mc_dBm'
    % size(sort_temp_mc_dBm)

    if any(isnan(sort_temp_mc_dBm),'all')
        disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check: NaN Error: sort_temp_mc_dBm'))
        pause;
    end

    binary_sort_mc_watts=db2pow(sort_temp_mc_dBm)/1000;
    if any(isnan(binary_sort_mc_watts),'all')
        disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev8: NaN Error: temp_mc_watts'))
        pause;
    end


    [mid_primary]=pre_sort_binary_movelist_rev3_multi_azi_app(app,radar_threshold-move_list_margin,binary_sort_mc_watts);
    sub_array_ml_turnoff_mc(loop_idx,1)=mid_primary;

    %tf_second_data
    % % % if num_sim_azi==1
    % % %     'Need to check ML binary search for backwards capability to 1 azimuth'
    % % %     'Checked'
    % % %     pause;
    % % % end



    if tf_second_data==1
        %%%%Rerun binary
        %%%'start here with another binary with the radar2threshold'
        [mid_second]=pre_sort_binary_movelist_rev3_multi_azi_app(app,radar2threshold-move_list_margin,binary_sort_mc_watts);
        sub_array_ml_turnoff_mc_secondary(loop_idx,1)=mid_second;
        %horzcat(mid_primary,mid_second)
    end
end

%'end of subchunk function'