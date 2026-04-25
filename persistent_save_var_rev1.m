function persistent_save_var_rev1(app,file_name,var_name,var_value) %#ok<INUSL>
%%%%%%%%Save a single variable to a .mat file with retry on failure.
%%%%%%%%Mirrors the inline save/while-retry pattern used across the codebase.
%%%%%%%%var_name is the variable name as it should be saved inside the .mat.

%%%%%%%%Assign in this scope so save() picks up the correct variable name
eval([var_name '=var_value;']);

retry_save=1;
while(retry_save==1)
    try
        save(file_name,var_name)
        retry_save=0;
    catch
        retry_save=1;
        pause(1)
    end
end
end
