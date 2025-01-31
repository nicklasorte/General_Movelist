function wrapper_scrap_agg_data_rev1(app,rev_folder,sim_number,folder_names,tf_server_status,string_prop_model,agg_check_reliability,agg_check_mc_size,agg_check_mc_percentile)

location_table=table([1:1:length(folder_names)]',folder_names)
server_status_rev2(app,tf_server_status)
num_folders=length(folder_names);

cell_aggregate_data=cell(num_folders,2);%%%1) DPA Name, 2)Max Interference Over
for folder_idx=1:1:num_folders
    retry_cd=1;
    while(retry_cd==1)
        try
            cd(rev_folder)
            pause(0.1);
            retry_cd=0;
        catch
            retry_cd=1;
            pause(0.1)
        end
    end
    retry_cd=1;
    while(retry_cd==1)
        try
            sim_folder=folder_names{folder_idx};
            cd(sim_folder)
            pause(0.1);
            retry_cd=0;
        catch
            retry_cd=1;
            pause(0.1)
        end
    end
    data_label1=sim_folder;
    file_name_max_miti_agg=strcat(string_prop_model,'_',data_label1,'_max_miti_aggregate_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(sim_number),'_',num2str(agg_check_mc_size),'_',num2str(agg_check_mc_percentile),'.mat');
    [file_max_agg_exist]=persistent_var_exist_with_corruption(app,file_name_max_miti_agg);

    if file_max_agg_exist==2
        retry_load=1;
        while(retry_load==1)
            try
                load(file_name_max_miti_agg,'max_miti_aggregate')
                pause(0.1);
                retry_load=0;
            catch
                retry_load=1;
                pause(0.1)
            end
        end

        max_miti_aggregate

        cell_aggregate_data{folder_idx,1}=data_label1;
        cell_aggregate_data{folder_idx,2}=max_miti_aggregate(1,2);

    end
    retry_cd=1;
    while(retry_cd==1)
        try
            cd(rev_folder)
            pause(0.1);
            retry_cd=0;
        catch
            retry_cd=1;
            pause(0.1)
        end
    end
end

%%%%%%%%%%%%'Now write an excel table'
%%%%%%%%Keep the Same Order as the Raw GMF
table_data=cell2table(cell_aggregate_data);
table_data.Properties.VariableNames={'DPA_Name' 'Max_Over_Interference_dB'}
writetable(table_data,strcat('Overview_data_',num2str(sim_number),'.xlsx'));
pause(0.1)
server_status_rev2(app,tf_server_status)

end