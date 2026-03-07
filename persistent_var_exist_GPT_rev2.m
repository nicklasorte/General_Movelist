function varExist = persistent_var_exist_GPT_rev2(~, fileName)
%PERSISTENT_VAR_EXIST  Check whether a file exists (robust version).
%
%   varExist = persistent_var_exist(~, fileName)
%
%   Returns:
%       2  if file exists   (to preserve your legacy convention)
%       0  if file does not exist

    arguments
        ~
        fileName (1,1) string
    end

    maxRetries = 5;
    basePause  = 0.05;

    for k = 1:maxRetries
        try
            fileExists = isfile(fileName);
            varExist   = 2 * fileExists;   % Preserve your 0 / 2 convention
            return
        catch ME
            if k == maxRetries
                error("persistent_var_exist:FailedCheck", ...
                    "Failed to check file existence after %d attempts.\n%s", ...
                    maxRetries, ME.message);
            end
            pause(basePause * k);  % gentle backoff
        end
    end
end