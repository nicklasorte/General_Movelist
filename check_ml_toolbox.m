function [tf_ml_toolbox]=check_ml_toolbox(app)

if isdeployed==1
    tf_ml_toolbox=1
else
    toolbox_pull = ver;
    tf_ml_toolbox=any(strcmp(cellstr(char(toolbox_pull.Name)), 'Statistics and Machine Learning Toolbox'));
end


end