function [sub_array_agg_check_mc_dBm]=subchunk_agg_check_maxazi_rev12(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx,varargin)
%SUBCHUNK_AGG_CHECK_MAXAZI_REV12
% Carefully scoped rev12 optimization over rev11:
%   1) preserve one-time RNG seeding and pre-generated MC random matrices;
%   2) preserve AZI chunking and allow optional AZI_CHUNK override via varargin{1};
%   3) reduce off-axis matrix build overhead with one vectorized nearest-neighbor pass;
%   4) reduce aggregation temporary allocation pressure via direct mW accumulation.
%
% Output contract is unchanged: max aggregate dBm over simulation azimuth for each MC.

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

nn_azi_idx=nearestpoint_app(app,mod_azi_diff_bs,aas_dist_azimuth);
super_array_bs_eirp_dist=array_aas_dist_data(nn_azi_idx,:);

[array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth);

sim_pt=base_protection_pts(point_idx,:);
bs_azimuth=azimuth(sim_pt(1),sim_pt(2),on_list_bs(:,1),on_list_bs(:,2));

sub_mc_idx=cell_sim_chunk_idx{sub_point_idx}; %#ok<NASGU>
num_mc_idx=length(sub_mc_idx);
num_bs=length(bs_azimuth);
sub_array_agg_check_mc_dBm=NaN(num_mc_idx,1);

% -------------------------------------------------------------------------
% STEP 1: one-time RNG and pre-generated random matrices.
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
% STEP 2: off-axis gain matrix construction (vectorized nearest-neighbor).
% Semantics are preserved via nearestpoint_app lookup against unique pattern azimuths.
% -------------------------------------------------------------------------
pat_az=mod(custom_antenna_pattern(:,1),360);
pat_gain=custom_antenna_pattern(:,2);
[pat_az_unique,ia_unique]=unique(pat_az,'stable');
pat_gain_unique=pat_gain(ia_unique);

rel_az_matrix=mod(bs_azimuth-array_sim_azimuth,360);
ant_deg_idx_flat=nearestpoint_app(app,rel_az_matrix(:),pat_az_unique);
off_axis_gain_matrix=reshape(pat_gain_unique(ant_deg_idx_flat),num_bs,num_sim_azi);

if DEBUG_CHECKS
    if any(~isfinite(off_axis_gain_matrix),'all')
        error('subchunk_agg_check_maxazi_rev12:OffAxisNotFinite', ...
            'off_axis_gain_matrix contains non-finite values.');
    end
end

% -------------------------------------------------------------------------
% STEP 3: RNG-free MC pathloss terms for each MC realization.
% -------------------------------------------------------------------------
sort_monte_carlo_pr_dBm_all=NaN(num_bs,num_mc_idx);
for loop_idx=1:1:num_mc_idx
    pre_sort_monte_carlo_pr_dBm=monte_carlo_Pr_dBm_rev2_app(app,agg_check_reliability,on_full_Pr_dBm,rand_pr_all(:,loop_idx));
    rand_norm_eirp=monte_carlo_super_bs_eirp_dist_rev5(app,super_array_bs_eirp_dist,agg_check_reliability,rand_eirp_all(:,loop_idx));
    monte_carlo_clutter_loss=monte_carlo_clutter_rev3_app(app,agg_check_reliability,clutter_loss,rand_clutter_all(:,loop_idx));

    sort_monte_carlo_pr_dBm_all(:,loop_idx)=pre_sort_monte_carlo_pr_dBm+rand_norm_eirp-monte_carlo_clutter_loss;
end

% -------------------------------------------------------------------------
% STEP 4: chunked azimuth aggregation in linear mW domain.
% max-over-azimuth is tracked in linear domain and converted once per MC.
% -------------------------------------------------------------------------
for loop_idx=1:1:num_mc_idx
    base_mc=sort_monte_carlo_pr_dBm_all(:,loop_idx);
    max_azi_agg_mw=0;

    for azi_start=1:azi_chunk:num_sim_azi
        azi_end=min(azi_start+azi_chunk-1,num_sim_azi);
        chunk_gain=off_axis_gain_matrix(:,azi_start:azi_end);

        if DEBUG_CHECKS
            if any(isnan(chunk_gain),'all') || any(isnan(base_mc),'all')
                error('subchunk_agg_check_maxazi_rev12:NaNInputs','NaN detected before aggregation.');
            end
        end

        chunk_agg_mw=sum(10.^((base_mc+chunk_gain)./10),1,'omitnan');
        chunk_max_mw=max(chunk_agg_mw,[],'omitnan');

        if chunk_max_mw>max_azi_agg_mw
            max_azi_agg_mw=chunk_max_mw;
        end
    end

    sub_array_agg_check_mc_dBm(loop_idx,1)=10.*log10(max(max_azi_agg_mw,realmin('double')));
end

end
