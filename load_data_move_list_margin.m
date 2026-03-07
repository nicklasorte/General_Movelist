function [move_list_margin]=load_data_move_list_margin(app)

retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: move_list_margin . . . '))
        load('move_list_margin.mat','move_list_margin')
        temp_data=move_list_margin;
        clear move_list_margin;
        move_list_margin=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end

