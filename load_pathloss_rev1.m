function [pathloss]=load_pathloss_rev1(app,string_prop_model,point_idx,sim_number,data_label1)

        file_name_pathloss=strcat(string_prop_model,'_pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
        retry_load=1;
        while(retry_load==1)
            try
                load(file_name_pathloss,'pathloss')
                retry_load=0;
            catch
                retry_load=1;
                pause(1)
            end
        end