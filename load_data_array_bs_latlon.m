function [array_bs_latlon]=load_data_array_bs_latlon(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: array_bs_latlon . . . '))
           load('array_bs_latlon.mat','array_bs_latlon') %%%%%%%%%%%%%Nationwide: %%%%%%%1)Lat, 2)Lon, 3)Azimuth, 4)Height, 5)EIRP, 6)Mitigation EIRP
        temp_data=array_bs_latlon;
        clear array_bs_latlon;
        array_bs_latlon=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end