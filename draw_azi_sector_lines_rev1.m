function [cell_sector_lines]=draw_azi_sector_lines_rev1(app,sector_data,sector_length_km)

%%%%%%%%%%sector_data
%%%%%1)Lat, 2)Lon, 3)Azimuth pointing

[num_sectors,~]=size(sector_data);
cell_sector_lines=cell(num_sectors,1);
for n=1:1:num_sectors
    [sec_lat,sec_lon]=scircle1(sector_data(n,1),sector_data(n,2),km2deg(sector_length_km),sector_data(n,3),[],[],1);
    cell_sector_lines{n}=vertcat(sector_data(n,[1,2]),horzcat(sec_lat,sec_lon));
end


end