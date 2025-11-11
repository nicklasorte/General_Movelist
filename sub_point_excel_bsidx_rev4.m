function []=sub_point_excel_bsidx_rev4(app,point_idx,data_label1,union_turn_off_list_data,base_protection_pts,sim_array_list_bs,string_prop_model,sim_number,norm_aas_zero_elevation_data,radar_beamwidth,min_azimuth,max_azimuth,move_list_reliability,sim_radius_km,custom_antenna_pattern,dpa_threshold,neighborhood_radius)

%%%%%%Load all the pathloss data
%%%%%%%%%'Load all the point pathloss calculations'
%%%%%%Persistent Load
file_name_pathloss=strcat(string_prop_model,'_pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
retry_load=1;
while(retry_load==1)
    try
        load(file_name_pathloss,'pathloss')
        retry_load=0;
    catch
        retry_load=1;
        'Having trouble loading pathloss . . .'
        pause(1)
    end
end

%%%%%%%Calculate Distance
sim_pt=base_protection_pts(point_idx,:);
bs_distance_km=deg2km(distance(sim_pt(1),sim_pt(2),sim_array_list_bs(:,1),sim_array_list_bs(:,2)));

[bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,sim_array_list_bs,norm_aas_zero_elevation_data);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'Calculate the antenna gain at Rx'
%%%%%%%%%%%%%%%%Calculate the simualation azimuths
[array_sim_azimuth,num_sim_azi]=calc_sim_azimuths_rev3_360_azimuths_app(app,radar_beamwidth,min_azimuth,max_azimuth);
% % if num_sim_azi>1
% %     'Need to expand the spreadsheet for multiple rx antenna rotations'
% %     pause;
% % end

% figure;
% hold on;
% histogram(bs_azi_gain)
% grid on;
% pause(0.1)
% 'check histogram'
% pause;


[mid_idx]=nearestpoint_app(app,50,move_list_reliability);
mid_pathloss_dB=pathloss(:,mid_idx);
temp_pr_dbm=sim_array_list_bs(:,4)-mid_pathloss_dB+bs_azi_gain;  %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System
%%%%%%Need to do it twice, once for the sim
%%%%%%distance and another for the neighbohrood
%%%%%%distance (neighborhood_radius)


%%%%'We could do a new one with all the sim_array_list_bs'
single_search_dist=sim_radius_km+1  %%%%Not the real distance, but it should never have one this size. %%%%%%%%%%%%%%'single_search_dist is only used for a file name'

%%%%%%%%First for the sim_radius_km
tf_calc_opt_sort=0%1%0%1%0  %%%%%%%Load if it's been calculated before
%%%%[opt_sort_bs_idx,array_max_agg]=near_opt_sort_idx_string_prop_model_custant_rev4_agg_output(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,sim_radius_km,sim_array_list_bs,base_protection_pts,temp_pr_dbm,string_prop_model,custom_antenna_pattern,min_azimuth,max_azimuth);
[opt_sort_bs_idx,array_max_agg,array_uuid]=near_opt_sort_idx_rev5(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,single_search_dist,sim_array_list_bs,base_protection_pts,temp_pr_dbm,string_prop_model,custom_antenna_pattern,min_azimuth,max_azimuth);


[num_all_tx,~]=size(sim_array_list_bs)
num_agg=length(array_max_agg)
if num_all_tx~=num_agg %%'check to make sure they are the same size'
    'Error in size mismath: sub_point_excel_rev3'
    pause;
end



% % opt_sort_bs_idx(1:10)
% % 'check ids'
% % pause;


% % figure;
% % hold on;
% % plot(array_max_agg,'-ok')
% % grid on;
% % pause(0.1)

delta_agg=diff(array_max_agg);
if max(delta_agg)>0
    'Not optimum'
    pause;
end

% figure;
% hold on;
% plot(delta_agg,'-ok')
% grid on;
% pause(0.1)


[num_tx,~]=size(sim_array_list_bs)
full_array_off_axis_gain=NaN(num_tx,num_sim_azi);
for azimuth_idx=1:1:num_sim_azi
    %%%Find CBSD azimuths outside of +/- of half_ant_hor_deg of temp_azimuth
    sim_azimuth=array_sim_azimuth(azimuth_idx);
    circshift_antpat=custom_antenna_pattern;
    circshift_antpat(:,1)=custom_antenna_pattern(:,1)+sim_azimuth; %%%%%%%Add the azimuth, then we don't have to worry about azimuth spacing on pattern
    %%%%Then Mod
    mod_ant_pat=mod(circshift_antpat(:,1),360);
    circshift_antpat(:,1)=mod_ant_pat;

    %%%%%%Now find the 0
    nn_zero_azi_idx=nearestpoint_app(app,0,circshift_antpat(:,1));
    [num_ele,~]=size(circshift_antpat);
    shift_antpat=circshift(circshift_antpat,num_ele-nn_zero_azi_idx+1);
    shift_antpat=table2array(unique(array2table(shift_antpat),'rows')); %%%%%%Only keep unique azimuth rows

    %%%%%%Test to make sure 0 is first in array
    nn_check_idx=nearestpoint_app(app,0,shift_antpat(:,1));
    if nn_check_idx~=1
        'Circ shift error'
        pause;
    end

    bs_azimuth=azimuth(sim_pt(1),sim_pt(2),sim_array_list_bs(:,1),sim_array_list_bs(:,2));
    [ant_deg_idx]=nearestpoint_app(app,bs_azimuth,shift_antpat(:,1));
    off_axis_gain=shift_antpat(ant_deg_idx,2);
    full_array_off_axis_gain(:,azimuth_idx)=off_axis_gain;
end

size(full_array_off_axis_gain)
max_off_axis_gain=max(full_array_off_axis_gain,[],2);
size(max_off_axis_gain)

% % % figure;
% % % hold on;
% % % plot(max_off_axis_gain)
% % % grid on;

%%%%%%%%%%%%%%%%%%%%%Calculate Power Received;
%array_rx_pwr=sim_array_list_bs(:,4)-pathloss+off_axis_gain+bs_azi_gain;
max_array_rx_pwr=sim_array_list_bs(:,4)-mid_pathloss_dB+max_off_axis_gain+bs_azi_gain;
% horzcat(array_rx_pwr(1:10),sim_array_list_bs(1:10,4),pathloss(1:10),off_axis_gain(1:10),bs_azi_gain(1:10))
% 'check'
% pause;

              % % %      %%%%sim_array_list_bs  
                %%%%%%%1) Lat, 
                % %%%%%2)Lon, 
                % %%%%%3)BS height, 
                % %%%%%4)BS EIRP Adjusted 
                % %%%%%5) Nick Unique ID for each sector, 
                % %%%%%6)NLCD: R==1/S==2/U==3, 
                % %%%%%7) Azimuth 
                % %%%%%8)BS EIRP Mitigation

