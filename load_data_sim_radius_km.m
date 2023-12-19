function [sim_radius_km]=load_data_sim_radius_km(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: sim_radius_km . . . '))

  

        load('sim_radius_km.mat','sim_radius_km')
        temp_data=sim_radius_km;
        clear sim_radius_km;
        sim_radius_km=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end