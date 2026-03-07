function plot_neigh_point_dist_rev1(app,base_polygon,catb_dist_data,base_protection_pts,data_label1,CBSD_label,sim_number)


[num_pts,~]=size(base_polygon)
if num_pts>1
    [m_dist,m_idx]=max(catb_dist_data);
    f1=figure;
    geoplot(base_polygon(:,1),base_polygon(:,2),'-k')%%%,'LineWidth',3,'DisplayName','Federal System')
    hold on;
    geoscatter(base_protection_pts(:,1),base_protection_pts(:,2),20,'filled')
    [~,sort_idx]=sort(catb_dist_data,'descend');
    catb_dist_data(isinf(catb_dist_data))=NaN(1);
    if length(catb_dist_data)>10
        geoplot(base_protection_pts(sort_idx(1:10),1),base_protection_pts(sort_idx(1:10),2),'sr','MarkerSize',10,'LineWidth',2)
    end
    geoplot(base_protection_pts(m_idx,1),base_protection_pts(m_idx,2),'ok','MarkerSize',20,'LineWidth',4)
    colormap(jet);
    title({strcat(data_label1),strcat('Neighborhood Distances [km]'),strcat(CBSD_label)})
    c=colorbar;
    c.Label.String='[km]';
    grid on;
    geobasemap streets-light%landcover
    f1.Position = [100 100 1200 900];
    pause(1)
    filename1=strcat(CBSD_label,'_mod_',data_label1,'_DistHeatMap1_',num2str(sim_number),'.png');
    'trying to save . . .'
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
    close(f1)
end

end