function [tf_full_turnoff]=load_data_tf_full_turnoff(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: tf_full_turnoff . . . '))
        load('tf_full_turnoff.mat','tf_full_turnoff')
        temp_data=tf_full_turnoff;
        clear tf_full_turnoff;
        tf_full_turnoff=temp_data;
        clear temp_data;
        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end
