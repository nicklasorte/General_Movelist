function [all_data_stats_binary]=initialize_or_load_all_data_stats_binary_pre_label(app,data_label1,sim_number,rand_pts,pre_label)

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
    
    if var_exist_cell==0 %%%%%%%%Initilize and Save
        [x22,~]=size(rand_pts);
        all_data_stats_binary=cell(x22,1); %%%%Leave the Cell empty
%         full_stats_catb=NaN(1,3); %%%%Distance, Aggregate, Move List Size
%         for point_idx=1:1:x22
%             all_data_stats_binary{point_idx}=full_stats_catb;
%         end
        %%%%%%Save the initialize all_data_stats_binary
        retry_save=1;
        while(retry_save==1)
            try
                save(file_name_cell,'all_data_stats_binary')
                retry_save=0;
            catch
                retry_save=1;
                pause(0.1)
            end
        end
    end
end