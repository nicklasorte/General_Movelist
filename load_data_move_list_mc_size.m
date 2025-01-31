function [move_list_mc_size]=load_data_move_list_mc_size(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: move_list_mc_size . . . '))
        load('move_list_mc_size.mat','move_list_mc_size')
        temp_data=move_list_mc_size;
        clear move_list_mc_size;
        move_list_mc_size=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end
