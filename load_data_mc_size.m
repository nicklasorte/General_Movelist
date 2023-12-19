function [mc_size]=load_data_mc_size(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: mc_size . . . '))

        load('mc_size.mat','mc_size')
        temp_data=mc_size;
        clear mc_size;
        mc_size=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end