function plot_stacked_bar_on_off_miti_rev1(app,knn_dist_bound_off,knn_dist_bound_miti,knn_dist_bound_on,data_label1,string_prop_model)




max_knn_dist_off=ceil(max(knn_dist_bound_off));
max_knn_dist_miti=ceil(max(knn_dist_bound_miti));
max_knn_dist_on=ceil(max(knn_dist_bound_on));
max_dist=max(horzcat(max_knn_dist_off,max_knn_dist_miti,max_knn_dist_on));
%%%%%%%%%%
bin_edges=0:1:max_dist;
center_bin=(bin_edges(2:end)-bin_edges(1:end-1))/2+(bin_edges(1:end-1));
[counts_off,~]=histcounts(knn_dist_bound_off,bin_edges);
[counts_miti,~]=histcounts(knn_dist_bound_miti,bin_edges);
[counts_on,~]=histcounts(knn_dist_bound_on,bin_edges);
all_counts = counts_off + counts_miti+ counts_on;
f3=figure;
hold on;
bar(center_bin, all_counts, 'g')
bar(center_bin, counts_miti, 'y')
bar(center_bin, counts_off, 'r')
hold off
legend('On', 'Miti', 'Off')
grid on;
title({strcat('Histogram')})
xlabel('Distance km')
ylabel('Number of Sectors')
filename1=strcat(data_label1,'_',string_prop_model,'_StackedBar.png');
saveas(gcf,char(filename1))
pause(0.1)
close(f3)

end