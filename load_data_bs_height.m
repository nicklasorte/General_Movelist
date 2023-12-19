function [bs_height]=load_data_bs_height(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: bs_height . . . '))
        load('bs_height.mat','bs_height')
        temp_data=bs_height;
        clear bs_height;
        bs_height=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end