function [mc_percentile]=load_data_mc_percentile(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: mc_percentile . . . '))
        load('mc_percentile.mat','mc_percentile')
        temp_data=mc_percentile;
        clear mc_percentile;
        mc_percentile=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end
