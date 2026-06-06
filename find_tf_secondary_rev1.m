function [tf_second_data,radar2threshold,mc_per2]=find_tf_secondary_rev1(app,cell_sim_data,sim_folder)

%%%%%%%%%%Find the secondary DPA Threshold and Percentiles,
%%%%%%%%%%if so then another all_data_stats_binary
data_header=cell_sim_data(1,:)';
label_idx=find(matches(data_header,'data_label1'));
row_folder_idx=find(matches(cell_sim_data(:,label_idx),sim_folder));

%%%%%Need the secondary, if they are there
dpa2thres_idx=find(matches(data_header,'dpa_second_threshold'));
per2_idx=find(matches(data_header,'second_mc_percentile'));

if ~isempty(dpa2thres_idx)
    radar2threshold=cell_sim_data{row_folder_idx,dpa2thres_idx};
else
    radar2threshold=NaN(1,1);
end

% % % %%%%%%%%%Might need to change this to:
 % % % in2_idx=find(matches(data_header,'second_in_ratio'));
% % % if ~isempty(in2_idx)
% % %     in_ratio2=cell_sim_data{row_folder_idx,in2_idx};
% % % else
% % %     in_ratio2=NaN(1,1);
% % % end
% % % if ~isempty(in_ratio2)

if ~isempty(per2_idx)
    mc_per2=cell_sim_data{row_folder_idx,per2_idx};
else
    mc_per2=NaN(1,1);
end
radar2threshold
mc_per2

if ~isnan(radar2threshold)
    tf_second_data=1;
else
    tf_second_data=0;
end
tf_second_data
end