%%%%%%%%%%Make a table:
% %%%%%%%%1) Uni_Id
% %%%%%%%%2) BS_Latitude_DD
% %%%%%%%%3) BS_Longitude_DD
% %%%%%%%%4) BS_Height_m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Add azimuth 5)
% %%%%%%%%6) Fed_Latitude_DD
% %%%%%%%%7) Fed_Longitude_DD
% %%%%%%%%8) Fed_Height_m
% %%%%%%%%9) Max_BS_EIRP_dBm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Add bs_azi_gain
%%%%%%%%%%10)--> 11 Path_Loss_dB
%%%%%%%%%11)-->12 Distance km
%%%%%%%%%12)-->13 Rx Ant Gain (dBi)
%%%%%%%%%13)-->14 Power Received dBm
%%%%%%%%%14)-->15 TF_off
%%%%%%%%%15)-->16 Aggregate
%%%%%%%%%%%%17) DPA Threshold

array_excel_data=horzcat(sim_array_list_bs(:,5),sim_array_list_bs(:,[1,2,3]),sim_array_list_bs(:,[7]),sim_pt.*ones(num_tx,1),sim_array_list_bs(:,[4]),bs_azi_gain,mid_pathloss_dB,bs_distance_km,max_off_axis_gain,max_array_rx_pwr);
array_excel_data(:,15)=0;  %%%%%TF Off
array_excel_data(1:10,:)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Can still use opt_sort_bs_idx since we are doing if for all the transmitters
sort_array_excel_data=array_excel_data(opt_sort_bs_idx,:);
sort_array_excel_data(:,16)=array_max_agg; %%%%%%%%%Aggregate

