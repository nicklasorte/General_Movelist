function [mitigation_dB]=load_data_mitigation_dB(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: mitigation_dB . . . '))

        load('mitigation_dB.mat','mitigation_dB')
        temp_data=mitigation_dB;
        clear mitigation_dB;
        mitigation_dB=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end


end