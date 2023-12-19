function [mitigation]=load_data_mitigation(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: mitigation . . . '))

        load('mitigation.mat','mitigation')
        temp_data=mitigation;
        clear mitigation;
        mitigation=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end


end