function [var_value]=persistent_load_var_rev1(app,file_name,var_name)
%%%%%%%%Load a single variable from a .mat file with retry on failure.
%%%%%%%%Mirrors the inline load/while-retry pattern used across the codebase.

retry_load=1;
while(retry_load==1)
    try
        S=load(file_name,var_name);
        var_value=S.(var_name);
        retry_load=0;
    catch
        retry_load=1;
        pause(1)
    end
end
end
