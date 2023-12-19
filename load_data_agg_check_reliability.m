function [agg_check_reliability]=load_data_agg_check_reliability(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: agg_check_reliability . . . '))

        load('agg_check_reliability.mat','agg_check_reliability')
        temp_data=agg_check_reliability;
        clear agg_check_reliability;
        agg_check_reliability=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end


end