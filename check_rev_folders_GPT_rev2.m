function [sim_number,folder_names,num_folders,folder_paths] = check_rev_folders_GPT_rev2(app,rev_folder)
%check_rev_folders  Parse sim number from a "...RevX" folder and list subfolders.

    arguments
        app %#ok<INUSA>
        rev_folder {mustBeTextScalar}
    end

    rev_folder = char(rev_folder);

    if ~isfolder(rev_folder)
        error("check_rev_folders:NotAFolder", "Folder not found: %s", rev_folder);
    end

    [~, leafName] = fileparts(rev_folder);

    % More flexible: find the *last* Rev### in the leaf name
    toks = regexp(leafName, 'Rev(\d+)', 'tokens', 'ignorecase');
    if isempty(toks)
        error("check_rev_folders:BadName", ...
            "Expected folder name to contain 'Rev###'. Got: %s", leafName);
    end

    sim_number = str2double(toks{end}{1});
    if isnan(sim_number)
        error("check_rev_folders:ParseFailed", ...
            "Could not parse sim number from: %s", leafName);
    end

    d = dir(rev_folder);
    isSub = [d.isdir] & ~ismember({d.name}, {'.','..'});
    folder_names = string({d(isSub).name}).';

    % Stable, reproducible order
    folder_names = sort(folder_names);

    num_folders = numel(folder_names);
    folder_paths = fullfile(string(rev_folder), folder_names);
end