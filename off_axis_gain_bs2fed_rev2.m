function [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev2(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data)


%%%%%%%Take into consideration the sector/azimuth off-axis gain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Each Base Station Azimuth
sim_pt=base_protection_pts(point_idx,:);
bs2fed_azimuth=azimuth(sim_array_list_bs(:,1),sim_array_list_bs(:,2),sim_pt(1),sim_pt(2));  %%%%%Where 0 is North, clockwise.

% % %         %%%%%%%%%%Example azimuth calculation with visual
% % %         close all;
% % %         figure;
% % %         hold on;
% % %         plot(sim_pt(2),sim_pt(1),'or')
% % %         plot(sim_array_list_bs(1,2),sim_array_list_bs(1,1),'sb')
% % %         bs2fed_azimuth(1)
% % %         grid on;
% % %         plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com

sector_azi=sim_array_list_bs(:,7);
azi_diff_bs=bs2fed_azimuth-sector_azi;
mod_azi_diff_bs=mod(azi_diff_bs+180,360)-180;  %%%%%%%%%%Keep everything within the range of -180 ~ 180

if length(unique(norm_aas_zero_elevation_data(:,2)))>1
    'Will need to 4 nearest points and Bilinear Interp'
    pause;
end

%%%%%%%%%Find the azimuth off-axis antenna loss
[nn_azi_idx]=nearestpoint_app(app,mod_azi_diff_bs,norm_aas_zero_elevation_data(:,1)); %%%%%%%Nearest Azimuth Idx
%%%horzcat(mod_azi_diff_bs,norm_aas_zero_elevation_data(nn_azi_idx,1))
% % %         %%%%1) Azimuth -180~~180
% % %         %%%2) Elevation
% % %         %%%3) First Base Station EIRP
% % %         %%%4) Second Base Station EIRP

[~,num_cols]=size(norm_aas_zero_elevation_data)
if num_cols>3
    'Need to add logic for that here'
    pause;
end

bs_azi_gain=NaN(size(bs2fed_azimuth));
first_idx=find(sim_array_list_bs(:,6)==1);
bs_azi_gain(first_idx)=norm_aas_zero_elevation_data(nn_azi_idx(first_idx),3);

array_bs_azi_data=horzcat(bs2fed_azimuth,sector_azi,azi_diff_bs,mod_azi_diff_bs,bs_azi_gain);  %%%%%%%%This is the data to save and export to the excel

end