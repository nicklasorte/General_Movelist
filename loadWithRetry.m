function S = loadWithRetry(filename, variables, maxRetries, pauseSeconds)
%loadWithRetry  Safely load MAT file with retry protection.
%
%   S = loadWithRetry(filename)
%   S = loadWithRetry(filename, variables)
%   S = loadWithRetry(filename, variables, maxRetries, pauseSeconds)
%
% Inputs:
%   filename      char/string MAT file name
%   variables     string/char/cellstr of variable names (optional)
%   maxRetries    number of retry attempts (default 10)
%   pauseSeconds  pause between retries (default 0.1 sec)
%
% Output:
%   S             struct returned by load()

    arguments
        filename (1,:) char
        variables = []
        maxRetries (1,1) double {mustBePositive,mustBeInteger} = 10
        pauseSeconds (1,1) double {mustBeNonnegative} = 0.1
    end

    if ~isfile(filename)
        error("loadWithRetry:FileNotFound", ...
            "File not found: %s", filename);
    end

    attempt = 0;
    lastError = [];

    while attempt < maxRetries
        try
            if isempty(variables)
                S = load(filename);
            else
                S = load(filename, variables);
            end
            return
        catch ME
            lastError = ME;
            attempt = attempt + 1;
            pause(pauseSeconds);
        end
    end

    error("loadWithRetry:FailedAfterRetries", ...
        "Failed to load %s after %d attempts.\nLast error: %s", ...
        filename, maxRetries, lastError.message);
end