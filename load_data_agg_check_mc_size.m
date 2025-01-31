function [agg_check_mc_size]=load_data_agg_check_mc_size(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: agg_check_mc_size . . . '))
        load('agg_check_mc_size.mat','agg_check_mc_size')
        temp_data=agg_check_mc_size;
        clear agg_check_mc_size;
        agg_check_mc_size=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end
