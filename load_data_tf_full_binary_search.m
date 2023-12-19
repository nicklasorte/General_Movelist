function [tf_full_binary_search]=load_data_tf_full_binary_search(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: tf_full_binary_search . . . '))
        load('tf_full_binary_search.mat','tf_full_binary_search')
        temp_data=tf_full_binary_search;
        clear tf_full_binary_search;
        tf_full_binary_search=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end