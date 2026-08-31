function [all_data_stats_binary]=load_all_data_stats_binary_pre_label(app,data_label1,sim_number,pre_label)

    file_name_cell=strcat(pre_label,'_',data_label1,'_',num2str(sim_number),'_all_data_stats_binary.mat');
    [var_exist_cell]=persistent_var_exist(app,file_name_cell);
    if var_exist_cell==2 %%%%%%%%Load
        retry_load=1;
        while(retry_load==1)
            try
                load(file_name_cell,'all_data_stats_binary')
                retry_load=0;
            catch
                retry_load=1;
                pause(0.1)
            end
        end
    end