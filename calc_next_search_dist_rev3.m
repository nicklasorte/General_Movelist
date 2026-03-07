function [next_search_dist, tf_search, temp_catb_dist_data, array_searched_dist]=calc_next_search_dist_rev3(app,all_data_stats_binary,radar_threshold,margin,tf_full_binary_search,min_binaray_spacing)
%calc_next_search_dist  Choose next search distance using zone-distance crossings.
%
%   Reuses calc_zone_distance_rev1(app, all_data_stats_binary, radar_threshold, margin).
%
%   Outputs:
%     next_search_dist        midpoint of the selected interval (NaN if none)
%     tf_search               true if next_search_dist is valid
%     temp_catb_dist_data     per-point zone distance (same as calc_zone_distance_rev1 output)
%     array_searched_dist     distance grid taken from the first cell (col 1)

    arguments
        app
        all_data_stats_binary (1,:) cell
        radar_threshold (1,1) double {mustBeFinite} = missing
        margin (1,1) double {mustBeFinite, mustBeNonnegative} = missing
        tf_full_binary_search (1,1) logical = true
        min_binaray_spacing (1,1) double {mustBeFinite, mustBeNonnegative} = 0
    end

    % % Defaults from app if not supplied
    % if ismissing(radar_threshold), radar_threshold = app.RadarThreshold; end
    % if ismissing(margin),          margin          = app.Margin;          end

    % Pull searched distance grid from first cell
    if isempty(all_data_stats_binary) || isempty(all_data_stats_binary{1}) || size(all_data_stats_binary{1},2) < 1
        array_searched_dist = [];
        temp_catb_dist_data = NaN(0,1);
        next_search_dist = NaN;
        tf_search = false;
        return
    end

    array_searched_dist = all_data_stats_binary{1}(:,1);

    % ---- Reuse your zone-distance function here ----
    temp_catb_dist_data = calc_zone_distance_rev1(app, all_data_stats_binary, radar_threshold, margin);

    % ---- Bin and select next search distance ----
    next_search_dist = NaN;
    tf_search = false;

    if numel(array_searched_dist) < 2
        return
    end

    validD = temp_catb_dist_data(~isnan(temp_catb_dist_data));
    if isempty(validD)
        return
    end

    % Keep your original behavior: use array_searched_dist+1 as edges
    count_binary_bins = histcounts(validD, array_searched_dist + 1);

    idx_nonzero = find(count_binary_bins ~= 0);
    if isempty(idx_nonzero)
        return
    end

    if tf_full_binary_search
        candidate_bins = sort(idx_nonzero, "descend");
    else
        candidate_bins = max(idx_nonzero);
    end

    % Find first candidate with sufficient spacing
    for k = 1:numel(candidate_bins)
        b = candidate_bins(k);

        if b+1 > numel(array_searched_dist)
            continue
        end

        d1 = array_searched_dist(b);
        d2 = array_searched_dist(b+1);

        if (d2 - d1) > min_binaray_spacing
            next_search_dist = round((d1 + d2)/2);
            tf_search = true;
            break
        end
    end
end