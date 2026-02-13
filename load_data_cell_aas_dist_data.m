function [cell_aas_dist_data]=load_data_cell_aas_dist_data(app)

retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: cell_aas_dist_data . . . '))
        load('cell_aas_dist_data.mat','cell_aas_dist_data')
        temp_data=cell_aas_dist_data;
        clear cell_aas_dist_data;
        cell_aas_dist_data=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end

