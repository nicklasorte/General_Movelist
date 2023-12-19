function [cell_status]=update_generic_status_cell_rev1(app,folder_names,sim_folder,cell_status_filename)

        %%%%%%%Load
        [cell_status]=initialize_or_load_generic_status_rev1(app,folder_names,cell_status_filename)
        
        %%%%%Find the idx
        temp_cell_idx=find(strcmp(cell_status(:,1),sim_folder)==1);

        %%%%%%%Update the Cell
        cell_status{temp_cell_idx,2}=1;
        
        %%%%%Save the Cell
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