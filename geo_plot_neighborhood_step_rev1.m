function geo_plot_neighborhood_step_rev1(app,base_protection_pts,sim_bound,single_search_dist,on_list_bs,search_dist_bound,inside_idx,union_turn_off_list_data,temp_max_agg,data_label1)

f1=figure;
geoplot(base_protection_pts(:,1),base_protection_pts(:,2),'xk','LineWidth',3,'DisplayName','Federal System')
hold on;
geoplot(sim_bound(:,1),sim_bound(:,2),'--','Color','b','LineWidth',3,'DisplayName',strcat(num2str(single_search_dist),'km'))
if single_search_dist>0
    geoplot(search_dist_bound(:,1),search_dist_bound(:,2),'-','Color',[255/256 51/256 255/256] ,'LineWidth',3,'DisplayName',strcat(num2str(single_search_dist),'km'))
end
geoscatter(on_list_bs(:,1),on_list_bs(:,2),1,'b','filled')
if single_search_dist>0
    geoscatter(on_list_bs(inside_idx,1),on_list_bs(inside_idx,2),2,'g','filled')
end
if ~isempty(union_turn_off_list_data)
    geoscatter(union_turn_off_list_data(:,1),union_turn_off_list_data(:,2),3,'r','filled')
end
grid on;
geoplot(base_protection_pts(:,1),base_protection_pts(:,2),'xk','LineWidth',3,'DisplayName','Federal System')
title(strcat(num2str(single_search_dist),'km--Maximum Aggregate:',num2str(temp_max_agg)))
pause(0.1)
geobasemap streets-light%landcover
f1.Position = [100 100 1200 900];
pause(1)
filename1=strcat('SearchDist_',data_label1,'_',num2str(single_search_dist),'km.png');
retry_save=1;
while(retry_save==1)
    try
        saveas(gcf,char(filename1))
        retry_save=0;
    catch
        retry_save=1;
        pause(1)
    end
end
pause(0.1);
close(f1)
end