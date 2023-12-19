function [min_binaray_spacing]=load_data_min_binaray_spacing(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: min_binaray_spacing . . . '))
        load('min_binaray_spacing.mat','min_binaray_spacing')
        temp_data=min_binaray_spacing;
        clear min_binaray_spacing;
        min_binaray_spacing=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end