function [sub_array_agg_check_mc_dBm]=subchunk_agg_check_maxazi_rev15(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx,varargin)
%SUBCHUNK_AGG_CHECK_MAXAZI_REV15 Monte Carlo aggregate check (rev14-compatible).
% Focused rev15 pass: target the next measured dominant bottleneck by
% replacing monte_carlo_clutter_rev3_app with monte_carlo_clutter_rev4_app.
% Intentionally preserve rev14 RNG/chunking/EIRP-helper behavior.

% Tuning knob: larger chunks can improve compute throughput but may increase peak memory.
AZI_CHUNK_DEFAULT=128;
DEBUG_CHECKS=false;
azi_chunk=AZI_CHUNK_DEFAULT;
if ~isempty(varargin)
    azi_chunk=varargin{1};
end
azi_chunk=max(1,round(azi_chunk));

array_aas_dist_data=cell_aas_dist_data{2};
aas_dist_azimuth=cell_aas_dist_data{1};
mod_azi_diff_bs=array_bs_azi_data(:,4);

% Off-axis EIRP lookup at BS-relative azimuth.
nn_azi_idx=nearestpoint_app(app,mod_azi_diff_bs,aas_dist_azimuth);
super_array_bs_eirp_dist=array_aas_dist_data(nn_azi_idx,:);

% Simulation azimuth grid.
[array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth);

% BS->point azimuths.
sim_pt=base_protection_pts(point_idx,:);
bs_azimuth=azimuth(sim_pt(1),sim_pt(2),on_list_bs(:,1),on_list_bs(:,2));

% MC iteration indices for this sub-point.
sub_mc_idx=cell_sim_chunk_idx{sub_point_idx}; %#ok<NASGU>
num_mc_idx=length(sub_mc_idx);
num_bs=length(bs_azimuth);
sub_array_agg_check_mc_dBm=NaN(num_mc_idx,1);

% -------------------------------------------------------------------------
% STEP 1: MC random pre-generation using a single RNG seeding call.
% Draw in [rel_min, rel_max] for PR, EIRP, clutter random reliabilities.
% -------------------------------------------------------------------------
rel_min=min(agg_check_reliability);
rel_max=max(agg_check_reliability);

if rel_min==rel_max
    rand_pr_all=repmat(rel_min,num_bs,num_mc_idx);
    rand_eirp_all=rand_pr_all;
    rand_clutter_all=rand_pr_all;
else
    rng(rand_seed1);
    rel_span=(rel_max-rel_min);
    rand_pr_all=rel_min+rel_span.*rand(num_bs,num_mc_idx);
    rand_eirp_all=rel_min+rel_span.*rand(num_bs,num_mc_idx);
    rand_clutter_all=rel_min+rel_span.*rand(num_bs,num_mc_idx);
end

% -------------------------------------------------------------------------
% STEP 2: Precompute off-axis gain matrix once for all (bs,sim_azimuth).
% Keep nearestpoint semantics stable.
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

% -------------------------------------------------------------------------
% STEP 3: RNG-free MC pathloss terms for each MC realization.
% -------------------------------------------------------------------------
sort_monte_carlo_pr_dBm_all=NaN(num_bs,num_mc_idx);
for loop_idx=1:1:num_mc_idx
    pre_sort_monte_carlo_pr_dBm=monte_carlo_Pr_dBm_rev2_app(app,agg_check_reliability,on_full_Pr_dBm,rand_pr_all(:,loop_idx));
    rand_norm_eirp=monte_carlo_super_bs_eirp_dist_rev6(app,super_array_bs_eirp_dist,agg_check_reliability,rand_eirp_all(:,loop_idx));
    monte_carlo_clutter_loss=monte_carlo_clutter_rev4_app(app,agg_check_reliability,clutter_loss,rand_clutter_all(:,loop_idx));

    sort_monte_carlo_pr_dBm_all(:,loop_idx)=pre_sort_monte_carlo_pr_dBm+rand_norm_eirp-monte_carlo_clutter_loss;
end

% -------------------------------------------------------------------------
% STEP 4: Aggregate over BS in watts, convert back to dBm, then max over az.
% -------------------------------------------------------------------------
for loop_idx=1:1:num_mc_idx
    base_mc=sort_monte_carlo_pr_dBm_all(:,loop_idx);
    max_azi_agg=-Inf;

    for azi_start=1:azi_chunk:num_sim_azi
        azi_end=min(azi_start+azi_chunk-1,num_sim_azi);
        chunk_gain=off_axis_gain_matrix(:,azi_start:azi_end);
        sort_temp_mc_dBm=base_mc+chunk_gain;

        if DEBUG_CHECKS
            if any(isnan(sort_temp_mc_dBm),'all')
                error('subchunk_agg_check_maxazi_rev15:NaNTempDbm','NaN detected in sort_temp_mc_dBm');
            end
        end

        binary_sort_mc_watts=db2pow(sort_temp_mc_dBm)/1000;
        if DEBUG_CHECKS
            if any(isnan(binary_sort_mc_watts),'all')
                error('subchunk_agg_check_maxazi_rev15:NaNWatt','NaN detected in binary_sort_mc_watts');
            end
        end

        azimuth_agg_dBm_chunk=pow2db(sum(binary_sort_mc_watts,1,'omitnan')*1000);
        chunk_max=max(azimuth_agg_dBm_chunk,[],'omitnan');
        if chunk_max>max_azi_agg
            max_azi_agg=chunk_max;
        end
    end

    sub_array_agg_check_mc_dBm(loop_idx,1)=max_azi_agg;
end

end
