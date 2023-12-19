function [building_loss]=load_data_building_loss(app)


retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: building_loss . . . '))
        load('building_loss.mat','building_loss')
        temp_data=building_loss;
        clear building_loss;
        building_loss=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end