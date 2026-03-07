function catb_dist_data = calculate_neighborhood_dist_rev1(app,all_data_stats_binary,radar_threshold,margin)

% Number of points
numPoints = numel(all_data_stats_binary);

% Preallocate
catb_dist_data = NaN(numPoints,1);

for point_idx = 1:numPoints

    full_stats_catb = all_data_stats_binary{point_idx};

    % Skip empty cells
    if isempty(full_stats_catb)
        continue
    end

    % Replace NaNs with 0 (vectorized)
    full_stats_catb(isnan(full_stats_catb)) = 0;

    % Adjust values relative to radar threshold
    if full_stats_catb(end,2) > radar_threshold
        pseudo_threshold = full_stats_catb(end,2) + 1;
        idx = full_stats_catb(:,2) < pseudo_threshold;
        full_stats_catb(idx,2) = radar_threshold;
    end

    % Determine threshold crossing
    agg_limit = radar_threshold + margin;

    tf_above = full_stats_catb(:,2) > agg_limit;
    tf_below = full_stats_catb(:,2) < agg_limit;

    % If all points are above or below threshold, return NaN
    if all(tf_above) || all(tf_below)
        catb_dist_data(point_idx) = NaN;
        continue
    end

    % First point within aggregation margin
    idx_crossing = find(~tf_above,1,'first');

    if isempty(idx_crossing)
        idx_crossing = size(full_stats_catb,1);
    end

    % Distance value
    catb_dist_data(point_idx) = full_stats_catb(idx_crossing,1);

end

end


% % % % function [catb_dist_data]=calculate_neighborhood_dist_rev1(app,all_data_stats_binary,radar_threshold,margin,maine_exception)
% % % % 
% % % % 
% % % % %Process the Data and Find the CatB Distances
% % % % %%%%%Process the Data
% % % % x22=length(all_data_stats_binary);
% % % % catb_dist_data=NaN(x22,1);
% % % % for point_idx=1:1:x22
% % % %     full_stats_catb=all_data_stats_binary{point_idx};
% % % % 
% % % %     %%%%Replace NaNs with '0'
% % % %     [x98,y98]=size(full_stats_catb);
% % % %     for k=1:1:x98
% % % %         idx_fill_nan=find(isnan(full_stats_catb(k,:))==1);
% % % %         full_stats_catb(k,idx_fill_nan)=0;
% % % %     end
% % % % 
% % % %     %%%%%Check if the last full_stats_catb is less than radar_threshold
% % % %     if full_stats_catb(end,2)>radar_threshold
% % % %         pseudo_threshold=full_stats_catb(end,2)+1;
% % % %         temp_idx_fix=find(full_stats_catb(:,2)<pseudo_threshold);
% % % %         full_stats_catb(temp_idx_fix,2)=radar_threshold;
% % % %     end
% % % % 
% % % %     if isempty(full_stats_catb)==0
% % % %         %%%%Find the First Point within the agg margin (Original Algorithm)
% % % %         tf_agg=full_stats_catb(:,2)>(radar_threshold+margin);
% % % %         tf_agg2=full_stats_catb(:,2)<(radar_threshold+margin);
% % % %         if all(tf_agg)==1 || all(tf_agg2)==1 %%%%%%This checks to see if all the points are above or below the radar threshold
% % % %             catb_dist_data(point_idx)=NaN(1);
% % % %         else
% % % %             idx_crossing=find(tf_agg==0,1,'first'); %%%%%Find the First Point within the agg margin
% % % %             if isempty(idx_crossing)==1
% % % %                 [idx_crossing,~]=size(full_stats_catb);
% % % %             end
% % % %             catb_dist_data(point_idx)=full_stats_catb(idx_crossing,1);
% % % % 
% % % %             %%%%%%%%%%%%Check for the plateau with a small move list
% % % %             movelist_size=max(full_stats_catb(:,3));
% % % %             idx_crossing_diff=NaN(1);
% % % %             if movelist_size<maine_exception
% % % %                 agg_diff=-1*diff(full_stats_catb(1:idx_crossing-1,2));
% % % %                 sum_agg_diff=NaN(idx_crossing-2,1);
% % % %                 for j=1:1:(idx_crossing-2)
% % % %                     sum_agg_diff(j)=sum(agg_diff(j:idx_crossing-2));
% % % %                 end
% % % %                 idx_crossing_diff=find(sum_agg_diff<margin,1,'first');
% % % %                 if isempty(idx_crossing_diff)==1
% % % %                     catb_dist_data(point_idx)=full_stats_catb(idx_crossing,1);
% % % %                 elseif idx_crossing_diff==1
% % % %                     catb_dist_data(point_idx)=NaN(1);
% % % %                 else
% % % %                     catb_dist_data(point_idx)=full_stats_catb(idx_crossing_diff,1);
% % % %                 end
% % % %             end
% % % %         end
% % % %     end
% % % % end
% % % % 
% % % % end