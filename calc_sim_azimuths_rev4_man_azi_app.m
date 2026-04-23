function [array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev4_man_azi_app(app,radar_beamwidth,min_azimuth,max_azimuth,tf_man_azi_step,azimuth_step)

if radar_beamwidth==360
    array_sim_azimuth=0;
else
    if tf_man_azi_step==0
        half_bw=radar_beamwidth/2;
        array_sim_azimuth=min_azimuth:half_bw:max_azimuth;
        %%%%array_sim_azimuth=0:half_bw:360;
        idx360=find(array_sim_azimuth==360);
        if ~isempty(idx360)==1
            array_sim_azimuth(idx360)=[];
        end

        if any(isnan(array_sim_azimuth))
            'NaN Error: array_sim_azimuth'
            pause;
        end
    elseif tf_man_azi_step==1
        if min_azimuth==max_azimuth
            array_sim_azimuth=min_azimuth;
        else
            array_sim_azimuth=min_azimuth:azimuth_step:max_azimuth;
        end
    end
end
if isempty(array_sim_azimuth)
    'empty error array_sim_azimuth'
    pause;
end
num_sim_azi=length(array_sim_azimuth);