function [thresh]=get_dpa_thresholds_from_cell_sim_data_rev1(cell_sim_data,sim_folder)
%%%%%%%%Extract primary + secondary DPA thresholds, percentiles and
%%%%%%%%I/N ratios out of cell_sim_data for the row matching sim_folder.
%%%%%%%%Returns NaN for fields that are not present so callers can rely
%%%%%%%%on a uniform struct shape.
%%%%%%%%
%%%%%%%%Output struct fields:
%%%%%%%%  radar_threshold       : primary dpa_threshold
%%%%%%%%  radar2threshold       : secondary dpa_second_threshold (NaN if absent)
%%%%%%%%  in_ratio1             : primary in_ratio (NaN if absent)
%%%%%%%%  in_ratio2             : secondary second_in_ratio (NaN if absent)
%%%%%%%%  mc_per2               : secondary second_mc_percentile (NaN if absent)
%%%%%%%%  tf_second_data_thresh : 1 if radar2threshold present (move-list path)
%%%%%%%%  tf_second_data_in     : 1 if in_ratio2 present (agg-check path)

data_header=cell_sim_data(1,:)';
label_idx=find(matches(data_header,'data_label1'));
row_folder_idx=find(matches(cell_sim_data(:,label_idx),sim_folder));

threshold_idx=find(matches(data_header,'dpa_threshold'));
if ~isempty(threshold_idx)
    thresh.radar_threshold=cell_sim_data{row_folder_idx,threshold_idx};
else
    thresh.radar_threshold=NaN(1,1);
end

dpa2thres_idx=find(matches(data_header,'dpa_second_threshold'));
if ~isempty(dpa2thres_idx)
    thresh.radar2threshold=cell_sim_data{row_folder_idx,dpa2thres_idx};
else
    thresh.radar2threshold=NaN(1,1);
end

in1_idx=find(matches(data_header,'in_ratio'));
if ~isempty(in1_idx)
    thresh.in_ratio1=cell_sim_data{row_folder_idx,in1_idx};
else
    thresh.in_ratio1=NaN(1,1);
end

in2_idx=find(matches(data_header,'second_in_ratio'));
if ~isempty(in2_idx)
    thresh.in_ratio2=cell_sim_data{row_folder_idx,in2_idx};
else
    thresh.in_ratio2=NaN(1,1);
end

per2_idx=find(matches(data_header,'second_mc_percentile'));
if ~isempty(per2_idx)
    thresh.mc_per2=cell_sim_data{row_folder_idx,per2_idx};
else
    thresh.mc_per2=NaN(1,1);
end

thresh.tf_second_data_thresh=double(~isnan(thresh.radar2threshold));
thresh.tf_second_data_in=double(~isnan(thresh.in_ratio2));
end
