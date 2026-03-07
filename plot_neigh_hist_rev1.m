function plot_neigh_hist_rev1(app,catb_dist_data,data_label1,CBSD_label,sim_number)

num_bins=ceil((ceil(max(catb_dist_data))-floor(min(catb_dist_data)))/10)+1;
if ~isnan(num_bins)==1
    fig1=figure;
    hold on;
    histogram(catb_dist_data,'Normalization','probability','NumBins',num_bins)
    line([max(catb_dist_data),max(catb_dist_data)],[min(ylim),max(ylim)],'Color','k','LineWidth',4)
    xlabel('Neighborhood Distance [km]')
    ylabel('Probability')
    grid on;
    title({strcat(data_label1,': Histogram: Neighborhood Distance'),strcat('Neighborhood Distance:',num2str(max(catb_dist_data)),'km'),strcat(CBSD_label)})
    filename1=strcat(CBSD_label,'_mod_',data_label1,'Histogram_CatB_Dist',num2str(sim_number),'.png');
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
end