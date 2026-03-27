function [sub_array_agg_check_mc_dBm]=subchunk_agg_check_maxazi_rev10(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
%SUBCHUNK_AGG_CHECK_MAXAZI_REV10 Regression-safe speedup revision.
% rev10 intentionally preserves strict per-iteration RNG behavior from rev9.
% rev10 removes azimuth chunking (when memory is safe) and optimizes aggregation
% without changing random stream semantics.
% rev11 can target RNG/pre-generation/vectorization changes after rev10 validation.

DEBUG_CHECKS=false;

%%%%%%%%%Adding clutter distribution in monte carlo later
%%%%%%%%%%We just have to make a new bs_eirp_dist based on the azimuth
%%%%%%%%%%of the base station antenna offset to the federal point.
array_aas_dist_data=cell_aas_dist_data{2};
aas_dist_azimuth=cell_aas_dist_data{1};
mod_azi_diff_bs=array_bs_azi_data(:,4);

%%%%%%%%%Find the azimuth off-axis antenna loss
[nn_azi_idx]=nearestpoint_app(app,mod_azi_diff_bs,aas_dist_azimuth); %%%%%%%Nearest Azimuth Idx
super_array_bs_eirp_dist=array_aas_dist_data(nn_azi_idx, :);

%%%%%%%%%%%%%%%%Calculate the simualation azimuths
[array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Each Base Station Azimuth
sim_pt=base_protection_pts(point_idx,:);
bs_azimuth=azimuth(sim_pt(1),sim_pt(2),on_list_bs(:,1),on_list_bs(:,2));

%%%%%%%%%%%%%%Generate MC Iterations and Calculate Move List
sub_mc_idx=cell_sim_chunk_idx{sub_point_idx};
num_mc_idx=length(sub_mc_idx);
num_bs=length(bs_azimuth);
sub_array_agg_check_mc_dBm=NaN(num_mc_idx,1);

% -------------------------------------------------------------------------
% STEP 1: Deterministic MC random precompute (seed identity preserved).
% rand_*_all dimensions: [num_bs x num_mc_idx]
% -------------------------------------------------------------------------
rel_min=min(agg_check_reliability);
rel_max=max(agg_check_reliability);

if rel_min==rel_max
    rand_pr_all=repmat(rel_min,num_bs,num_mc_idx);
    rand_eirp_all=rand_pr_all;
    rand_clutter_all=rand_pr_all;
else
    rand_pr_all=NaN(num_bs,num_mc_idx);
    rand_eirp_all=NaN(num_bs,num_mc_idx);
    rand_clutter_all=NaN(num_bs,num_mc_idx);

    for loop_idx=1:1:num_mc_idx
        mc_iter=sub_mc_idx(loop_idx);

        rng(rand_seed1+mc_iter); % PR draw identity
        rand_pr_all(:,loop_idx)=rand(num_bs,1)*(rel_max-rel_min)+rel_min;

        rng(rand_seed1+mc_iter+1); % EIRP draw identity
        rand_eirp_all(:,loop_idx)=rand(num_bs,1)*(rel_max-rel_min)+rel_min;

        rng(rand_seed1+mc_iter+2); % Clutter draw identity
        rand_clutter_all(:,loop_idx)=rand(num_bs,1)*(rel_max-rel_min)+rel_min;
    end
end

% -------------------------------------------------------------------------
% STEP 2: Precompute off-axis gain matrix once for all (bs,sim_azimuth).
% off_axis_gain_matrix dimensions: [num_bs x num_sim_azi]
% Nearest-neighbor behavior mirrors rev9 path.
% -------------------------------------------------------------------------
pat_az=mod(custom_antenna_pattern(:,1),360);
pat_gain=custom_antenna_pattern(:,2);

[pat_az_unique,ia_unique]=unique(pat_az,'stable');
pat_gain_unique=pat_gain(ia_unique);

off_axis_gain_matrix=NaN(num_bs,num_sim_azi);
for azimuth_idx=1:1:num_sim_azi
    sim_azimuth=array_sim_azimuth(azimuth_idx);
    rel_az=mod(bs_azimuth-sim_azimuth,360);
    ant_deg_idx=nearestpoint_app(app,rel_az,pat_az_unique);
    off_axis_gain_matrix(:,azimuth_idx)=pat_gain_unique(ant_deg_idx);
end

if DEBUG_CHECKS && any(isnan(off_axis_gain_matrix),'all')
    error('Inside Agg Check Rev10: NaN Error: off_axis_gain_matrix');
end

% -------------------------------------------------------------------------
% STEP 3/4: Compute MC terms with RNG-free rev helpers.
% -------------------------------------------------------------------------
sort_monte_carlo_pr_dBm_all=NaN(num_bs,num_mc_idx);
for loop_idx=1:1:num_mc_idx
    pre_sort_monte_carlo_pr_dBm=monte_carlo_Pr_dBm_rev2_app(app,agg_check_reliability,on_full_Pr_dBm,rand_pr_all(:,loop_idx));
    rand_norm_eirp=monte_carlo_super_bs_eirp_dist_rev5(app,super_array_bs_eirp_dist,agg_check_reliability,rand_eirp_all(:,loop_idx));
    monte_carlo_clutter_loss=monte_carlo_clutter_rev3_app(app,agg_check_reliability,clutter_loss,rand_clutter_all(:,loop_idx));

    sort_monte_carlo_pr_dBm_all(:,loop_idx)=pre_sort_monte_carlo_pr_dBm+rand_norm_eirp-monte_carlo_clutter_loss;
end

% -------------------------------------------------------------------------
% STEP 5: Aggregate across full azimuth set in one pass (no azi_chunk loop).
% Keep MC loop for deterministic RNG/regression safety.
% -------------------------------------------------------------------------
for loop_idx=1:1:num_mc_idx
    base_mc=sort_monte_carlo_pr_dBm_all(:,loop_idx);
    sort_temp_mc_dBm=base_mc+off_axis_gain_matrix;

    if DEBUG_CHECKS && any(isnan(sort_temp_mc_dBm),'all')
        error('Inside Agg Check Rev10: NaN Error: sort_temp_mc_dBm');
    end

    % Keep numeric path equivalent to rev9 while removing chunk overhead.
    binary_sort_mc_watts=db2pow(sort_temp_mc_dBm)/1000;

    if DEBUG_CHECKS && any(isnan(binary_sort_mc_watts),'all')
        error('Inside Agg Check Rev10: NaN Error: binary_sort_mc_watts');
    end

    agg_dBm=pow2db(sum(binary_sort_mc_watts,1,"omitnan")*1000);
    sub_array_agg_check_mc_dBm(loop_idx,1)=max(agg_dBm);
end

%%%%%%%%%%We can max azimuths -->sub_array_agg_check_mc_dBm=NaN(num_mc_idx,num_sim_azi);

end
