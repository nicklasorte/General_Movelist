function [array_bs_eirp]=load_data_array_bs_eirp(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: array_bs_eirp . . . '))
            load('array_bs_eirp.mat','array_bs_eirp')
        temp_data=array_bs_eirp;
        clear array_bs_eirp;
        array_bs_eirp=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end