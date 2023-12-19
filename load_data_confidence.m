function [confidence]=load_data_confidence(app)

retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: confidence . . . '))
        load('confidence.mat','confidence')
        temp_data=confidence;
        clear confidence;
        confidence=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end