function [tf_test]=load_data_tf_test(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: tf_test . . . '))
        load('tf_test.mat','tf_test')
        temp_data=tf_test;
        clear tf_test;
        tf_test=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end
