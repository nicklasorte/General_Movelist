function [reliability]=load_data_reliability(app)

retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: reliability . . . '))
        load('reliability.mat','reliability')
        temp_data=reliability;
        clear reliability;
        reliability=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end