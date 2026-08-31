function scrap_aggregate_0km_rev1(app,sim_number,string_prop_model,reliability,tf_rescrap_rev_data,tf_server_status,rev_folder,cell_sim_data)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%Part 2b 0km data scrap

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Scrap Data for table.
filename_cell_0km_data=strcat('cell_0km_aggregate_',string_prop_model,'_',num2str(sim_number),'_',num2str(min(reliability)),'%.mat')
if tf_rescrap_rev_data==0
    %'check if all the files are there, if not, then set tf_rescrap_rev_data==0, else load'
    [var_exist1]=persistent_var_exist_with_corruption(app,filename_cell_0km_data);
    if var_exist1~=2
        tf_rescrap_rev_data=1;
    end
end

if tf_rescrap_rev_data==1
    server_status_rev2(app,tf_server_status)
    [sim_number,folder_names,num_folders]=check_rev_folders(app,rev_folder);
    array_rand_folder_idx=1:1:num_folders;

    cell_0km_aggregate=cell(num_folders,3);  %%%%1)Name, 2)First I/N, 3)Second I/N  
    for folder_idx=1:1:num_folders
        %%%%%%%%%%Calculate
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
                sim_folder=folder_names{array_rand_folder_idx(folder_idx)}
                cd(sim_folder)
                pause(0.1);
                retry_cd=0;
            catch
                retry_cd=1;
                pause(0.1)
            end
        end
        data_label1=sim_folder;

        %%%%%%%'Need to know if there is a second I/N data'
        [tf_second_data,zero_dB]=secondary_in_data_rev2(app,cell_sim_data,sim_folder);    

        %%%%%%%%Loading the aggregate data.
        %%%%%%%%Distribute single_scrap_data to all_data_stats_binary
        CBSD_label='BaseStation';
        [all_data_stats_binary]=load_all_data_stats_binary_pre_label(app,data_label1,sim_number,CBSD_label);
        %%%%%%%Find the zero row
        [x1,y1]=size(all_data_stats_binary);
        if x1>1 || y1>1
            'More than 1 row'
            pause;
        end
        temp_data1=all_data_stats_binary{:};
        zero_row_idx=find(temp_data1(:,1)==0);
        cell_0km_aggregate{folder_idx,1}=sim_folder;
        cell_0km_aggregate{folder_idx,2}=temp_data1(zero_row_idx,2)+zero_dB;

        if tf_second_data==1
            [all_secondary_stats_binary]=load_secondary_data_stats_binary_pre_label(app,data_label1,sim_number,'secondary');
            [x1,y1]=size(all_secondary_stats_binary);
            if x1>1 || y1>1
                'More than 1 row'
                pause;
            end
            temp_data2=all_secondary_stats_binary{:};
            zero2_row_idx=find(temp_data2(:,1)==0);
            if isnan(temp_data2(zero2_row_idx,2))
                % temp_data1
                % temp_data2
                % temp_data2(zero2_row_idx,2)
                % %pause;
                cell_0km_aggregate{folder_idx,2}=NaN(1,1);
                cell_0km_aggregate{folder_idx,3}=NaN(1,1);
            else
                cell_0km_aggregate{folder_idx,3}=temp_data2(zero2_row_idx,2)+zero_dB;
            end
            
        end
        cell_0km_aggregate
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
    %%%%%%%Remove empty cells
    cell_0km_aggregate=cell_0km_aggregate(~cellfun('isempty',cell_0km_aggregate(:,1)),:);


    %%%%%Save 1
    retry_save=1;
    while(retry_save==1)
        try
            save(filename_cell_0km_data,'cell_0km_aggregate')
            pause(0.1)
            retry_save=0;
        catch
            retry_save=1
            pause(1)
        end
    end


    %%%%%Need the secondary, if they are there
    data_header=cell_sim_data(1,:)';
    per1_idx=find(matches(data_header,'mc_percentile'));
    first_per=cell_sim_data{2,per1_idx};
    if tf_second_data==1
        per2_idx=find(matches(data_header,'second_mc_percentile'));
        second_per=cell_sim_data{2,per2_idx};
    else
        second_per=NaN(1,1);
    end

    %%%%%%%%%%%'Now write an excel table'
    %%%%%%%%All the population for each mitigation.
    table_in_data=cell2table(cell_0km_aggregate);
    table_in_data.Properties.VariableNames={'Location', strcat('First_Percentile:',num2str(first_per)),strcat('Second_Percentile:',num2str(second_per))}
    writetable(table_in_data,strcat('Aggregate_0km_',num2str(sim_number),'_',num2str(min(reliability)),'%.xlsx'))
end

end