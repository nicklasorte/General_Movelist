function [data,info] = load_variable_with_retry_GPT_rev2(app,fileName,varName,opts)
%load_variable_with_retry_GPT_rev2 Robustly load ONE variable from a MAT-file (with retry).

arguments
    app                               % required (can be [] at runtime)
    fileName (1,1) string
    varName  (1,1) string
    opts.PauseSeconds   (1,1) double {mustBeFinite,mustBeNonnegative} = 0.2
    opts.MaxRetries     (1,1) double {mustBePositive} = Inf
    opts.TimeoutSeconds (1,1) double {mustBeNonnegative} = Inf
    opts.Validate = []               % function handle: tf = Validate(data)
    opts.OnCatch  = []               % function handle: txt = OnCatch(ME,attempt)
end

t0 = tic;
attempt = 0;

info = struct( ...
    "AttemptCount",0, ...
    "ElapsedSeconds",0, ...
    "LastErrorId","", ...
    "LastErrorMessage","");

while true
    attempt = attempt + 1;

    % Progress message (throttle if you like; keeping it simple).
    if ~isempty(app)
        try
            disp_progress(app,"Loading: " + varName + " ...");
        catch
            % If disp_progress isn't available or errors, ignore.
        end
    end

    try
        S = load(fileName, varName);   % load only the requested variable
        if ~isfield(S, varName)
            error("load_variable_with_retry:MissingVariable", ...
                "Variable '%s' not found in file '%s'.", varName, fileName);
        end

        data = S.(varName);

        % Optional validation hook (reject and retry).
        if ~isempty(opts.Validate)
            tf = opts.Validate(data);
            if ~(islogical(tf) && isscalar(tf) && tf)
                error("load_variable_with_retry:ValidationFailed", ...
                    "Validation failed for '%s' loaded from '%s'.", varName, fileName);
            end
        end

        info.AttemptCount   = attempt;
        info.ElapsedSeconds = toc(t0);
        return

    catch ME
        info.LastErrorId      = string(ME.identifier);
        info.LastErrorMessage = string(ME.message);
        info.AttemptCount     = attempt;
        info.ElapsedSeconds   = toc(t0);

        % Custom catch handling/logging hook.
        if ~isempty(opts.OnCatch)
            try
                txt = opts.OnCatch(ME,attempt);
                if ~isempty(txt) && ~isempty(app)
                    disp_progress(app,string(txt));
                end
            catch
            end
        end

        % Stop conditions.
        if attempt >= opts.MaxRetries
            error("load_variable_with_retry:MaxRetriesExceeded", ...
                "Failed loading '%s' from '%s' after %d attempts. Last error: %s", ...
                varName, fileName, attempt, info.LastErrorMessage);
        end
        if info.ElapsedSeconds >= opts.TimeoutSeconds
            error("load_variable_with_retry:Timeout", ...
                "Timed out (%.3g s) loading '%s' from '%s'. Last error: %s", ...
                opts.TimeoutSeconds, varName, fileName, info.LastErrorMessage);
        end

        pause(opts.PauseSeconds);
    end
end
end