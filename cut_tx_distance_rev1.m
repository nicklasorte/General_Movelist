function [keep_idx]=cut_tx_distance_rev1(app,base_protection_pts,point_idx,sim_array_list_bs,single_search_dist)


if isempty(point_idx) || isnan(point_idx)
    'Error on point_idx'
    point_idx
    pause;
end

if isempty(sim_array_list_bs) %|| all(isnan(sim_array_list_bs))
    'Error on sim_array_list_bs'
    sim_array_list_bs
end

if isempty(single_search_dist) || isnan(single_search_dist)
    'Error on single_search_dist'
    single_search_dist
    pause;
end

if isempty(base_protection_pts) || all(isnan(base_protection_pts))
    'Error on base_protection_pts'
    base_protection_pts
    pause;
end


        %%%%'Cut the base stations and pathloss to be only within the search distance'
        %disp_progress(app,strcat('Inside Pre_sort_ML rev8 Line75: Cutting Base Stations'))
        sim_pt=base_protection_pts(point_idx,:);
        bs_distance=deg2km(distance(sim_pt(1),sim_pt(2),sim_array_list_bs(:,1),sim_array_list_bs(:,2)));
        keep_idx=find(bs_distance<=single_search_dist);
        %'length of bs_distance and keep_idx'
        %horzcat(length(bs_distance),length(keep_idx))

        if isempty(keep_idx)
            'Error: keep_idx in cut_tx_distance_rev1'
            pause;
        end