function [agg_check_mc_percentile]=load_data_agg_check_mc_percentile(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: agg_check_mc_percentile . . . '))
        load('agg_check_mc_percentile.mat','agg_check_mc_percentile')
        temp_data=agg_check_mc_percentile;
        clear agg_check_mc_percentile;
        agg_check_mc_percentile=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end
