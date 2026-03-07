function [sub_array_agg_check_mc_dBm]=subchunk_agg_check_rev7(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chuck_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)

%%%%%%%%%Adding clutter distribution in monte carlo later
%%%%%%%%%%We just have to make a new bs_eirp_dist based on the azimuth
%%%%%%%%%%of the base station antenna offset to the federal point.
array_aas_dist_data=cell_aas_dist_data{2};
aas_dist_azimuth=cell_aas_dist_data{1};
mod_azi_diff_bs=array_bs_azi_data(:,4);
% min(mod_azi_diff_bs)
% max(mod_azi_diff_bs)
%%%%%%%%%Find the azimuth off-axis antenna loss
[nn_azi_idx]=nearestpoint_app(app,mod_azi_diff_bs,aas_dist_azimuth); %%%%%%%Nearest Azimuth Idx
% size(nn_azi_idx)
% size(on_full_Pr_dBm)

%%%%%%%%Now create a super_array_bs_eirp_dist with array_aas_dist_data which will be used in the same way as bs_eirp_dist
% % % num_rows=length(nn_azi_idx)
% % % [~,num_int_col]=size(array_aas_dist_data);
% % % super_array_bs_eirp_dist=NaN(num_rows,num_int_col);
% % % size(super_array_bs_eirp_dist)
% % % for k=1:1:num_rows
% % %     super_array_bs_eirp_dist(k,:)=array_aas_dist_data(nn_azi_idx(k),:);
% % % end
super_array_bs_eirp_dist=array_aas_dist_data(nn_azi_idx, :);
%size(super_array_bs_eirp_dist)

%%%%%%%%%%%%%%%%Calculate the simualation azimuths
[array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Each Base Station Azimuth
sim_pt=base_protection_pts(point_idx,:);
bs_azimuth=azimuth(sim_pt(1),sim_pt(2),on_list_bs(:,1),on_list_bs(:,2));

%%%%%%%%%%%%%%Generate MC Iterations and Calculate Move List
%%%Preallocate
sub_mc_idx=cell_sim_chuck_idx{sub_point_idx}
num_mc_idx=length(sub_mc_idx)
sub_array_agg_check_mc_dBm=NaN(num_mc_idx,num_sim_azi);
for loop_idx=1:1:num_mc_idx
    loop_idx
    mc_iter=sub_mc_idx(loop_idx)

    %%%%%%%Generate 1 MC Iteration
    [pre_sort_monte_carlo_pr_dBm]=monte_carlo_Pr_dBm_rev1_app(app,rand_seed1,mc_iter,agg_check_reliability,on_full_Pr_dBm);
    %%%%%[rand_norm_eirp]=monte_carlo_super_bs_eirp_dist_rev3(app,super_array_bs_eirp_dist,rand_seed1,mc_iter,num_tx,agg_check_reliability);
    [rand_norm_eirp]=monte_carlo_super_bs_eirp_dist_rev4(app,super_array_bs_eirp_dist,rand_seed1,mc_iter,agg_check_reliability); %%%%Don't need the num_tx
    [monte_carlo_clutter_loss]=monte_carlo_clutter_rev1_app(app,rand_seed1,mc_iter,agg_check_reliability,clutter_loss);
    sort_monte_carlo_pr_dBm=pre_sort_monte_carlo_pr_dBm+rand_norm_eirp-monte_carlo_clutter_loss;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Aggregate for Single MC Iteration
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%Preallocate
    azimuth_agg_dBm=NaN(num_sim_azi,1);
    for azimuth_idx=1:1:num_sim_azi
        %%%Find CBSD azimuths outside of +/- of half_ant_hor_deg of temp_azimuth
        sim_azimuth=array_sim_azimuth(azimuth_idx);

        %%%%%%%%%%%%%Shift the antenna pattern
        circshift_antpat=custom_antenna_pattern;
        circshift_antpat(:,1)=custom_antenna_pattern(:,1)+sim_azimuth; %%%%%%%Add the azimuth, then we don't have to worry about azimuth spacing on pattern
        %%%%Then Mod
        mod_ant_pat=mod(circshift_antpat(:,1),360);
        circshift_antpat(:,1)=mod_ant_pat;

        %%%%%%Now find the 0
        nn_zero_azi_idx=nearestpoint_app(app,0,circshift_antpat(:,1));
        [num_ele,~]=size(circshift_antpat);
        shift_antpat=circshift(circshift_antpat,num_ele-nn_zero_azi_idx+1);
        shift_antpat=table2array(unique(array2table(shift_antpat),'rows')); %%%%%%Only keep unique azimuth rows

        %%%%%%Test to make sure 0 is first in array
        nn_check_idx=nearestpoint_app(app,0,shift_antpat(:,1));
        if nn_check_idx~=1
            'Circ shift error'
            pause;
        end

        %%%%%%%Calculate the loss due to off axis in the horizontal direction
        %%%%[off_axis_loss]=calc_off_axix_loss_rev1_app(app,sim_azimuth,bs_azimuth,radar_ant_array,min_ant_loss);
        %%%%%%%%%%%%%%%%%%%%%%%Since we've already rotated the antenna pattern, just need to find the nearest bs_azimuth
        [ant_deg_idx]=nearestpoint_app(app,bs_azimuth,shift_antpat(:,1));
        off_axis_gain=shift_antpat(ant_deg_idx,2);
        sort_temp_mc_dBm=sort_monte_carlo_pr_dBm+off_axis_gain;

        if any(isnan(sort_temp_mc_dBm))  %%%%%%%%Check
            disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check: NaN Error: sort_temp_mc_dBm'))
            pause;
        end

        %%%%%%Convert to Watts, Sum, and Find Aggregate
        %%%pow2db(0.1*1000)=20, 0.1 Watts = 20dBm
        %%%db2pow(20)/1000=0.1, 20dBm = 0.1 Watts
        binary_sort_mc_watts=db2pow(sort_temp_mc_dBm)/1000; %%%%%%

        if any(isnan(binary_sort_mc_watts))
            disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev1: Line 168: NaN Error: temp_mc_watts'))
            pause;
        end

        mc_agg_dbm=pow2db(sum(binary_sort_mc_watts,"omitnan")*1000);
        azimuth_agg_dBm(azimuth_idx)=mc_agg_dbm;
    end
    sub_array_agg_check_mc_dBm(loop_idx,:)=azimuth_agg_dBm; %%%%%%%%%%%max across all azimuths for a single MC iteration
end

%sub_array_agg_check_mc_dBm %%%This is what we save/output
end