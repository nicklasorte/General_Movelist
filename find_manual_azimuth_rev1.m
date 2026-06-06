function [azimuth_step,tf_man_azi_step]=find_manual_azimuth_rev1(app,cell_sim_data,sim_folder)

%%%%%%%%%%%%%%%%%%%Check for manual azimuth
data_header=cell_sim_data(1,:)';
label_idx=find(matches(data_header,'data_label1'));
row_folder_idx=find(matches(cell_sim_data(:,label_idx),sim_folder));
col_azi_step_idx=find(matches(data_header,'azimuth_step'));
if ~isempty(col_azi_step_idx)
    azimuth_step=cell_sim_data{row_folder_idx,col_azi_step_idx};
    tf_man_azi_step=1;
else
    azimuth_step=NaN(1,1);
    tf_man_azi_step=0;
end
