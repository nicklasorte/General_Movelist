function [maine_exception]=load_data_maine_exception(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: maine_exception . . . '))


        load('maine_exception.mat','maine_exception')
        temp_data=maine_exception;
        clear maine_exception;
        maine_exception=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end