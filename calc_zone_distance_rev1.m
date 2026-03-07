function zone_dist_km = calc_zone_distance_rev1(app, all_data_stats_binary, radar_threshold, margin)
%calc_zone_distance_rev1  Compute zone distance for each stats array.
%
%   zone_dist_km = calc_zone_distance_rev1(app, all_data_stats_binary, radar_threshold, margin)
%
%   If radar_threshold or margin are omitted or empty, use app properties.
%   Column 1 = distance (km)
%   Column 2 = radar metric

    arguments
        app
        all_data_stats_binary (1,:) cell
        radar_threshold (1,1) double {mustBeFinite} = missing
        margin (1,1) double {mustBeFinite, mustBeNonnegative} = missing
    end

    % Defaults from app (App Designer pattern)
    if ismissing(radar_threshold)
        radar_threshold = app.RadarThreshold;
    end
    if ismissing(margin)
        margin = app.Margin;
    end

    nPts = numel(all_data_stats_binary);
    zone_dist_km = NaN(nPts,1);

    thrAgg = radar_threshold + margin;

    for point_idx = 1:nPts
        S = all_data_stats_binary{point_idx};

        % Need at least columns 1 and 2
        if isempty(S) || size(S,2) < 2
            continue
        end

        % Replace NaNs with 0 (fast and clear)
        S(isnan(S)) = 0;  % alternative: S = fillmissing(S,"constant",0);  :contentReference[oaicite:0]{index=0}

        col2 = S(:,2);

        % If last value is still above radar_threshold → no valid crossing
        if col2(end) > radar_threshold
            continue
        end

        % If entirely above or entirely below the agg threshold → no crossing
        if all(col2 > thrAgg) || all(col2 < thrAgg)
            continue
        end

        % First point within agg margin (col2 <= thrAgg)
        idx_crossing = find(col2 <= thrAgg, 1, "first");

        % idx_crossing should exist given the checks above, but keep it robust:
        if ~isempty(idx_crossing)
            zone_dist_km(point_idx) = S(idx_crossing,1);
        end
    end
end