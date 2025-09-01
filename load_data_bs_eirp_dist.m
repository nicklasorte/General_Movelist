function [bs_eirp_dist]=load_data_bs_eirp_dist(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: bs_eirp_dist . . . '))
           load('bs_eirp_dist.mat','bs_eirp_dist') %%%%%%%%%%%%%Nationwide: %%%%%%%1)Lat, 2)Lon, 3)Azimuth, 4)Height, 5)EIRP, 6)Mitigation EIRP
        temp_data=bs_eirp_dist;
        clear bs_eirp_dist;
        bs_eirp_dist=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end