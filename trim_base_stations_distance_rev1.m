function [sim_array_list_bs,keep_idx]=trim_base_stations_distance_rev1(app,base_protection_pts,point_idx,sim_array_list_bs,single_search_dist)

%%%%'Cut the base stations and pathloss to be only within the search distance'
sim_pt=base_protection_pts(point_idx,:);
bs_distance=deg2km(distance(sim_pt(1),sim_pt(2),sim_array_list_bs(:,1),sim_array_list_bs(:,2)));
keep_idx=find(bs_distance<=single_search_dist);
horzcat(length(bs_distance),length(keep_idx))
size(sim_array_list_bs)
sim_array_list_bs=sim_array_list_bs(keep_idx,:);
size(sim_array_list_bs)
end