%%%%%%%%%%Now find the turnoff
if isnan(union_turn_off_list_data(1,5))
    bs_turnoff_idx=NaN(1,1);
    bs_turnoff_idx=bs_turnoff_idx(~isnan(bs_turnoff_idx));
else
    bs_turnoff_idx=union_turn_off_list_data(:,5);
end
nn_off_idx=nearestpoint_app(app,bs_turnoff_idx,sort_array_excel_data(:,1));
sort_nn_off_idx=sort(nn_off_idx);  %%%%%%%%%%%%%%%%%%%%%We don't need this sort, but I like to see them sequentially.
sort_array_excel_data(sort_nn_off_idx,15)=1; %%%%TF Off
sort_array_excel_data(1:10,:)
sort_array_excel_data(:,17)=dpa_threshold;%%%%.*ones(num_tx,1)
full_excel_data=sort_array_excel_data;

table_excel_data=array2table(full_excel_data);
table_excel_data.Properties.VariableNames={'Uni_Id' 'BS_Latitude_DD' 'BS_Longitude_DD' 'BS_Height_m' 'BS_Azi' 'Fed_Latitude_DD' 'Fed_Longitude_DD' 'Fed_Height_m' 'Max_BS_EIRP_dBm' 'BS_ant_azi_dB' 'Path_Loss_dB' 'Distance_km' 'Max_Rx_Ant_Gain' 'Max_Rx_Pwr'  'TF_off' 'Aggregate_dBm'  'Interference_Threshold'}
disp_progress(app,strcat('Writing Excel File . . . '))
tic;
retry_save=1;
while(retry_save==1)
    try
        writetable(table_excel_data,strcat('FULL_',data_label1,'_Point',num2str(point_idx),'_',string_prop_model,'_Rev',num2str(sim_number),'.xlsx'));
        pause(0.1);
        retry_save=0;
    catch
        retry_save=1;
        pause(0.1)
    end
end
toc;  %%%%%%A few seconds
%%%%%%%%%%%%%%%%%%%%%%This full excel seems to be working.



%%%%%%%%%%%%%%%%%%Now cut all that are outside the neighborhood
keep_idx=find(bs_distance_km<=neighborhood_radius);
keep_sim_array_list_bs=sim_array_list_bs(keep_idx,:);
keep_temp_pr_dbm=temp_pr_dbm(keep_idx,:);
%%%keep_bs_azi_gain=bs_azi_gain(keep_idx);


%%%%%%%%First for the neighborhood_radius
%%%%Need this input: sim_array_list_bs, temp_pr_dbm
neighborhood_radius
tf_calc_opt_sort=0%1%0%1%0  %%%%%%%Load if it's been calculated before
%[neigh_opt_sort_bs_idx,neigh_array_max_agg]=near_opt_sort_idx_string_prop_model_custant_rev4_agg_output(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,neighborhood_radius,keep_sim_array_list_bs,base_protection_pts,keep_temp_pr_dbm,string_prop_model,custom_antenna_pattern,min_azimuth,max_azimuth);
[~,neigh_array_max_agg,neigh_array_uuid]=near_opt_sort_idx_rev5(app,data_label1,point_idx,tf_calc_opt_sort,radar_beamwidth,neighborhood_radius,keep_sim_array_list_bs,base_protection_pts,keep_temp_pr_dbm,string_prop_model,custom_antenna_pattern,min_azimuth,max_azimuth);


[num_keep_tx,~]=size(keep_sim_array_list_bs)
num_nei_agg=length(neigh_array_uuid)
if num_keep_tx~=num_nei_agg %%'check to make sure they are the same size'
    'Error in size mismath: sub_point_excel_rev3'
    pause;
end


% % % neigh_opt_sort_bs_idx(1:50)
% % % 'check point ids'
% % % pause;

% figure;
% hold on;
% plot(neigh_array_max_agg,'-ok')
% grid on;
% pause(0.1)
%
% delta_agg=diff(neigh_array_max_agg);
% if max(delta_agg)>0
%     'Not optimum'
%     pause;
% end


