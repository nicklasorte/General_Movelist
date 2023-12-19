function [var_exist]=persistent_var_exist_with_corruption(app,file_name)
retry_exists=1;
while(retry_exists==1)
    try
        var_exist=exist(file_name,'file');
        retry_exists=0;
    catch
        retry_exists=1;
        pause(1)
    end
end

%%%%%%%Try to load it and delete it if it is corrupted
if var_exist==2
    retry_check=1;
    tf_delete=0;
    while(retry_check==1)
        try
            warning('');
            load(file_name)
            retry_check=0;
            [warnMsg, warnId] = lastwarn;
            if ~isempty(warnMsg)
                %%%%%...react to warning...
                tf_find4=contains(warnMsg,'Unexpected end-of-file');
                if tf_find4==1
                    %%%%Delete File
                    delete(file_name)
                    retry_check=0;
                    tf_delete=1;
                end
            end
        catch error_msg
            temp_error_string=error_msg.message
            tf_find1=contains(temp_error_string,'File might be corrupt.')
            tf_find2=contains(temp_error_string,'Cannot read file')
            tf_find3=contains(temp_error_string,'Unable to read')
            file_name
            if tf_find1==1 || tf_find2==1 || tf_find3==1
                %%%%Delete File
                delete(file_name)
                retry_check=0;
                tf_delete=1;
            else
                retry_check=1;
                pause(0.1)
            end
        end
    end
    
    if tf_delete==1
        var_exist=0;
    end
end
end





