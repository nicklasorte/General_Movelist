function [move_list_mc_percentile]=load_data_move_list_mc_percentile(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: move_list_mc_percentile . . . '))
        load('move_list_mc_percentile.mat','move_list_mc_percentile')
        temp_data=move_list_mc_percentile;
        clear move_list_mc_percentile;
        move_list_mc_percentile=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end
