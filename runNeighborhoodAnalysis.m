function results = runNeighborhoodAnalysis(app, data_label1, sim_number, radar_threshold, margin,CBSD_label, base_polygon, base_protection_pts, tf_catb,doPlots, doExportPNG, doSaveMAT, outputFolder)
%runNeighborhoodAnalysis
%
% Clean architecture:
%   • Returns results struct
%   • Separates computation from plotting
%   • Plotting/export can be turned on/off
%   • Uses exportgraphics (modern)
%   • Reuses calc_zone_distance_rev1

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
        doPlots (1,1) logical = true
        doExportPNG (1,1) logical = true
        doSaveMAT (1,1) logical = true
        outputFolder (1,:) char = pwd
    end

    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    %% -------------------------------------------------
    % Compute distances (reuses your function)
    %% -------------------------------------------------
    statsFile = sprintf('%s_%s_%g_all_data_stats_binary.mat', ...
        CBSD_label, data_label1, sim_number);

    if ~isfile(statsFile)
        results = struct;
        return
    end

    S = load(statsFile,"all_data_stats_binary");
    all_data_stats_binary = S.all_data_stats_binary;

    catb_dist_data = calc_zone_distance_rev1( ...
        app, all_data_stats_binary, radar_threshold, margin);

    [maxDistanceKm, maxIndex] = max(catb_dist_data,[],"omitnan");

    [neighborhood_bound, neighborhood_radius_km] = ...
        computeNeighborhoodBound(app, base_polygon, catb_dist_data);

    CBSD_label_plot = normalizeCBSDLabel(CBSD_label);

    %% -------------------------------------------------
    % Save MAT outputs
    %% -------------------------------------------------
    if doSaveMAT
        saveSafe(fullfile(outputFolder, ...
            sprintf('%s_%s_neighborhood_bound.mat', CBSD_label, data_label1)), ...
            neighborhood_bound=neighborhood_bound);

        if tf_catb
            saveSafe(fullfile(outputFolder, ...
                sprintf('%s_%s_catb_neighborhood_radius.mat', CBSD_label, data_label1)), ...
                catb_neighborhood_radius=neighborhood_radius_km);

            saveSafe(fullfile(outputFolder, ...
                sprintf('%s_mod_%s_%g_catb_dist_data.mat', CBSD_label, data_label1, sim_number)), ...
                catb_dist_data=catb_dist_data);
        else
            saveSafe(fullfile(outputFolder, ...
                sprintf('%s_%s_cata_neighborhood_radius.mat', CBSD_label, data_label1)), ...
                cata_neighborhood_radius=neighborhood_radius_km);

            cata_dist_data = catb_dist_data;
            saveSafe(fullfile(outputFolder, ...
                sprintf('%s_mod_%s_%g_cata_dist_data.mat', CBSD_label, data_label1, sim_number)), ...
                cata_dist_data=cata_dist_data);
        end
    end

    %% -------------------------------------------------
    % Plotting Section (optional)
    %% -------------------------------------------------
    figFiles = struct;

    if doPlots

        % Heatmap
        f = plotDistanceHeatmap(base_polygon, base_protection_pts, ...
            catb_dist_data, maxIndex, data_label1, CBSD_label_plot);
        figFiles.Heatmap = exportFigure(f, doExportPNG, outputFolder, ...
            sprintf('%s_mod_%s_DistHeatMap1_%g.png', CBSD_label, data_label1, sim_number));
        close(f);

        % Histogram
        f = plotDistanceHistogram(catb_dist_data, data_label1, CBSD_label_plot);
        figFiles.Histogram = exportFigure(f, doExportPNG, outputFolder, ...
            sprintf('%s_mod_%s_Histogram_%g.png', CBSD_label, data_label1, sim_number));
        close(f);

        % Series
        f = plotAllPointsSeries(catb_dist_data, data_label1, CBSD_label_plot);
        figFiles.Series = exportFigure(f, doExportPNG, outputFolder, ...
            sprintf('%s_mod_%s_AllPoints_%g.png', CBSD_label, data_label1, sim_number));
        close(f);

        % Single worst case
        f = plotSinglePointCurve(all_data_stats_binary, catb_dist_data, ...
            radar_threshold, data_label1, CBSD_label_plot);
        figFiles.SinglePoint = exportFigure(f, doExportPNG, outputFolder, ...
            sprintf('%s_mod_%s_SinglePoint_%g.png', CBSD_label, data_label1, sim_number));
        close(f);

        % Neighborhood map
        f = plotNeighborhood(base_polygon, neighborhood_bound, ...
            neighborhood_radius_km, data_label1, CBSD_label_plot);
        figFiles.Neighborhood = exportFigure(f, doExportPNG, outputFolder, ...
            sprintf('%s_mod_%s_Neighborhood_%g.png', CBSD_label, data_label1, sim_number));
        close(f);

    end

    %% -------------------------------------------------
    % Return structured output
    %% -------------------------------------------------
    results = struct;
    results.catb_dist_data = catb_dist_data;
    results.maxDistanceKm = maxDistanceKm;
    results.maxIndex = maxIndex;
    results.neighborhood_radius_km = neighborhood_radius_km;
    results.neighborhood_bound = neighborhood_bound;
    results.CBSD_label_plot = CBSD_label_plot;
    results.figureFiles = figFiles;
end