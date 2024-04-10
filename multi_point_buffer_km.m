function [bound_buffer]=multi_point_buffer_km(app,base_polygon,buffer_km)


    %Go inland from all points and include those in a bigger polygon to be included for the census tracs polygon
    az=[];
    ellipsoid=[];
    n_pts=50;
    [num_pts,~]=size(base_polygon);
    %%%%%Preallocate
    temp_lat_buff=NaN(n_pts,num_pts);
    temp_lon_buff=NaN(n_pts,num_pts);
    for i=1:1:num_pts
        [temp_lat_buff(:,i), temp_lon_buff(:,i)]=scircle1(base_polygon(i,1),base_polygon(i,2),km2deg(buffer_km),az,ellipsoid,'degrees',n_pts);
    end
    reshape_lat=reshape(temp_lat_buff,[],1);
    reshape_lon=reshape(temp_lon_buff,[],1);    
    con_hull_idx=convhull(reshape_lon,reshape_lat); %%%%%%%%%%%Convex Hull
    bound_buffer=horzcat(reshape_lat(con_hull_idx),reshape_lon(con_hull_idx));

end