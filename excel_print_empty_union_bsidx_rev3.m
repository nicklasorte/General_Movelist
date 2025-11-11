function excel_print_empty_union_bsidx_rev3(app,tf_print_excel,reliability,data_label1,mc_size,base_protection_pts,sim_array_list_bs,string_prop_model,sim_number,norm_aas_zero_elevation_data,radar_beamwidth,min_azimuth,max_azimuth,move_list_reliability,sim_radius_km,custom_antenna_pattern,dpa_threshold)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Before we mark it complete, print the excel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if tf_print_excel==1
    % num_rel=length(reliability)
    % if num_rel>1
    %     'Need to update this with multiple reliabilities'
    %     pause;
    % end

    %%%%%%%%%%%%Pull the neighborhood radius--> Union Move list --> Pathloss --> Excel
    retry_load=1;
    while(retry_load==1)
        try
            CBSD_label='BaseStation';
            load(strcat(CBSD_label,'_',data_label1,'_catb_neighborhood_radius.mat'),'catb_neighborhood_radius')
            temp_data=catb_neighborhood_radius;
            clear catb_neighborhood_radius;
            neighborhood_radius=temp_data;
            clear temp_data;

            retry_load=0;
        catch
            retry_load=1;
            pause(0.1)
        end
    end

    file_name_union_move=strcat(CBSD_label,'_union_turn_off_list_data_',num2str(mc_size),'_',num2str(neighborhood_radius),'km.mat');
    [file_union_move_exist]=persistent_var_exist_with_corruption(app,file_name_union_move);
    if file_union_move_exist==2
        disp_progress(app,strcat('Neighborhood Calc Rev1: Line 237: Loading Union:',num2str(neighborhood_radius),'km'))
        retry_load=1;
        while(retry_load==1)
            try
                load(file_name_union_move,'union_turn_off_list_data')
                retry_load=0;
            catch
                retry_load=1;
                pause(1)
            end
        end
    else
        union_turn_off_list_data=NaN(1,5);
        'Error: NO Union turn off list'
        %pause;
    end
    neighborhood_radius

    sort(union_turn_off_list_data(:,5))
    % % 'check ids'
    % % pause;


    %%%Export the pathloss data, 1 sheet for each point
    [num_sim_pts,~]=size(base_protection_pts)
    [num_tx,~]=size(sim_array_list_bs);
    for point_idx=1:1:num_sim_pts
        %%%%%%sub_point_excel_rev3(app,point_idx,data_label1,union_turn_off_list_data,base_protection_pts,sim_array_list_bs,string_prop_model,sim_number,norm_aas_zero_elevation_data,radar_beamwidth,min_azimuth,max_azimuth,move_list_reliability,sim_radius_km,custom_antenna_pattern,dpa_threshold,neighborhood_radius)
        sub_point_excel_bsidx_rev4(app,point_idx,data_label1,union_turn_off_list_data,base_protection_pts,sim_array_list_bs,string_prop_model,sim_number,norm_aas_zero_elevation_data,radar_beamwidth,min_azimuth,max_azimuth,move_list_reliability,sim_radius_km,custom_antenna_pattern,dpa_threshold,neighborhood_radius)
    end
end

end