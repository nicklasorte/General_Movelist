function plotSearchDistance_geoplot_GPT_rev1(app,base_protection_pts,sim_bound,search_dist_bound,on_list_bs,inside_idx,union_turn_off_list_data,single_search_dist,temp_max_agg,data_label1)
%%%%plotSearchDistanceGeoFigure  Plot search-distance geometry and save PNG.
%
% Designed for App Designer use (app passed in).
%
% Saves figure using saveWithRetry (exportgraphics-based).
    arguments
        app
        base_protection_pts (:,2) double
        sim_bound (:,2) double
        search_dist_bound (:,2) double = NaN(0,2)
        on_list_bs (:,2) double = NaN(0,2)
        inside_idx (:,1) double = NaN(0,1)
        union_turn_off_list_data (:,2) double = NaN(0,2)
        single_search_dist (1,1) double {mustBeFinite}
        temp_max_agg (1,1) double {mustBeFinite}
        data_label1 {mustBeTextScalar}
        %outPngFile {mustBeTextScalar} = ""
    end

    outPngFile=strcat('SearchDist_',data_label1,'_',num2str(single_search_dist),'km.png');
    %#ok<INUSD> % app reserved for future UIAxes support

    data_label1 = string(data_label1);

    if strlength(string(outPngFile)) == 0
        outPngFile = sprintf("SearchDist_%s_%gkm.png", data_label1, single_search_dist);
    end
    outPngFile = char(outPngFile);

    fig = figure("Color","w","Position",[100 100 1200 900]);
    hold on

    %% Federal System points
    geoplot(base_protection_pts(:,1), base_protection_pts(:,2), ...
        "xk", "LineWidth", 3, "DisplayName", "Federal System");

    %% Simulation boundary
    geoplot(sim_bound(:,1), sim_bound(:,2), ...
        "--", "Color", "b", "LineWidth", 3, ...
        "DisplayName", sprintf("%g km", single_search_dist));

    %% Search distance boundary (if applicable)
    if single_search_dist > 0 && ~isempty(search_dist_bound)
        geoplot(search_dist_bound(:,1), search_dist_bound(:,2), ...
            "-", "Color", [255/256 51/256 255/256], ...
            "LineWidth", 3, ...
            "DisplayName", sprintf("%g km", single_search_dist));
    end

    %% On-list base stations
    if ~isempty(on_list_bs)
        geoscatter(on_list_bs(:,1), on_list_bs(:,2), 10, "b", "filled");
    end

    %% Inside stations
    if single_search_dist > 0 && ~isempty(inside_idx)
        inside_idx = inside_idx(inside_idx >= 1 & inside_idx <= size(on_list_bs,1));
        if ~isempty(inside_idx)
            geoscatter(on_list_bs(inside_idx,1), ...
                       on_list_bs(inside_idx,2), ...
                       20, "g", "filled");
        end
    end

    %% Turn-off stations
    if ~isempty(union_turn_off_list_data)
        geoscatter(union_turn_off_list_data(:,1), ...
                   union_turn_off_list_data(:,2), ...
                   30, "r", "filled");
    end

    %% Styling
    title(sprintf("%g km -- Maximum Aggregate: %g", ...
          single_search_dist, temp_max_agg));
    grid on
    geobasemap streets-light

    %% Save
    saveWithRetry(outPngFile, fig);

    close(fig);
end