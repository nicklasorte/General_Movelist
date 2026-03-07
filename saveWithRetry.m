function saveWithRetry(filename, payload, maxRetries, pauseSeconds, resolutionDPI)
%saveWithRetry  Retry-safe save for MAT files and figure exports.
%
%   saveWithRetry("file.mat", payload)
%     - if payload is a scalar struct -> saves fields as variables (like -struct)
%     - otherwise -> saves one variable named "payload"
%
%   saveWithRetry("plot.png", figOrAxes) exports graphics using exportgraphics.

    arguments
        filename (1,1) string
        payload
        maxRetries (1,1) double {mustBePositive, mustBeInteger} = 10
        pauseSeconds (1,1) double {mustBeNonnegative} = 0.1
        resolutionDPI (1,1) double {mustBePositive, mustBeInteger} = 200
    end

    isMat = endsWith(lower(filename), ".mat");
    lastError = MException.empty;

    for attempt = 1:maxRetries
        try
            if isMat
                if isstruct(payload) && isscalar(payload)
                    % Save fields as variables (requires scalar struct + variable name). :contentReference[oaicite:1]{index=1}
                    save(filename, "-struct", "payload");
                else
                    % Save payload as a single variable (always works, including non-scalar structs/cells).
                    save(filename, "payload");
                end
            else
                % Use isgraphics for robust handle checking. :contentReference[oaicite:2]{index=2}
                if ~(isgraphics(payload, "figure") || isgraphics(payload, "axes"))
                    error("saveWithRetry:BadPayload", ...
                        "For image export, payload must be a figure or axes graphics object.");
                end
                exportgraphics(payload, filename, "Resolution", resolutionDPI); % :contentReference[oaicite:3]{index=3}
            end
            return
        catch ME
            lastError = ME;
            pause(pauseSeconds);
        end
    end

    error("saveWithRetry:FailedAfterRetries", ...
        "Failed to save/export %s after %d attempts.\nLast error: %s", ...
        filename, maxRetries, lastError.message);
end