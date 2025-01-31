function []=plot_miti_sectors_rev1_app(app,data_label1,string_prop_model,mitigation_union_mitigation_list_data,mitigation_union_turn_off_list_data,base_polygon,on_list_bs,max_knn_dist_off,max_knn_dist_miti)


f2=fullfig; %%%%%%%%%%%f2=figure;
AxesH = axes;
hold on;
scatter(mitigation_union_mitigation_list_data(:,2),mitigation_union_mitigation_list_data(:,1),5,'k','filled')
scatter(mitigation_union_turn_off_list_data(:,2),mitigation_union_turn_off_list_data(:,1),5,'k','filled')
plot(base_polygon(:,2),base_polygon(:,1),'-b','LineWidth',3)
grid on;
plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
temp_axis=axis;
xspan=temp_axis(2)-temp_axis(1);
yspan=temp_axis(4)-temp_axis(3);
temp_axis(1)=temp_axis(1)-0.1*xspan;
temp_axis(3)=temp_axis(3)-0.1*yspan;
temp_axis(2)=temp_axis(2)+0.1*xspan;
temp_axis(4)=temp_axis(4)+0.1*yspan;



full_list_bs=vertcat(mitigation_union_turn_off_list_data,mitigation_union_mitigation_list_data,on_list_bs);

if all(full_list_bs(:,7)==0)

    %%%'No Sectors'
    scatter(on_list_bs(:,2),on_list_bs(:,1),10,'g','filled')
    scatter(mitigation_union_mitigation_list_data(:,2),mitigation_union_mitigation_list_data(:,1),10,'y','filled')
    scatter(mitigation_union_turn_off_list_data(:,2),mitigation_union_turn_off_list_data(:,1),10,'r','filled')

else
    %on_list_bs
    %mitigation_union_turn_off_list_data
    %mitigation_union_mitigation_list_data%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%So this is where we make a 3 sector pointing marker
    sector_ratio=150
    line_thickness=2
    %%%%%First, find the distance from point to point of map
    map_dia_km=deg2km(distance(temp_axis(3),temp_axis(1),temp_axis(4),temp_axis(2)));

    %%%%Then the sector length is a variable of this distance (1/100)
    sector_length_km=map_dia_km/sector_ratio;

    %%%%%Then make all the lines
    tic;
    sector_miti_data=mitigation_union_mitigation_list_data(:,[1,2,7]); %%%%%%%%%Lat, Lon, Sector
    [cell_sector_miti_lines]=draw_azi_sector_lines_rev1(app,sector_miti_data,sector_length_km);
    toc;

    %%%%%Then make all the lines
    tic;
    sector_off_data=mitigation_union_turn_off_list_data(:,[1,2,7]); %%%%%%%%%Lat, Lon, Sector
    [cell_sector_off_lines]=draw_azi_sector_lines_rev1(app,sector_off_data,sector_length_km);
    toc;

    %%%%%Then make all the lines
    tic;
    sector_on_data=on_list_bs(:,[1,2,7]); %%%%%%%%%Lat, Lon, Sector
    [cell_sector_on_lines]=draw_azi_sector_lines_rev1(app,sector_on_data,sector_length_km);
    toc;


    %%%%%%%%%%%%%%%%%%%%Plot
    tic;
    num_sectors=length(cell_sector_miti_lines);
    for n=1:1:num_sectors
        sector_line=cell_sector_miti_lines{n};
        plot(sector_line(:,2),sector_line(:,1),'-y','Linewidth',line_thickness)
    end
    toc;

    %%%%%%%%%%%%%%%%%%%%Plot
    tic;
    num_sectors=length(cell_sector_off_lines);
    for n=1:1:num_sectors
        sector_line=cell_sector_off_lines{n};
        plot(sector_line(:,2),sector_line(:,1),'-r','Linewidth',line_thickness)
    end
    toc;

    %%%%%%%%%%%%%%%%%%%%Plot
    tic;
    num_sectors=length(cell_sector_on_lines);
    for n=1:1:num_sectors
        sector_line=cell_sector_on_lines{n};
        plot(sector_line(:,2),sector_line(:,1),'-g','Linewidth',line_thickness)
    end
    toc;

    %%%%%%%%%%Replot for the right "layering"
    tic;
    scatter(on_list_bs(:,2),on_list_bs(:,1),1,'k','filled')
    scatter(mitigation_union_mitigation_list_data(:,2),mitigation_union_mitigation_list_data(:,1),1,'k','filled')
    scatter(mitigation_union_turn_off_list_data(:,2),mitigation_union_turn_off_list_data(:,1),1,'k','filled')
end
plot(base_polygon(:,2),base_polygon(:,1),'-b','LineWidth',3)
title({strcat('Max Turn Off Distance:',num2str(max_knn_dist_off),'km'),strcat('Max Mitigation Distance:',num2str(max_knn_dist_miti),'km')})
axis(temp_axis)
plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
toc;
filename1=strcat(data_label1,'_',string_prop_model,'_Off_Mitigation.png');
saveas(gcf,char(filename1))
pause(0.1)
close(f2)

end