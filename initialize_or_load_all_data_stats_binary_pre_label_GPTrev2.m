function all_data_stats_binary = initialize_or_load_all_data_stats_binary_pre_label_GPTrev2(app, data_label1, sim_number, rand_pts, pre_label, opts)
%INITIALIZE_OR_LOAD_ALL_DATA_STATS_BINARY_PRE_LABEL_GPTREV2
% Load cached results or create an empty cell array, with robust retry I/O.

if nargin < 6 || isempty(opts)
    opts = struct();
end

'Needs works'
pause;
opts = localFillDefaults(opts, struct( ...
    "Folder",        "", ...
    "MaxRetries",    20, ...
    "BasePause",     0.05, ...
    "BackoffFactor", 1.15, ...
    "MaxPause",      0.50, ...
    "AtomicSave",    true));

% Build file path.
baseName = sprintf('%s_%s_%d_all_data_stats_binary.mat', pre_label, data_label1, sim_number);
if strlength(string(opts.Folder)) > 0
    fileName = string(fullfile(opts.Folder, baseName));
else
    fileName = string(baseName);
end

% Prefer your existing sentinel if available; fall back to file existence.
varExist = [];
try
    varExist = persistent_var_exist_GPT_rev2(app, fileName);
catch
end

fileExists = isfile(fileName);
if isempty(varExist)
    varExist = 2*fileExists;  % 2 -> load, 0 -> init
end

% -------------------- LOAD --------------------
if varExist == 2
    localProgress(app, "Loading cached all_data_stats_binary: " + fileName);

    S = retryIO(@() load(char(fileName), "all_data_stats_binary"), opts, "load");

    if ~isfield(S, "all_data_stats_binary")
        error("initialize_or_load_all_data_stats_binary_pre_label_GPTrev2:MissingVariable", ...
            "MAT-file '%s' exists but does not contain variable 'all_data_stats_binary'.", fileName);
    end

    all_data_stats_binary = S.all_data_stats_binary;
    return
end

% ------------------ INITIALIZE ----------------
n = size(rand_pts, 1);
all_data_stats_binary = cell(n, 1);

localProgress(app, "Initializing all_data_stats_binary (" + n + "x1) and saving: " + fileName);

% Ensure folder exists.
if strlength(string(opts.Folder)) > 0 && ~isfolder(opts.Folder)
    retryIO(@() mkdir(char(opts.Folder)), opts, "mkdir");
end

% Prepare payload as scalar struct (the *value* we want to save).
payload = struct('all_data_stats_binary', all_data_stats_binary);

% Save (optionally atomically).
if opts.AtomicSave
    tmpName = fileName + ".tmp_" + string(feature("getpid")) + "_" + string(randi(1e9)) + ".mat";
    retryIO(@() localSaveStruct(char(tmpName), payload), opts, "save(tmp)");
    retryIO(@() movefile(char(tmpName), char(fileName), 'f'), opts, "movefile");
else
    retryIO(@() localSaveStruct(char(fileName), payload), opts, "save");
end

end

% =====================================================================
function localSaveStruct(fName, payload)
%localSaveStruct Save fields of a scalar struct without workspace issues.
%
% save -struct requires the NAME of a scalar struct variable that exists in
% the *current* workspace. So we create one here with a known name.

S = payload; %#ok<NASGU>
save(fName, '-struct', 'S');
end

% =====================================================================
function varargout = retryIO(fcn, opts, verb)
%RETRYIO Retry an operation with bounded attempts and backoff.
lastME = [];

for k = 1:opts.MaxRetries
    try
        nout = nargout;   % outputs requested from retryIO
        if nout == 0
            fcn();
            return
        else
            [varargout{1:nout}] = fcn();
            return
        end
    catch ME
        lastME = ME;
        if k == opts.MaxRetries
            error("retryIO:Failed", ...
                "Failed to %s after %d attempts.\nLast error: %s", ...
                string(verb), opts.MaxRetries, string(lastME.message));
        end
        pause_s = min(opts.MaxPause, opts.BasePause * opts.BackoffFactor^(k-1));
        pause(pause_s);
    end
end

if ~isempty(lastME)
    rethrow(lastME);
end
end

% =====================================================================
function localProgress(app, msg)
if isempty(app), return, end
try
    disp_progress(app, msg);
catch
end
end

% =====================================================================
function opts = localFillDefaults(opts, defaults)
f = fieldnames(defaults);
for i = 1:numel(f)
    if ~isfield(opts, f{i}) || isempty(opts.(f{i}))
        opts.(f{i}) = defaults.(f{i});
    end
end
end