function [move_list_reliability]=load_data_move_list_reliability(app)

retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: move_list_reliability . . . '))
        load('move_list_reliability.mat','move_list_reliability')
        temp_data=move_list_reliability;
        clear move_list_reliability;
        move_list_reliability=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end
