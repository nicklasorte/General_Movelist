function [Tpol]=load_data_Tpol(app)


retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: Tpol . . . '))
        load('Tpol.mat','Tpol')
        temp_data=Tpol;
        clear Tpol;
        Tpol=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end
