function [temp_Pr_watts_azi]=vector_pr_watts_azi_rev1(app,sim_array_list_bs,non_sort_bs_azimuth,temp_pr_dbm,custom_antenna_pattern,array_sim_azimuth)
% -------------------------------------------------------------------------
% Vectorized replacement for the per-azimuth loop that builds
% temp_Pr_watts_azi (num_tx x num_sim_azi).
%
% Original loop, for each sim_azimuth:
%   1) Add sim_azimuth to the pattern azimuths and mod 360
%   2) circshift so 0 is first, dedupe rows
%   3) Nearest-neighbor lookup of every bs_azimuth in the shifted pattern
%   4) off_axis_gain = pattern gain at that index
%   5) temp_Pr_watts(:,j) = db2pow(temp_pr_dbm + off_axis_gain) / 1000
%
% Equivalent vectorized form:
%   For every (tx, sim_azi) the relative pattern angle is
%       rel_az(i,j) = mod(bs_az(i) - sim_az(j), 360).
%   Look that up once in the modded pattern and reshape.
% -------------------------------------------------------------------------
[num_tx,~]=size(sim_array_list_bs);
num_sim_azi=length(array_sim_azimuth);

%%%Normalize antenna pattern azimuths to [0,360) and dedupe by azimuth
pat_az=mod(custom_antenna_pattern(:,1),360);
pat_gain=custom_antenna_pattern(:,2);
[pat_az_unique,ia_unique]=unique(pat_az,'stable');
pat_gain_unique=pat_gain(ia_unique);

%%%Relative pattern angle for every (tx, sim_azi) pair
rel_az_matrix=mod(non_sort_bs_azimuth(:)-array_sim_azimuth(:).',360);

%%%Single nearest-neighbor lookup against the modded pattern
ant_deg_idx=nearestpoint_app(app,rel_az_matrix(:),pat_az_unique);
off_axis_gain_matrix=reshape(pat_gain_unique(ant_deg_idx),num_tx,num_sim_azi);

%%%dBm -> Watts (db2pow(20)/1000 = 0.1 W)
temp_Pr_dBm_azi=temp_pr_dbm(:)+off_axis_gain_matrix;
temp_Pr_watts_azi=db2pow(temp_Pr_dBm_azi)/1000;
end
