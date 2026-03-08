function [sub_array_agg_check_mc_dBm]=subchunk_agg_check_rev7(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chuck_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)

%%%%%%%%%Adding clutter distribution in monte carlo later
%%%%%%%%%%We just have to make a new bs_eirp_dist based on the azimuth
%%%%%%%%%%of the base station antenna offset to the federal point.
array_aas_dist_data=cell_aas_dist_data{2};
aas_dist_azimuth=cell_aas_dist_data{1};
mod_azi_diff_bs=array_bs_azi_data(:,4);

%%%%%%%%%Find the azimuth off-axis antenna loss
[nn_azi_idx]=nearestpoint_app(app,mod_azi_diff_bs,aas_dist_azimuth); %%%%%%%Nearest Azimuth Idx

%%%%%%%%Now create a super_array_bs_eirp_dist
super_array_bs_eirp_dist=array_aas_dist_data(nn_azi_idx,:);

%%%%%%%%%%%%%%%%Calculate the simulation azimuths
[array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Each Base Station Azimuth
sim_pt=base_protection_pts(point_idx,:);
bs_azimuth=azimuth(sim_pt(1),sim_pt(2),on_list_bs(:,1),on_list_bs(:,2));
num_bs=length(bs_azimuth);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%Pre-compute off_axis_gain for every simulation azimuth [num_bs x num_sim_azi]
%%%%%This block is independent of MC data so it runs once, not once per chunk.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
all_off_axis_gain=NaN(num_bs,num_sim_azi);
[num_ele,~]=size(custom_antenna_pattern);

for azimuth_idx=1:1:num_sim_azi
    sim_azimuth=array_sim_azimuth(azimuth_idx);

    %%%%%%%%%%%%%Shift the antenna pattern
    circshift_antpat=custom_antenna_pattern;
    circshift_antpat(:,1)=mod(custom_antenna_pattern(:,1)+sim_azimuth,360);

    %%%%%%Now find the 0 and align
    nn_zero_azi_idx=nearestpoint_app(app,0,circshift_antpat(:,1));
    shift_antpat=circshift(circshift_antpat,num_ele-nn_zero_azi_idx+1);
    shift_antpat=table2array(unique(array2table(shift_antpat),'rows')); %%%%%%Only keep unique azimuth rows

    %%%%%%Test to make sure 0 is first in array
    nn_check_idx=nearestpoint_app(app,0,shift_antpat(:,1));
    if nn_check_idx~=1
        'Circ shift error'
        pause;
    end

    [ant_deg_idx]=nearestpoint_app(app,bs_azimuth,shift_antpat(:,1));
    all_off_axis_gain(:,azimuth_idx)=shift_antpat(ant_deg_idx,2);  %%%%[num_bs x 1] stored as column
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%Generate MC Iterations and Calculate Aggregate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sub_mc_idx=cell_sim_chuck_idx{sub_point_idx};
num_mc_idx=length(sub_mc_idx);
sub_array_agg_check_mc_dBm=NaN(num_mc_idx,num_sim_azi);

%%%%%%%Batch MC calls — each returns [num_bs x num_mc_idx]
[all_Pr_dBm]=monte_carlo_Pr_dBm_batch(app,rand_seed1,sub_mc_idx,agg_check_reliability,on_full_Pr_dBm);
[all_eirp]=monte_carlo_super_bs_eirp_dist_batch(app,super_array_bs_eirp_dist,rand_seed1,sub_mc_idx,agg_check_reliability);
[all_clutter]=monte_carlo_clutter_batch(app,rand_seed1,sub_mc_idx,agg_check_reliability,clutter_loss);

all_sort_mc_dBm=all_Pr_dBm+all_eirp-all_clutter;  %%%%[num_bs x num_mc_idx]

if any(isnan(all_sort_mc_dBm(:)))
    disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check: NaN Error: all_sort_mc_dBm'))
    pause;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%Azimuth loop — antenna work is gone, only math remains
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for azimuth_idx=1:1:num_sim_azi
    off_axis_gain=all_off_axis_gain(:,azimuth_idx);          %%%%[num_bs x 1]
    sort_temp=all_sort_mc_dBm+off_axis_gain;                  %%%%[num_bs x num_mc_idx] broadcast

    %%%%%%Sum across BSs (dim 1): /1000 and *1000 cancel, work directly in dBm-scale mW
    sub_array_agg_check_mc_dBm(:,azimuth_idx)=pow2db(sum(db2pow(sort_temp),1,"omitnan"))';  %%%%[num_mc_idx x 1]
end

%sub_array_agg_check_mc_dBm %%%This is what we save/output
end
