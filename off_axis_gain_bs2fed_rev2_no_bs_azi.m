function [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev2_no_bs_azi(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data)


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

if all(isnan(sector_azi))
    bs_azi_gain=NaN(size(sector_azi));
    bs_azi_gain(:)=0;
    azi_diff_bs=sector_azi;
    mod_azi_diff_bs=azi_diff_bs;
else
    azi_diff_bs=bs2fed_azimuth-sector_azi;
    mod_azi_diff_bs=mod(azi_diff_bs+180,360)-180;  %%%%%%%%%%Keep everything within the range of -180 ~ 180

    %%%%%%%%%Find the azimuth off-axis antenna loss
    [nn_azi_idx]=nearestpoint_app(app,mod_azi_diff_bs,norm_aas_zero_elevation_data(:,1)); %%%%%%%Nearest Azimuth Idx
    %%%horzcat(mod_azi_diff_bs,norm_aas_zero_elevation_data(nn_azi_idx,1))
    % % %         %%%%1) Azimuth -180~~180
    % % %         %%%2) Rural
    % % %         %%%3) Suburban
    % % %         %%%4) Urban

    bs_azi_gain=NaN(size(bs2fed_azimuth));
    rural_idx=find(sim_array_list_bs(:,6)==1);
    sub_idx=find(sim_array_list_bs(:,6)==2);
    urban_idx=find(sim_array_list_bs(:,6)==3);

    bs_azi_gain(rural_idx)=norm_aas_zero_elevation_data(nn_azi_idx(rural_idx),2);
    bs_azi_gain(sub_idx)=norm_aas_zero_elevation_data(nn_azi_idx(sub_idx),3);
    bs_azi_gain(urban_idx)=norm_aas_zero_elevation_data(nn_azi_idx(urban_idx),4);

end
array_bs_azi_data=horzcat(bs2fed_azimuth,sector_azi,azi_diff_bs,mod_azi_diff_bs,bs_azi_gain);  %%%%%%%%This is the data to save and export to the excel

end