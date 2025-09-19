function [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data)


        %%%%%%%Take into consideration the sector/azimuth off-axis gain
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate Each Base Station Azimuth
        sim_pt=base_protection_pts(point_idx,:);
        bs2fed_azimuth=azimuth(sim_array_list_bs(:,1),sim_array_list_bs(:,2),sim_pt(1),sim_pt(2));  %%%%%Where 0 is North, clockwise.

% % %         %%%%%%%%%%Example azimuth calculation with visual
        % % f1=figure;
        % % geoplot(sim_pt(1),sim_pt(2),'or')
        % % hold on;
        % % geoplot(sim_array_list_bs(1,1),sim_array_list_bs(1,2),'sb')
        % % geobasemap streets-light%landcover
        % % bs2fed_azimuth(1)
 

        sector_azi=sim_array_list_bs(:,7);
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

        % rural_idx(1)

        bs_azi_gain(rural_idx)=norm_aas_zero_elevation_data(nn_azi_idx(rural_idx),2);
        bs_azi_gain(sub_idx)=norm_aas_zero_elevation_data(nn_azi_idx(sub_idx),3);
        bs_azi_gain(urban_idx)=norm_aas_zero_elevation_data(nn_azi_idx(urban_idx),4);

             array_bs_azi_data=horzcat(bs2fed_azimuth,sector_azi,azi_diff_bs,mod_azi_diff_bs,bs_azi_gain);  %%%%%%%%This is the data to save and export to the excel
             % 
             % nn_azi_idx(1)
             % array_bs_azi_data(1,:)
             % sim_array_list_bs(1,:)
end