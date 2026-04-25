function [keep_idx,bs_distance]=cut_bs_by_search_distance_rev1(base_protection_pts,point_idx,sim_array_list_bs,single_search_dist)
%%%%%%%%Compute great-circle distance from a protection point to each base
%%%%%%%%station and return the indices that fall within single_search_dist (km).

sim_pt=base_protection_pts(point_idx,:);
bs_distance=deg2km(distance(sim_pt(1),sim_pt(2),sim_array_list_bs(:,1),sim_array_list_bs(:,2)));
keep_idx=find(bs_distance<=single_search_dist);
end
