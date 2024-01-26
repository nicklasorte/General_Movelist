function [var_exist]=persistent_var_exist(app,file_name)
retry_save=1;
while(retry_save==1)
    try
        var_exist=exist(file_name,'file');
        retry_save=0;
    catch
        retry_save=1;
        pause(1)
    end
end
end