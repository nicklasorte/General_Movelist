function [off_axis_loss]=calc_off_axix_loss_rev1_app(app,sim_azimuth,cbsd_azimuth,radar_ant_array,min_radar_loss)

num_tx=length(cbsd_azimuth);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
half_ant_hor_deg=max(radar_ant_array(:,1)); %%%%Maximum degree to which we apply a loss less than 25dB

%%%%%%%Calculate the loss due to off axis in the horizontal direction
%%%Find CBSD azimuths outside of +/- of half_ant_hor_deg of temp_azimuth
%%%%sim_azimuth=array_sim_azimuth(azimuth_idx);

%%%%%%%%%This is where the error might be
left_azimuth=mod(sim_azimuth-half_ant_hor_deg,360);
right_azimuth=mod(sim_azimuth+half_ant_hor_deg,360);
%%%%%%%%%horzcat(left_azimuth,temp_azimuth,right_azimuth)

%%%%%%%%Find the Azimuths to apply 25dB to outside
if left_azimuth>right_azimuth
    azi_outside_idx=find(cbsd_azimuth<left_azimuth & cbsd_azimuth>right_azimuth);
    azi_inside_idx=find(cbsd_azimuth>left_azimuth | cbsd_azimuth<right_azimuth);
else
    azi_outside_idx=find(cbsd_azimuth<left_azimuth | cbsd_azimuth>right_azimuth);
    azi_inside_idx=find(cbsd_azimuth>left_azimuth & cbsd_azimuth<right_azimuth);
end

if num_tx~=length(azi_outside_idx)+length(azi_inside_idx)
    'Error: Azimuth idx missing'
    horzcat(num_tx,length(azi_outside_idx)+length(azi_inside_idx))
    pause;
end

%%%%%Find Difference between temp_azimuth and CBSD azimuth to get the radar ant loss
normDeg = mod(sim_azimuth-cbsd_azimuth(azi_inside_idx),360);
absDiffDeg = min(360-normDeg, normDeg);
[ant_deg_idx]=nearestpoint_app(app,absDiffDeg,radar_ant_array(:,1));

%%%Add loss (25dB) for CBSDs outside the Radar beamwidth
off_axis_loss=min_radar_loss*ones(num_tx,1);
%%%Add partial loss for CBSDs outside the Radar beamwidth
temp_partial_loss=radar_ant_array(ant_deg_idx,2);
off_axis_loss(azi_inside_idx)=-1*temp_partial_loss;

if min(off_axis_loss)<0
    'Error Negative off axis loss'
    pause;
end

if max(off_axis_loss)>min_radar_loss
    'Error More Loss than min_radar_loss'
    pause;
end

if any(isnan(off_axis_loss))
    'Error NaN for off_axis_loss'
    pause;
end

end