function variable_data = load_variable_with_retry(app, file_name, variable_name, pause_time)

    if nargin < 4 || isempty(pause_time)
        pause_time = 1;
    end

    %%%%A = load_variable_with_retry(app, 'results.mat', 'A', 0.2);
    while true
        try
            if ~isempty(app)
                disp_progress(app, ...
                    "Loading: " + string(variable_name) + " ...")
            end

            S = load(file_name, variable_name);
            variable_data = S.(variable_name);
            return

        catch
            pause(pause_time);
        end
    end
end

% function variable_data = load_variable_with_retry(app, file_name, variable_name, pause_time)
% %LOAD_VARIABLE_WITH_RETRY Load a variable from MAT-file with retry logic
% %
% %   variable_data = load_variable_with_retry(app, file_name, variable_name)
% %   variable_data = load_variable_with_retry(app, file_name, variable_name, pause_time)
% 
%     % Default pause_time = 1 second
%     if nargin < 4 || isempty(pause_time)
%         pause_time = 1;
%     end
% 
%     retry_load = 1;
% 
%     while retry_load == 1
%         try
%             if ~isempty(app)
%                 disp_progress(app, ...
%                     strcat('Loading: ', string(variable_name), ' ...'))
%             end
% 
%             % Load requested variable only
%             S = load(file_name, variable_name);
% 
%             % Dynamic field access
%             variable_data = S.(variable_name);
% 
%             retry_load = 0;
% 
%         catch
%             retry_load = 1;
%             pause(pause_time);
%         end
%     end
% end