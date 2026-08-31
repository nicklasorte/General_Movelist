function [tf_second_data]=find_tf_second_in_rev1(app,cell_sim_data,sim_folder)


%%%%%Need the secondary, if they are there
data_header=cell_sim_data(1,:)';
label_idx=find(matches(data_header,'data_label1'));
in2_idx=find(matches(data_header,'second_in_ratio'));
if ~isempty(in2_idx)
    row_folder_idx=find(matches(cell_sim_data(:,label_idx),sim_folder));
    in_ratio2=cell_sim_data{row_folder_idx,in2_idx};
else
    in_ratio2=NaN(1,1);
end
in_ratio2
if ~isnan(in_ratio2)
    tf_second_data=1;
else
    tf_second_data=0;
end
tf_second_data

end