function [all_data_stats_binary]=update_all_data_distance_rev1(app,all_data_stats_binary,single_search_dist,single_scrap_data)

%%%%Distance, Aggregate, Move List Size
for point_idx=1:1:length(all_data_stats_binary)
    temp_data=all_data_stats_binary{point_idx};
    new_temp_data=vertcat(temp_data,horzcat(single_search_dist,single_scrap_data(point_idx,:)));
    [uni_dist,uni_idx]=unique(new_temp_data(:,1));
    uni_new_temp_data=new_temp_data(uni_idx,:);

    %%%%Sort the Data
    [check_sort,sort_idx]=sort(uni_new_temp_data(:,1)); %%%%%%Sorting by Distance just in case
    all_data_stats_binary{point_idx}=uni_new_temp_data(sort_idx,:);
end
end