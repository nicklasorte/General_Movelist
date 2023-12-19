function [deployment_percentage]=load_data_deployment_percentage(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: deployment_percentage . . . '))
        load('deployment_percentage.mat','deployment_percentage')
        temp_data=deployment_percentage;
        clear deployment_percentage;
        deployment_percentage=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end