function single_mod_plateau_alg_rev7_geoplot_name(app, data_label1, sim_number, radar_threshold, margin,CBSD_label, base_polygon, base_protection_pts, tf_catb)
%single_mod_plateau_alg_rev7_geoplot_name
%
% Refactored:
%   - Reuses calc_zone_distance_rev1()
%   - No maine_exception logic
%   - Subfunctions save plots using saveWithRetry (exportgraphics)
%   - Saves MAT outputs using saveWithRetry (save -struct)
%
% REQUIREMENTS:
%   - loadWithRetry(filename, vars) exists
%   - normalizeCBSDLabel(labelIn) exists
%   - calc_zone_distance_rev1(app, all_data_stats_binary, radar_threshold, margin) exists
%   - computeNeighborhoodBound(app, base_polygon, catb_dist_data) exists
%   - plotDistanceHeatmap(..., pngFile) etc. exist (updated signatures below)
%   - saveWithRetry supports:
%         saveWithRetry("file.mat", struct("var",value))
%         saveWithRetry("plot.png", figHandle)

    arguments
        app
        data_label1 (1,:) char
        sim_number (1,1) double {mustBeFinite}
        radar_threshold (1,1) double {mustBeFinite}
        margin (1,1) double {mustBeFinite, mustBeNonnegative}
        CBSD_label (1,:) char
        base_polygon (:,2) double
        base_protection_pts (:,2) double
        tf_catb (1,1) logical
    end

    %% -------- Filenames --------
    statsFile = sprintf('%s_%s_%g_all_data_stats_binary.mat', CBSD_label, data_label1, sim_number);
    distFile  = sprintf('%s_mod_%s_%g_catb_dist_data.mat', CBSD_label, data_label1, sim_number);

    if ~isfile(statsFile)
        return
    end

    %% -------- Load stats --------
    S = loadWithRetry(statsFile, "all_data_stats_binary");
    all_data_stats_binary = S.all_data_stats_binary;

    %% -------- Compute distances (reused function) --------
    catb_dist_data = calc_zone_distance_rev1(app, all_data_stats_binary, radar_threshold, margin);

    %% -------- Normalize label --------
    labelForPlot = normalizeCBSDLabel(CBSD_label);

    %% -------- Heatmap --------
    [~, m_idx] = max(catb_dist_data, [], "omitnan");
    heatmapPng = sprintf('%s_mod_%s_DistHeatMap1_%g.png', CBSD_label, data_label1, sim_number);
    plotDistanceHeatmap(base_polygon, base_protection_pts, catb_dist_data, m_idx, ...
        data_label1, labelForPlot, heatmapPng);

    %% -------- Histogram --------
    histPng = sprintf('%s_mod_%s_Histogram_%g.png', CBSD_label, data_label1, sim_number);
    plotDistanceHistogram(catb_dist_data, data_label1, labelForPlot, histPng);

    %% -------- Series plot --------
    seriesPng = sprintf('%s_mod_%s_AllPoints_%g.png', CBSD_label, data_label1, sim_number);
    plotAllPointsSeries(catb_dist_data, data_label1, labelForPlot, seriesPng);

    %% -------- Worst-case curve --------
    singlePng = sprintf('%s_mod_%s_SinglePoint_%g.png', CBSD_label, data_label1, sim_number);
    plotSinglePointCurve(all_data_stats_binary, catb_dist_data, radar_threshold, ...
        data_label1, labelForPlot, singlePng);

    %% -------- Neighborhood Bound --------
    [neighborhood_bound, buffer_radius] = computeNeighborhoodBound(app, base_polygon, catb_dist_data);

    neighPng = sprintf('%s_mod_%s_Neighborhood_%g.png', CBSD_label, data_label1, sim_number);
    plotNeighborhood(base_polygon, neighborhood_bound, buffer_radius, ...
        data_label1, labelForPlot, neighPng);

    %% -------- Save neighborhood + distances (MAT) --------
    saveWithRetry(sprintf('%s_%s_neighborhood_bound.mat', CBSD_label, data_label1), ...
        struct("neighborhood_bound", neighborhood_bound));

    if tf_catb
        catb_neighborhood_radius = buffer_radius;
        saveWithRetry(sprintf('%s_%s_catb_neighborhood_radius.mat', CBSD_label, data_label1), ...
            struct("catb_neighborhood_radius", catb_neighborhood_radius));

        saveWithRetry(distFile, struct("catb_dist_data", catb_dist_data));
    else
        cata_neighborhood_radius = buffer_radius;
        cata_dist_data = catb_dist_data;

        saveWithRetry(sprintf('%s_%s_cata_neighborhood_radius.mat', CBSD_label, data_label1), ...
            struct("cata_neighborhood_radius", cata_neighborhood_radius));

        saveWithRetry(sprintf('%s_mod_%s_%g_cata_dist_data.mat', CBSD_label, data_label1, sim_number), ...
            struct("cata_dist_data", cata_dist_data));
    end

    disp(sprintf('%s-Distance:%g', string(labelForPlot), max(catb_dist_data, [], "omitnan")));
end

% =====================================================================
% UPDATED SUBFUNCTIONS (each saves internally using saveWithRetry)
% =====================================================================

