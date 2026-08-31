function [tf_second_data,zero_dB]=secondary_in_data_rev2(app,cell_sim_data,sim_folder)           

%%%%%%%%%%Find the secondary I/N and Percentiles and the

            data_header=cell_sim_data(1,:)';
            in1_idx=find(matches(data_header,'in_ratio'));
            label_idx=find(matches(data_header,'data_label1'));
            row_folder_idx=find(matches(cell_sim_data(:,label_idx),sim_folder));
            in_ratio1=cell_sim_data{row_folder_idx,in1_idx};

            %%%%%Need the secondary, if they are there
            in2_idx=find(matches(data_header,'second_in_ratio'));
            per2_idx=find(matches(data_header,'second_mc_percentile'));

            threshold_idx=find(matches(data_header,'dpa_threshold'));
            radar_threshold=cell_sim_data{row_folder_idx,threshold_idx};
            %%%%%%%%%%This is the zero dB shift.
            zero_dB=in_ratio1-radar_threshold;

            if ~isempty(in2_idx)
                in_ratio2=cell_sim_data{row_folder_idx,in2_idx};
            else
                in_ratio2=NaN(1,1);
            end
            if ~isempty(in_ratio2)%~isempty(per2_idx)
                per2=cell_sim_data{row_folder_idx,per2_idx};
            else
                per2=NaN(1,1);
                per_second_in=NaN(1,1);
            end
            
            if ~isnan(in_ratio2)
                tf_second_data=1;
            else
                tf_second_data=0;
            end
            