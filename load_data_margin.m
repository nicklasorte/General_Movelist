function [margin]=load_data_margin(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: margin . . . '))



        load('margin.mat','margin')
        temp_data=margin;
        clear margin;
        margin=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end