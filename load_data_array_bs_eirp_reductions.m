function [array_bs_eirp_reductions]=load_data_array_bs_eirp_reductions(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: array_bs_eirp_reductions . . . '))


        load('array_bs_eirp_reductions.mat','array_bs_eirp_reductions') %%%%%Rural, Suburban, Urban cols:(1-3), No Mitigations/Mitigations rows:(1-2)
        temp_data=array_bs_eirp_reductions;
        clear array_bs_eirp_reductions;
        array_bs_eirp_reductions=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end