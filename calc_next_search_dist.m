function [next_search_dist,tf_search,temp_catb_dist_data,array_searched_dist]=calc_next_search_dist(app,all_data_stats_binary,radar_threshold,margin,maine_exception,tf_full_binary_search,min_binaray_spacing)
               
temp_data1=all_data_stats_binary{1};  
array_searched_dist=temp_data1(:,1)

            %%%%%Process the Data
                x22=length(all_data_stats_binary);
                temp_catb_dist_data=NaN(x22,1);
                for point_idx=1:1:x22
                    full_stats_catb=all_data_stats_binary{point_idx};
                    
                    %%%%Replace NaNs with '0'
                    [x98,y98]=size(full_stats_catb);
                    for k=1:1:x98
                        idx_fill_nan=find(isnan(full_stats_catb(k,:))==1);
                        full_stats_catb(k,idx_fill_nan)=0;
                    end
                    
                    %%%%%Check if the last full_stats_catb is less than radar_threshold
                    if full_stats_catb(end,2)>radar_threshold
                        pseudo_threshold=full_stats_catb(end,2)+1;
                        temp_idx_fix=find(full_stats_catb(:,2)<pseudo_threshold);
                        full_stats_catb(temp_idx_fix,2)=radar_threshold;
                    end
                    
                    
                    if isempty(full_stats_catb)==0
                        %%%%Find the First Point within the agg margin (Original Algorithm)
                        tf_agg=full_stats_catb(:,2)>(radar_threshold+margin);
                        tf_agg2=full_stats_catb(:,2)<(radar_threshold+margin);
                        if all(tf_agg)==1 || all(tf_agg2)==1 %%%%%%This checks to see if all the points are above or below the radar threshold
                            temp_catb_dist_data(point_idx)=NaN(1);
                        else
                            idx_crossing=find(tf_agg==0,1,'first'); %%%%%Find the First Point within the agg margin
                            if isempty(idx_crossing)==1
                                [idx_crossing,~]=size(full_stats_catb);
                            end
                            temp_catb_dist_data(point_idx)=full_stats_catb(idx_crossing,1);
                            
                            %%%%%%%%%%%%Check for the plateau with a small move list
                            movelist_size=max(full_stats_catb(:,3));
                            idx_crossing_diff=NaN(1);
                            if movelist_size<maine_exception
                                agg_diff=-1*diff(full_stats_catb(1:idx_crossing-1,2));
                                sum_agg_diff=NaN(idx_crossing-2,1);
                                for j=1:1:(idx_crossing-2)
                                    sum_agg_diff(j)=sum(agg_diff(j:idx_crossing-2));
                                end
                                idx_crossing_diff=find(sum_agg_diff<margin,1,'first');
                                if isempty(idx_crossing_diff)==1
                                    temp_catb_dist_data(point_idx)=full_stats_catb(idx_crossing,1);
                                elseif idx_crossing_diff==1
                                    temp_catb_dist_data(point_idx)=NaN(1);
                                else
                                    temp_catb_dist_data(point_idx)=full_stats_catb(idx_crossing_diff,1);
                                end
                            end
                        end
                    end
                end
                
                %%%%%%%%Sort into Bins
count_binary_bins=histcounts(temp_catb_dist_data,array_searched_dist+1);


%%%%%%%%Find non zero bin counts and those are the next input distances
idx_nonzero=find(count_binary_bins~=0);

if tf_full_binary_search==1
sort_idx_dist=sort(idx_nonzero,'descend'); %%%%%%Descend Sort, will search the higher end first
end

if tf_full_binary_search==0
    sort_idx_dist=max(sort(idx_nonzero,'descend')); %%%%%%Only the Max
end

tf_dist_step=1;
dist_marker=1;
next_search_dist=NaN(1);
while(tf_dist_step==1 && dist_marker<=length(sort_idx_dist))
    %%%%%%%%Now Check the distance between sort_idx_dist
    temp_dist1=array_searched_dist(sort_idx_dist(dist_marker));
    temp_dist2=array_searched_dist(sort_idx_dist(dist_marker)+1);
    dist_diff=temp_dist2-temp_dist1;
    if dist_diff>min_binaray_spacing
        next_search_dist=round((temp_dist1+temp_dist2)/2);
        tf_dist_step=0;
    else
        dist_marker=dist_marker+1;
    end
end

if ~isnan(next_search_dist)==1
    tf_search=1; %%%%<--Flag for while loop
else
    tf_search=0;
end

end