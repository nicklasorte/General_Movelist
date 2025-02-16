function [sim_bound]=calc_sim_bound(app,base_polygon,sim_radius_km,data_label1)


    %Go inland from all points and include those in a bigger polygon to be included for the census tracs polygon
    az=[];
    ellipsoid=[];
    n_pts=50;
    [num_pts,~]=size(base_polygon);
    nnan_idx=find(~isnan(base_polygon(:,1)));
    base_polygon=base_polygon(nnan_idx,:);
    %%%%%Preallocate
    temp_lat_buff=NaN(n_pts,num_pts);
    temp_lon_buff=NaN(n_pts,num_pts);
    for i=1:1:num_pts
        [temp_lat_buff(:,i), temp_lon_buff(:,i)]=scircle1(base_polygon(i,1),base_polygon(i,2),km2deg(sim_radius_km),az,ellipsoid,'degrees',n_pts);
    end
    reshape_lat=reshape(temp_lat_buff,[],1);
    reshape_lon=reshape(temp_lon_buff,[],1);    
    con_hull_idx=convhull(reshape_lon,reshape_lat); %%%%%%%%%%%Convex Hull
    sim_bound=horzcat(reshape_lat(con_hull_idx),reshape_lon(con_hull_idx));


%     close all;
%     figure;
%     hold on;
%     plot(base_polygon(:,2),base_polygon(:,1),'-ob')
%     plot(sim_bound(:,2),sim_bound(:,1),'-r')
%     grid on;
%     plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
%     filename1=strcat('Sim_Area_',data_label1,'.png');
%     pause(0.1)
%     %saveas(gcf,char(filename1))


end