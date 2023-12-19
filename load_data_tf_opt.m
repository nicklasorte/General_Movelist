function [tf_opt]=load_data_tf_opt(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: tf_opt . . . '))
        load('tf_opt.mat','tf_opt')
        temp_data=tf_opt;
        clear tf_opt;
        tf_opt=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end