%%%%%%%%%%Make a table:
% %%%%%%%%1) Uni_Id
% %%%%%%%%2) BS_Latitude_DD
% %%%%%%%%3) BS_Longitude_DD
% %%%%%%%%4) BS_Height_m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Add azimuth 5)
% %%%%%%%%6) Fed_Latitude_DD
% %%%%%%%%7) Fed_Longitude_DD
% %%%%%%%%8) Fed_Height_m
% %%%%%%%%9) Max_BS_EIRP_dBm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Add bs_azi_gain
%%%%%%%%%%10)--> 11 Path_Loss_dB
%%%%%%%%%11)-->12 Distance km
%%%%%%%%%12)-->13 Rx Ant Gain (dBi)
%%%%%%%%%13)-->14 Power Received dBm
%%%%%%%%%14)-->15 TF_off
%%%%%%%%%15)-->16 Aggregate
%%%%%%%%%%%%17) DPA Threshold

keep_array_excel_data=horzcat(keep_sim_array_list_bs(:,5),keep_sim_array_list_bs(:,[1,2,3]),keep_sim_array_list_bs(:,7),sim_pt.*ones(length(keep_idx),1),keep_sim_array_list_bs(:,[4]),bs_azi_gain(keep_idx),mid_pathloss_dB(keep_idx),bs_distance_km(keep_idx),max_off_axis_gain(keep_idx),max_array_rx_pwr(keep_idx));
keep_array_excel_data(:,15)=0;  %%%TF Off

%%%%%%%%%Find the neighborhood uuid in the keep_array_excel_data

%%%%%%'instead of using neigh_opt_sort_bs_idx, we need to find the idx based on the neigh_array_uuid'
nn_neigh_uuid_idx=nearestpoint_app(app,neigh_array_uuid,keep_array_excel_data(:,1))
sort_nn_neigh_uuid_idx=sort(nn_neigh_uuid_idx)  %%%%%%%%%%%%%%%%%%%%%We don't need this sort, but I like to see them sequentially.

%%%% sort_keep_array_excel_data=keep_array_excel_data(neigh_opt_sort_bs_idx,:);
sort_keep_array_excel_data=keep_array_excel_data(nn_neigh_uuid_idx,:);
sort_keep_array_excel_data(:,16)=neigh_array_max_agg;  %%%%%%But this is sorted.  Aggregate


%%%%%%%%%%Now find the turnoff
if isnan(union_turn_off_list_data(1,5))
    bs_turnoff_idx=NaN(1,1);
    bs_turnoff_idx=bs_turnoff_idx(~isnan(bs_turnoff_idx));
else
    bs_turnoff_idx=union_turn_off_list_data(:,5);
end
keep_nn_off_idx=nearestpoint_app(app,bs_turnoff_idx,sort_keep_array_excel_data(:,1));
sort_keep_nn_off_idx=sort(keep_nn_off_idx);  %%%%%%%%%%%%%%%%%%%%%We don't need this sort, but I like to see them sequentially.
sort_keep_array_excel_data(sort_keep_nn_off_idx,15)=1;  %%%%%TF Off
sort_keep_array_excel_data(:,17)=dpa_threshold;%%%%.*ones(num_tx,1) %%%%%%%%%DPA Threshold
keep_full_excel_data=sort_keep_array_excel_data;


table_excel_keep_data=array2table(keep_full_excel_data);
table_excel_keep_data.Properties.VariableNames={'Uni_Id' 'BS_Latitude_DD' 'BS_Longitude_DD' 'BS_Height_m' 'BS_Azi' 'Fed_Latitude_DD' 'Fed_Longitude_DD' 'Fed_Height_m' 'Max_BS_EIRP_dBm' 'BS_ant_azi_dB' 'Path_Loss_dB' 'Distance_km' 'Max_Rx_Ant_Gain' 'Max_Rx_Pwr'  'TF_off' 'Aggregate_dBm'  'Interference_Threshold'}
disp_progress(app,strcat('Writing Excel File . . . '))
tic;
retry_save=1;
while(retry_save==1)
    try
        writetable(table_excel_keep_data,strcat('Neighborhood_',data_label1,'_Point',num2str(point_idx),'_',string_prop_model,'_Rev',num2str(sim_number),'.xlsx'));
        pause(0.1);
        retry_save=0;
    catch
        retry_save=1;
        pause(0.1)
    end
end
toc;  %%%%%%A few seconds


end

