function [tfExists, info] = persistent_matfile_exists_with_corruption_GPT_rev2(~, fileName, opts)
%PERSISTENT_MATFILE_EXISTS_WITH_CORRUPTION Robust existence + MAT-file sanity check.
%
% This is designed for network shares that occasionally disappear.
% It retries transient I/O errors and deletes MAT-files that look corrupted.
%
% Inputs
%   fileName (string/char) : full path recommended
%   opts (name-value via struct or arguments block below)
%
% Outputs
%   tfExists : logical, true if file exists and appears readable as a MAT-file
%   info     : diagnostics (attempt counts, last error/warning, deleted flag)

arguments
    ~
    fileName (1,1) string

    % "Persistent" behavior: default is effectively infinite wait.
    opts.MaxWaitSeconds (1,1) double {mustBePositive} = inf

    % Retry pacing (with exponential backoff).
    opts.InitialPauseSeconds (1,1) double {mustBeNonnegative} = 0.25
    opts.BackoffFactor       (1,1) double {mustBeGreaterThanOrEqual(opts.BackoffFactor,1)} = 1.3
    opts.MaxPauseSeconds     (1,1) double {mustBePositive} = 5

    % Corruption policy
    opts.DeleteOnCorruption  (1,1) logical = true
end

info = struct( ...
    "existsChecks", 0, ...
    "validateChecks", 0, ...
    "deleted", false, ...
    "lastWarning", "", ...
    "lastError", "" ...
);

t0 = tic;
pauseT = opts.InitialPauseSeconds;

% --- Keep trying until success or time limit ---
while true
    % Stop if time limit exceeded
    if ~isinf(opts.MaxWaitSeconds) && toc(t0) > opts.MaxWaitSeconds
        tfExists = false;
        return
    end

    % 1) Existence check (can throw on flaky shares)
    info.existsChecks = info.existsChecks + 1;
    try
        tfExists = isfile(fileName);  % clearer/faster than exist for files :contentReference[oaicite:2]{index=2}
    catch ME
        info.lastError = string(ME.message);
        pause(pauseT);
        pauseT = min(opts.MaxPauseSeconds, pauseT * opts.BackoffFactor);
        continue
    end

    if ~tfExists
        % File truly not there (or folder is visible but file absent).
        return
    end

    % 2) Sanity check the MAT-file without loading data: whos('-file',...)
    %    If the file is truncated/corrupt, this typically errors quickly.
    info.validateChecks = info.validateChecks + 1;

    % Save & restore warning state; ensure lastwarn is local to this attempt. :contentReference[oaicite:3]{index=3}
    origWarnState = warning;
    c = onCleanup(@() warning(origWarnState)); %#ok<NASGU>
    warning("");         % resets lastwarn state :contentReference[oaicite:4]{index=4}
    lastwarn("", "");    % reset message/id :contentReference[oaicite:5]{index=5}

    try
        whos("-file", fileName);  % header/metadata read; no workspace pollution
        [wmsg, ~] = lastwarn;
        info.lastWarning = string(wmsg);

        % Some truncations show as warning text; treat "Unexpected end-of-file" as corruption.
        if ~isempty(wmsg) && contains(wmsg, "Unexpected end-of-file", "IgnoreCase", true)
            if opts.DeleteOnCorruption
                safeDelete_(fileName);
                info.deleted = true;
                tfExists = false;
            end
        end

        % If we got here, share is reachable and MAT-file is readable.
        return

    catch ME
        info.lastError = string(ME.message);

        % Heuristic: decide corruption vs transient network/locking.
        if looksLikeCorruption_(ME)
            if opts.DeleteOnCorruption
                safeDelete_(fileName);
                info.deleted = true;
                tfExists = false;
            end
            return
        end

        % Otherwise treat as transient (share dropped, permission hiccup, file locked mid-write).
        pause(pauseT);
        pauseT = min(opts.MaxPauseSeconds, pauseT * opts.BackoffFactor);
    end
end

end

function tf = looksLikeCorruption_(ME)
% Conservative: delete only for strong MAT read/corruption/truncation signals.
msg = string(ME.message);
id  = string(ME.identifier);

tf = contains(msg, "File might be corrupt",      "IgnoreCase", true) || ...
     contains(msg, "Cannot read file",           "IgnoreCase", true) || ...
     contains(msg, "Unable to read",             "IgnoreCase", true) || ...
     contains(msg, "Unexpected end-of-file",     "IgnoreCase", true) || ...
     contains(msg, "not a MAT-file",             "IgnoreCase", true) || ...
     contains(id,  "MATLAB:load",                "IgnoreCase", true) || ...
     contains(id,  "MATLAB:whos",                "IgnoreCase", true);
end

function safeDelete_(fileName)
try
    if isfile(fileName)
        delete(fileName);
    end
catch
    % Intentionally quiet: delete can fail due to permissions/locks/share flakiness.
end
end