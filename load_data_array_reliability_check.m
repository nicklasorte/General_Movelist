function [array_reliability_check]=load_data_array_reliability_check(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: array_reliability_check . . . '))
        load('array_reliability_check.mat','array_reliability_check')
        temp_data=array_reliability_check;
        clear array_reliability_check;
        array_reliability_check=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end