function plotDistanceHeatmap(base_polygon, base_protection_pts, dist_km, maxIndex, ...
                             data_label1, CBSD_label_plot, pngFile)
    arguments
        base_polygon (:,2) double
        base_protection_pts (:,2) double
        dist_km (:,1) double
        maxIndex (1,1) double = NaN
        data_label1 (1,:) char
        CBSD_label_plot
        pngFile (1,:) char
    end

    fig = figure("Color","w","Position",[100 100 1200 900]);
    hold on

    geoplot(base_polygon(:,1), base_polygon(:,2), "-k", "LineWidth", 1.5);

    tfValid = ~isnan(dist_km);
    if any(tfValid)
        geoscatter(base_protection_pts(tfValid,1), base_protection_pts(tfValid,2), ...
            30, dist_km(tfValid), "filled");
        colormap(jet);
        cb = colorbar;
        cb.Label.String = "Neighborhood Distance [km]";
    else
        geoscatter(base_protection_pts(:,1), base_protection_pts(:,2), 30, "filled");
    end

    % Mark top 10 and max
    C = dist_km; C(isnan(C)) = -Inf;
    [~, sidx] = sort(C, "descend");
    k = min(10, numel(sidx));
    if k > 0
        geoplot(base_protection_pts(sidx(1:k),1), base_protection_pts(sidx(1:k),2), ...
            "sr", "MarkerSize", 8, "LineWidth", 1.5);
    end
    if ~isnan(maxIndex) && maxIndex>=1 && maxIndex<=size(base_protection_pts,1)
        geoplot(base_protection_pts(maxIndex,1), base_protection_pts(maxIndex,2), ...
            "ok", "MarkerSize", 14, "LineWidth", 3);
    end

    title({data_label1, "Neighborhood Distances [km]", string(CBSD_label_plot)});
    grid on
    geobasemap streets-light

    saveWithRetry(pngFile, fig);
    close(fig);
end

function plotDistanceHistogram(dist_km, data_label1, CBSD_label_plot, pngFile)
    arguments
        dist_km (:,1) double
        data_label1 (1,:) char
        CBSD_label_plot
        pngFile (1,:) char
    end

    d = dist_km(~isnan(dist_km));
    if isempty(d)
        return
    end

    nBins = max(10, ceil(sqrt(numel(d))));

    fig = figure("Color","w");
    histogram(d, "Normalization","probability", "NumBins", nBins, "FaceColor",[0.2 0.4 0.8]);
    hold on
    xline(max(d), "k-", "LineWidth", 3);

    xlabel("Neighborhood Distance [km]");
    ylabel("Probability");
    grid on
    title({sprintf('%s: Histogram of Neighborhood Distance', data_label1), ...
        sprintf('Max Distance: %.2f km', max(d)), ...
        string(CBSD_label_plot)});

    saveWithRetry(pngFile, fig);
    close(fig);
end

function plotAllPointsSeries(dist_km, data_label1, CBSD_label_plot, pngFile)
    arguments
        dist_km (:,1) double
        data_label1 (1,:) char
        CBSD_label_plot
        pngFile (1,:) char
    end

    fig = figure("Color","w");
    plot(dist_km, "-ob");
    grid on
    xlabel("Neighborhood Index");
    ylabel("Neighborhood Distance [km]");
    title({data_label1, sprintf("Neighborhood: %.2f km", max(dist_km,[],"omitnan")), string(CBSD_label_plot)});

    saveWithRetry(pngFile, fig);
    close(fig);
end

function plotSinglePointCurve(all_data_stats_binary, dist_km, radar_threshold, ...
                              data_label1, CBSD_label_plot, pngFile)
    arguments
        all_data_stats_binary (1,:) cell
        dist_km (:,1) double
        radar_threshold (1,1) double {mustBeFinite}
        data_label1 (1,:) char
        CBSD_label_plot
        pngFile (1,:) char
    end

    [~, idx] = max(dist_km, [], "omitnan");
    if isempty(idx) || isnan(idx) || idx < 1 || idx > numel(all_data_stats_binary)
        return
    end

    S = all_data_stats_binary{idx};
    if isempty(S) || size(S,2) < 2
        return
    end

    fig = figure("Color","w");
    plot(S(:,1), S(:,2), "-sk");
    hold on

    yline(radar_threshold, "r-", "LineWidth", 2);

    xl = xlim; yl = ylim;
    patch([xl(1) xl(2) xl(2) xl(1)], ...
          [radar_threshold radar_threshold yl(1) yl(1)], ...
          "g", "FaceAlpha", 0.15, "EdgeColor","none");

    if ~isnan(dist_km(idx))
        xline(dist_km(idx), "b-", "LineWidth", 2);
    end

    grid on
    xlabel("Neighborhood Distance");
    ylabel("Aggregate Interference [dBm]");
    title({sprintf('%s:%d', data_label1, idx), ...
        sprintf('Neighborhood: %.2f km', dist_km(idx)), ...
        string(CBSD_label_plot)});

    saveWithRetry(pngFile, fig);
    close(fig);
end

function plotNeighborhood(base_polygon, neighborhood_bound, buffer_radius, ...
                          data_label1, CBSD_label_plot, pngFile)
    arguments
        base_polygon (:,2) double
        neighborhood_bound (:,2) double
        buffer_radius (1,1) double {mustBeFinite}
        data_label1 (1,:) char
        CBSD_label_plot
        pngFile (1,:) char
    end

    nnan_base_polygon = base_polygon(~isnan(base_polygon(:,1)), :);

    fig = figure("Color","w","Position",[100 100 1200 900]);
    hold on

    if size(nnan_base_polygon,1) > 1
        geoplot(base_polygon(:,1), base_polygon(:,2), "-k");
    else
        geoplot(nnan_base_polygon(:,1), nnan_base_polygon(:,2), "ok");
    end

    geoplot(neighborhood_bound(:,1), neighborhood_bound(:,2), "--r", "LineWidth", 1.5);

    title({data_label1, sprintf('%s-Neighborhood: %.2f km', string(CBSD_label_plot), buffer_radius)});
    grid on
    geobasemap streets-light

    saveWithRetry(pngFile, fig);
    close(fig);
end