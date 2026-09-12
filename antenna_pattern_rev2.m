function [radar_ant_array]=antenna_pattern_rev2(app,ant_beamwidth,ant_gain,min_ant_loss)
%%%%%%%%%%%%%%Calculate Simple Rx Antenna Loss (dB) for 180 degrees
tenth_bw=ant_beamwidth/10;
azimuth_array_af=0:tenth_bw:180;
idx180=find(azimuth_array_af==180);
if ~isempty(idx180)==1
    azimuth_array_af(idx180)=[];
end

temp_ant_loss=(-12*(azimuth_array_af./ant_beamwidth).^2)+ant_gain;
%idx_below_min=find(temp_ant_loss<-1*min_ant_loss); %%%%%%Max Antenna Loss 25dBi
%temp_ant_loss(idx_below_min)=-1*min_ant_loss;
idx_below_min=find(temp_ant_loss<(ant_gain-min_ant_loss)); %%%%%%Max Antenna Loss 25dBi
temp_ant_loss(idx_below_min)=(ant_gain-min_ant_loss);
%%idx_below_min

%%%%%%%Now Find the Degrees/Ant Loss dB, with only one entry of the -25dB at the end
%idx_below_min
if isempty(idx_below_min)
    temp_ant_loss=temp_ant_loss';
    ant_deg_idx=azimuth_array_af';
else
    temp_ant_loss=temp_ant_loss(1:idx_below_min(1))';
    ant_deg_idx=azimuth_array_af(1:idx_below_min(1))';
end

radar_ant_array=horzcat(ant_deg_idx,temp_ant_loss); %%%Degress from center and dB loss
end