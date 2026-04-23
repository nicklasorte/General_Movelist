function geo_plot_neighborhood_step_rev2(app,base_protection_pts,sim_bound,single_search_dist,on_list_bs,search_dist_bound,inside_idx,union_turn_off_list_data,temp_max_agg,data_label1,cell_sim_data,tf_second_data,sim_folder,temp_max_second_agg)

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


%%%%%%%%%%Find the secondary I/N and Percentiles and the
data_header=cell_sim_data(1,:)';
in1_idx=find(matches(data_header,'in_ratio'));
label_idx=find(matches(data_header,'data_label1'));
row_folder_idx=find(matches(cell_sim_data(:,label_idx),sim_folder));
in_ratio1=cell_sim_data{row_folder_idx,in1_idx};

%%%%%Need the secondary, if they are there
in2_idx=find(matches(data_header,'second_in_ratio'));
per2_idx=find(matches(data_header,'second_mc_percentile'));

threshold_idx=find(matches(data_header,'dpa_threshold'));
radar_threshold=cell_sim_data{row_folder_idx,threshold_idx};


%%%%%%%%%%This is the zero dB shift.
zero_dB=in_ratio1-radar_threshold;
per_first_in=temp_max_agg+zero_dB

if ~isempty(in2_idx)
    in_ratio2=cell_sim_data{row_folder_idx,in2_idx};
else
    in_ratio2=NaN(1,1);
end
if ~isempty(per2_idx)
    per2=cell_sim_data{row_folder_idx,per2_idx};

    %%%%%%Find the second percentile also
    per_second_in=temp_max_second_agg+zero_dB;
else
    per2=NaN(1,1);
    per_second_in=NaN(1,1);
end

if tf_second_data==0
    title(strcat(num2str(single_search_dist),'km--I/N:',num2str(per_first_in)))
elseif tf_second_data==1
    title({strcat(num2str(single_search_dist),'km'),strcat('First I/N:',num2str(per_first_in)), strcat('Second I/N:',num2str(per_second_in))})
end

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