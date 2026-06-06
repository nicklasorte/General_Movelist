function [clutter_loss]=load_p2108_clutter_rev1(app,point_idx,sim_number,data_label1)       

file_name_clutter=strcat('P2108_clutter_loss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
        retry_load=1;
        while(retry_load==1)
            try
                load(file_name_clutter,'clutter_loss')
                retry_load=0;
            catch
                retry_load=1;
                pause(1)
            end
        end