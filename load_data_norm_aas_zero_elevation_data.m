function [norm_aas_zero_elevation_data]=load_data_norm_aas_zero_elevation_data(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: norm_aas_zero_elevation_data . . . '))




        load('norm_aas_zero_elevation_data.mat','norm_aas_zero_elevation_data')
        %%%%1) Azimuth -180~~180
        %%%2) Rural
        %%%3) Suburban
        %%%4) Urban
        temp_data=norm_aas_zero_elevation_data;
        clear norm_aas_zero_elevation_data;
        norm_aas_zero_elevation_data=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end