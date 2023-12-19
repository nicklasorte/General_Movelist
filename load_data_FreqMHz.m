function [FreqMHz]=load_data_FreqMHz(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: FreqMHz . . . '))
        load('FreqMHz.mat','FreqMHz')
        temp_data=FreqMHz;
        clear FreqMHz;
        FreqMHz=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end