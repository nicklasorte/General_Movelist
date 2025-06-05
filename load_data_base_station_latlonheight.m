function [base_station_latlonheight]=load_data_base_station_latlonheight(app)



retry_load=1;
while(retry_load==1)
    try
        disp_progress(app,strcat('Loading Sim Data: base_station_latlonheight . . . '))

        load('base_station_latlonheight.mat','base_station_latlonheight')
        temp_data=base_station_latlonheight;
        clear base_station_latlonheight;
        base_station_latlonheight=temp_data;
        clear temp_data;

        retry_load=0;
    catch
        retry_load=1
        pause(0.1)
    end
end