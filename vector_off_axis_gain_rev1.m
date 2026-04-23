function [off_axis_gain_matrix]=vector_off_axis_gain_rev1(app,custom_antenna_pattern,bs_azimuth,array_sim_azimuth)
% -------------------------------------------------------------------------
% STEP 2: Precompute off-axis gain matrix once for all (bs,sim_azimuth)
% off_axis_gain_matrix dimensions: [num_bs x num_sim_azi]
% Nearest-neighbor behavior mirrors rev7 path.
% -------------------------------------------------------------------------
[n_pat_rows,~]=size(custom_antenna_pattern);
pat_az=mod(custom_antenna_pattern(:,1),360);
pat_gain=custom_antenna_pattern(:,2);
num_bs=length(bs_azimuth);
num_sim_azi=length(array_sim_azimuth);

[pat_az_unique,ia_unique]=unique(pat_az,'stable');
pat_gain_unique=pat_gain(ia_unique);

off_axis_gain_matrix=NaN(num_bs,num_sim_azi);
for azimuth_idx=1:1:num_sim_azi
    sim_azimuth=array_sim_azimuth(azimuth_idx);
    rel_az=mod(bs_azimuth-sim_azimuth,360);
    ant_deg_idx=nearestpoint_app(app,rel_az,pat_az_unique);
    off_axis_gain_matrix(:,azimuth_idx)=pat_gain_unique(ant_deg_idx);
end