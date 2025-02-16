function [radar_ant_array]=horizontal_antenna_loss_app(app,radar_beamwidth,min_radar_loss)


       %%%%%%%%%%Add Radar Antenna Pattern: Offset from 0 degrees and loss in dB
        %[radar_ant_array]=radar_hor_ant_loss_app(app,radar_beamwidth,min_radar_loss);
        %radar_beamwidth
        %min_radar_loss
        
        %%%%%%%%%%%%%%Calculate Radar Rx Antenna Loss (dB) for 180 degrees
        tenth_bw=radar_beamwidth/10;
        azimuth_array_af=0:tenth_bw:180;
        idx180=find(azimuth_array_af==180);
        if ~isempty(idx180)==1
            azimuth_array_af(idx180)=[];
        end

        temp_ant_loss=-12*(azimuth_array_af./radar_beamwidth).^2;
        idx_below_min=find(temp_ant_loss<-1*min_radar_loss); %%%%%%Max Antenna Loss 25dBi
        temp_ant_loss(idx_below_min)=-1*min_radar_loss;
        %%idx_below_min

        %%%%%%%Now Find the Degrees/Ant Loss dB, with only one entry of the -25dB at the end
        temp_ant_loss=temp_ant_loss(1:idx_below_min(1))';
        ant_deg_idx=azimuth_array_af(1:idx_below_min(1))';
        radar_ant_array=horzcat(ant_deg_idx,temp_ant_loss); %%%Degress from center and dB loss

end