function [grid_spacing]=load_data_grid_spacing(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: grid_spacing . . . '))
        load('grid_spacing.mat','grid_spacing')
        temp_data=grid_spacing;
        clear grid_spacing;
        grid_spacing=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end