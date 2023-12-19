function [array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth)



if radar_beamwidth==360
    array_sim_azimuth=0;
    num_sim_azi=length(array_sim_azimuth);
else

    half_bw=radar_beamwidth/2;
    array_sim_azimuth=min_azimuth:half_bw:max_azimuth;
    %%%%array_sim_azimuth=0:half_bw:360;
    idx360=find(array_sim_azimuth==360);
    if ~isempty(idx360)==1
        array_sim_azimuth(idx360)=[];
    end
    num_sim_azi=length(array_sim_azimuth);

    if any(isnan(array_sim_azimuth))
        'NaN Error: array_sim_azimuth'
        pause;
    end
end

end