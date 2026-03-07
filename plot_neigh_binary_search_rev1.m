function plot_neigh_binary_search_rev1(app,catb_dist_data,all_data_stats_binary,radar_threshold,margin,data_label1,CBSD_label,sim_number)

%%%Find Max Distance and Look at Individual Plot
[~,point_idx]=max(catb_dist_data);
fig1=figure;
hold on;
full_stats_catb=all_data_stats_binary{point_idx};
plot(full_stats_catb(:,1),full_stats_catb(:,2),'-sk')
above_idx=find(full_stats_catb(:,2)>(radar_threshold+margin))
line([min(xlim),max(xlim)],[radar_threshold,radar_threshold],'Color','r','LineWidth',2)
fill([min(xlim),max(xlim),max(xlim),min(xlim),min(xlim)],[radar_threshold+margin,radar_threshold+margin,min(ylim),min(ylim),radar_threshold+margin],'g','FaceAlpha',0.25)
line([min(xlim),max(xlim)],[radar_threshold,radar_threshold],'Color','r','LineWidth',2)
line([catb_dist_data(point_idx),catb_dist_data(point_idx)],[min(ylim),max(ylim)],'Color','b','LineWidth',2)
plot(full_stats_catb(above_idx,1),full_stats_catb(above_idx,2),'xr','LineWidth',3)
grid on;
grid on;
ylabel('Aggregate Interference [dBm]')
xlabel('Neighborhood Distance')
title({strcat(data_label1,':',num2str(point_idx)),strcat('Neighborhood:',num2str(catb_dist_data(point_idx)),'km'),strcat(CBSD_label)})
filename1=strcat(CBSD_label,'_mod_',data_label1,'_SinglePoint_',num2str(sim_number),'_',num2str(point_idx),'.png');
retry_save=1;
while(retry_save==1)
    try
        saveas(gcf,char(filename1))
        pause(0.1);
        retry_save=0;
    catch
        retry_save=1;
        pause(0.1)
    end
end
pause(0.1)
close(fig1)
end