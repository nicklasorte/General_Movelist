function [cell_status]=initialize_or_load_neighborhood_data_rev1(app,folder_names,cell_status_filename)

  [num_folders,~]=size(folder_names);
    [var_exist_cell]=persistent_var_exist_with_corruption(app,cell_status_filename);
    if var_exist_cell==2 %%%%%%%%Load
        retry_load=1;
        while(retry_load==1)
            try
                load(cell_status_filename,'cell_status')
                retry_load=0;
            catch
                retry_load=1;
                pause(0.1)
            end
        end
        [temp_size,~]=size(cell_status);
        if temp_size>num_folders
            %%%%%%%%Nothing
        elseif temp_size<num_folders
            %%%%%Expand the cell
            disp_multifolder(app,'Pause for cell_status expansion')
            pause;
            var_exist_cell=0;
        end
    end
    
    if var_exist_cell==0 %%%%%%%%Initilize and Save
        [num_folders,~]=size(folder_names);
        cell_status=cell(num_folders,5); %%%% 1) Name and 2)0/1 3)Neighborhood Distnace 4)Move List Size  5)All Binary Data
        cell_status(:,1)=folder_names;
        zero_cell=cell(1);
        zero_cell{1}=0;
        cell_status(:,2)=zero_cell;
        %%%%%%Save the initialize all_data_stats_binary
        retry_save=1;
        while(retry_save==1)
            try
                save(cell_status_filename,'cell_status')
                retry_save=0;
            catch
                retry_save=1;
                pause(0.1)
            end
        end
    end


end