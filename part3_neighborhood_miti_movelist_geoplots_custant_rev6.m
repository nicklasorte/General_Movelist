function part3_neighborhood_miti_movelist_geoplots_custant_rev6(app,parallel_flag,rev_folder,workers,move_list_reliability,mc_size,mc_percentile,reliability,norm_aas_zero_elevation_data,string_prop_model,tf_opt,tf_server_status,tf_recalculate,array_mitigation)


[sim_number,folder_names,~]=check_rev_folders(app,rev_folder);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function:
cell_status_filename=strcat('cell_',string_prop_model,'_',num2str(sim_number),'_mitigation_list_status.mat')
label_single_filename=strcat(string_prop_model,'_',num2str(sim_number),'_mitigation_list_status')
checkout_filename=strcat('TF_checkout_',string_prop_model,'_',num2str(sim_number),'_mitigation_list_status.mat')
%location_table=table([1:1:length(folder_names)]',folder_names)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check for the Number of Folders to Sim

%%%%%%%%%%Need a list because going through 470 folders takes 17 minutes
tf_update_cell_status=0;
sim_folder='';  %%%%%Empty sim_folder to not update.
[cell_status]=checkout_cell_status_rev1(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status);


if tf_recalculate==1
    cell_status(:,2)=num2cell(0);
    %%%%%Save the Cell
    retry_save=1;
    while(retry_save==1)
        try
            save(cell_status_filename,'cell_status')
            retry_save=0;
        catch
            retry_save=1;
            pause(2)
        end
    end

end
zero_idx=find(cell2mat(cell_status(:,2))==0);
cell_status

if ~isempty(zero_idx)==1
    temp_folder_names=folder_names(zero_idx)
    num_folders=length(temp_folder_names);

    %%%%%%%%Pick a random folder and go to the folder to do the sim
    disp_progress(app,strcat('Mitigation Move List . . .'))
    reset(RandStream.getGlobalStream,sum(100*clock))  %%%%%%Set the Random Seed to the clock because all compiled apps start with the same random seed.

    [tf_ml_toolbox]=check_ml_toolbox(app);
    if tf_ml_toolbox==1
        array_rand_folder_idx=randsample(num_folders,num_folders,false);
    else
        array_rand_folder_idx=randperm(num_folders);
    end

    temp_folder_names(array_rand_folder_idx)
    disp_randfolder(app,num2str(array_rand_folder_idx'))

    %%%%%%%%%%%%%%%%%%%%%%%%Load the Census Pop Data
    retry_load=1;
    while(retry_load==1)
        try
            load('Cascade_new_full_census_2010.mat','new_full_census_2010')%%%%%%%Geo Id, Center Lat, Center Lon,  NLCD (1-4), Population
            retry_load=0;
        catch
            retry_load=1;
            pause(0.1)
        end
    end
    mid_lat=new_full_census_2010(:,2);
    mid_lon=new_full_census_2010(:,3);
    census_latlon=horzcat(mid_lat,mid_lon);
    census_pop=new_full_census_2010(:,5);
    census_geoid=new_full_census_2010(:,1);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [multi_hWaitbar,multi_hWaitbarMsgQueue]= ParForWaitbarCreateMH_time('Multi-Folder Mitigation: ',num_folders);    %%%%%%% Create ParFor Waitbar

    for folder_idx=1:1:num_folders
        disp_TextArea_PastText(app,strcat('Part3 Mitigation:',num2str(num_folders-folder_idx)))

        %%%%%%%%%%%%%%Check cell_status
        tf_update_cell_status=0;
        sim_folder='';
        [cell_status]=checkout_cell_status_rev1(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status);

        sim_folder=temp_folder_names{array_rand_folder_idx(folder_idx)};
        temp_cell_idx=find(strcmp(cell_status(:,1),sim_folder)==1);
        cell_status{temp_cell_idx,2}

        if cell_status{temp_cell_idx,2}==0
            %%%%%%%%%%Calculate
            retry_cd=1;
            while(retry_cd==1)
                try
                    cd(rev_folder)
                    pause(0.1);
                    retry_cd=0;
                catch
                    retry_cd=1;
                    pause(0.1)
                end
            end

            retry_cd=1;
            while(retry_cd==1)
                try
                    sim_folder=temp_folder_names{array_rand_folder_idx(folder_idx)};
                    cd(sim_folder)
                    pause(0.1);
                    retry_cd=0;
                catch
                    retry_cd=1;
                    pause(0.1)
                end
            end

            disp_multifolder(app,sim_folder)
            data_label1=sim_folder;

            %%%%%%Check for the tf_complete_ITM file
            complete_filename=strcat(data_label1,'_',label_single_filename,'.mat'); %%%This is a marker for me
            [var_exist]=persistent_var_exist_with_corruption(app,complete_filename);
            if tf_recalculate==1
                var_exist=0
            end

            if var_exist==2
                retry_cd=1;
                while(retry_cd==1)
                    try
                        cd(rev_folder)
                        pause(0.1);
                        retry_cd=0;
                    catch
                        retry_cd=1;
                        pause(0.1)
                    end
                end

                %%%%%%%%Update the cell_status
                tf_update_cell_status=1;
                tic;
                [~]=checkout_cell_status_rev1(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status);
                toc;
            else
                retry_load=1;
                while(retry_load==1)
                    try
                        load(strcat(data_label1,'_base_polygon.mat'),'base_polygon')
                        temp_data=base_polygon;
                        clear base_polygon;
                        base_polygon=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_base_protection_pts.mat'),'base_protection_pts')
                        temp_data=base_protection_pts;
                        clear base_protection_pts;
                        base_protection_pts=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_sim_array_list_bs.mat'),'sim_array_list_bs')
                        temp_data=sim_array_list_bs;
                        clear sim_array_list_bs;
                        sim_array_list_bs=temp_data;
                        clear temp_data;
                        % % %      %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation

                        load(strcat(data_label1,'_ant_beamwidth.mat'),'ant_beamwidth')
                        temp_data=ant_beamwidth;
                        clear ant_beamwidth;
                        ant_beamwidth=temp_data;
                        clear temp_data;
                        radar_beamwidth=ant_beamwidth;

                        load(strcat(data_label1,'_min_ant_loss.mat'),'min_ant_loss')
                        temp_data=min_ant_loss;
                        clear min_ant_loss;
                        min_ant_loss=temp_data;
                        clear temp_data;

                        %load(strcat(data_label1,'_radar_threshold.mat'),'radar_threshold')
                        load(strcat(data_label1,'_dpa_threshold.mat'),'dpa_threshold')
                        temp_data=dpa_threshold;
                        clear dpa_threshold;
                        dpa_threshold=temp_data;
                        clear temp_data;
                        radar_threshold=dpa_threshold;

                        load(strcat(data_label1,'_min_azimuth.mat'),'min_azimuth')
                        temp_data=min_azimuth;
                        clear min_azimuth;
                        min_azimuth=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_max_azimuth.mat'),'max_azimuth')
                        temp_data=max_azimuth;
                        clear max_azimuth;
                        max_azimuth=temp_data;
                        clear temp_data;

                        load(strcat(data_label1,'_custom_antenna_pattern.mat'),'custom_antenna_pattern')
                        temp_data=custom_antenna_pattern;
                        clear custom_antenna_pattern;
                        custom_antenna_pattern=temp_data;
                        clear temp_data;

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

                strcat('neighborhood_radius:',num2str(neighborhood_radius))
                %pause;

                % % fig1=figure;
                % % hold on;
                % % plot(custom_antenna_pattern(:,1),custom_antenna_pattern(:,2),'-b')
                % % xlabel('Azimuth [Degree]')
                % % ylabel('Antenna Gain')
                % % grid on;


                %%%%%%%%%%Parpool
                [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                [num_ppts,~]=size(base_protection_pts);

                neighborhood_radius
                num_miti=length(array_mitigation)



                %%%'Need to do the move list, but with cells for each mitigation'
                %%%%%%%%%%First check for the union move list
                %%%%%%%%%First, check to see if the union of the move list exists
                file_name_cell_miti_union=strcat('cell_miti_union_turn_off_list_data_',num2str(num_miti),'_',num2str(neighborhood_radius),'km.mat');  %%%%%%%%%We would only have 1 file? No inputs change this?
                [file_union_move_exist]=persistent_var_exist_with_corruption(app,file_name_cell_miti_union);

                if file_union_move_exist==2
                    retry_load=1;
                    while(retry_load==1)
                        try
                            load(file_name_cell_miti_union,'cell_miti_union')
                            retry_load=0;
                        catch
                            retry_load=1;
                            pause(1)
                        end
                    end
                else %%%%if file_union_move_exist==0 %%%The File Does not exist, we will calculate it

                    % % 'Need to open up pre_sort_movelist_rev12_neigh_cut_azimuths_mitigation_app'
                    % % pause;

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate first-->Parfor --> No data load
                    if parallel_flag==1
                        [poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
                        parfor point_idx=1:num_ppts  %%%%Change to parfor
                            %%%%pre_sort_movelist_rev13_neigh_cut_azimuths_miti_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,array_mitigation,tf_opt,min_azimuth,max_azimuth,neighborhood_radius);
                            pre_sort_movelist_rev21_neigh_cut_azimuths_miti_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,array_mitigation,tf_opt,min_azimuth,max_azimuth,neighborhood_radius,custom_antenna_pattern);
                        end
                    end

                    %%%%%%%%%%%Then for each point, scrap the data and save to excel. Only hold onto 1 point data at a time.
                    %%%%%%%%For this case (1 Monte Carlo Iteration), we really don't need to save most of the data, only the optimized move list order.
                    %%%%%%%%%Keep the move list flexible with the reliability inputs, so we can have multiple move lists.
                    %%%%%%%%%%In the next revision, do the full ITM reliability and do the aggregate check of the 50% ITM with the full 1-99%. (1000 MC and 95th Percentile)

                    server_status_rev2(app,tf_server_status)
                    cell_multi_pt_miti_list=cell(num_ppts,1);
                    for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
                        point_idx
                        %%%%[cell_miti_list]=pre_sort_movelist_rev13_neigh_cut_azimuths_miti_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,array_mitigation,tf_opt,min_azimuth,max_azimuth,neighborhood_radius);
                        [cell_miti_list]=pre_sort_movelist_rev21_neigh_cut_azimuths_miti_app(app,move_list_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,min_ant_loss,radar_threshold,mc_percentile,sim_array_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,array_mitigation,tf_opt,min_azimuth,max_azimuth,neighborhood_radius,custom_antenna_pattern);
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        cell_multi_pt_miti_list{point_idx}=cell_miti_list;
                        cell_miti_list
                    end
                    toc;

                    if num_ppts>1
                        'Need to double check how we merge.'
                        pause;
                    end

                    cell_multi_pt_miti_list




                    %%%%%%%%'Need to find the minimum EIRP, for each unique lat/lon and set that to the EIRP/mitigation'
                    all_miti_list=vertcat(cell_multi_pt_miti_list{:});
                    nan_cols=cell2mat(all_miti_list(:,3));
                    keep_col_idx=find(~isnan(nan_cols)); %%%Remove these from the list.
                    nnan_all_miti_list=all_miti_list(keep_col_idx,:);
                    array_all_list=vertcat(nnan_all_miti_list{:,1})

                    if isempty(array_all_list)
                        cell_miti_union=cell(1,2);
                    else
                        uni_bs_idx=unique(array_all_list(:,5));
                        num_bs=length(uni_bs_idx);
                        [num_all_bs,num_col]=size(sim_array_list_bs);
                        neigh_miti_list_bs=NaN(num_bs,num_col);
                        for i=1:1:num_bs
                            row_idx=find(array_all_list(:,5)==uni_bs_idx(i));
                            if length(row_idx)>1
                                temp_rows_data=array_all_list(row_idx,:);
                                [~,min_idx]=min(temp_rows_data(:,4));
                                neigh_miti_list_bs(i,:)=array_all_list(row_idx(min_idx),:);
                            else
                                neigh_miti_list_bs(i,:)=array_all_list(row_idx,:);
                            end
                        end

                        %%%%%%%%Find the mitigation for each base station
                        [num_miti_bs,~]=size(neigh_miti_list_bs)
                        ind_miti_dB=NaN(num_miti_bs,1); %%%%%%%The individual mitigation applied to the base station
                        for i=1:1:num_miti_bs
                            row_idx=find(sim_array_list_bs(:,5)==neigh_miti_list_bs(i,5));  %%%%%%%ID number
                            ind_miti_dB(i)=sim_array_list_bs(row_idx,4)-neigh_miti_list_bs(i,4); %%%%%%EIRP
                        end

                        %%%%%%%%%%Group by mitigation and put into individual cells
                        uni_miti=unique(ind_miti_dB)
                        num_uni_miti=length(uni_miti)
                        cell_miti_union=cell(num_uni_miti,2); %%%%%%%%%%1) List of the lat/lon and miti off EIRP. 2) Mitigation dB [Off-List]
                        for i=1:1:num_uni_miti
                            rows_match_idx=find(ind_miti_dB==uni_miti(i));
                            cell_miti_union{i,1}=neigh_miti_list_bs(rows_match_idx,:);
                            cell_miti_union{i,2}=uni_miti(i);
                        end
                        cell_miti_union

                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Map the Mitigation Turn-off
                        [num_rows,~]=size(cell_miti_union)
                        color_set=plasma(num_rows);
                        %%%%%%%%%%%%%%%%Original Linear Heat Map Color set
                        f1=figure;
                        for i=1:1:num_rows
                            temp_latlon=cell_miti_union{i,1};
                            geoscatter(temp_latlon(:,1),temp_latlon(:,2),10,color_set(i,:),'filled');
                            hold on;
                        end
                        h = colorbar;
                        ylabel(h, 'Margin [dB]')
                        colorbar_labels=cell2mat(cell_miti_union(:,2))
                        num_labels=length(colorbar_labels)*2+1;
                        cell_bar_label=cell(num_labels,1);
                        counter=0;
                        for miti_idx=2:2:num_labels
                            counter=counter+1;
                            if isnan(colorbar_labels(counter))
                                cell_bar_label{miti_idx}=strcat(num2str(colorbar_labels(counter)));
                            elseif colorbar_labels(counter)>=9999
                                cell_bar_label{miti_idx}=strcat('Off');
                            else
                                cell_bar_label{miti_idx}=strcat(num2str(colorbar_labels(counter)),'dB');
                            end
                        end
                        bar_tics=linspace(0,1,num_labels);
                        h = colorbar('Location','eastoutside','Ticks',bar_tics,'TickLabels',cell_bar_label);
                        colormap(f1,color_set)
                        grid on;
                        title({strcat('Mitigation Turnoff')})
                        pause(0.1)
                        geobasemap streets-light%landcover
                        f1.Position = [100 100 1200 900];
                        pause(1)
                        filename1=strcat('Miti_turnoff_',data_label1,'.png');
                        saveas(gcf,char(filename1))
                        pause(1);
                        close(f1)
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    end

                    retry_save=1;
                    while(retry_save==1)
                        try
                            save(file_name_cell_miti_union,'cell_miti_union')
                            retry_save=0;
                        catch
                            retry_save=1;
                            pause(1)
                        end
                    end
                end


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Find/Plot the Coordination Zones for each reliability
                file_name_cell_bound_miti=strcat('cell_bound_',string_prop_model,'_',num2str(sim_number),'_',data_label1,'.mat');
                [file_cell_bound_miti]=persistent_var_exist_with_corruption(app,file_name_cell_bound_miti);

                if file_cell_bound_miti~=2
                    base_polygon=base_polygon(~isnan(base_polygon(:,1)),:);
                    %%%%%%%If base_polygon is a single point
                    [x41,y41]=size(base_polygon)
                    if x41>1 %%%%%%%Not a single point
                        % tf_cw=ispolycw(base_polygon(:,2),base_polygon(:,1))
                        % if tf_cw==0
                        %     [x_lon,y_lat]=poly2cw(base_polygon(:,2),base_polygon(:,1));
                        %     base_polygon=horzcat(y_lat,x_lon);
                        % end
                        % base_polygon
                        % 'buffering . . .'
                        % tic;
                        % [buff_lat1km,buff_lon1km]=bufferm(base_polygon(:,1),base_polygon(:,2),km2deg(buffer_radius),'out',25);  %%%%1km buff
                        % toc;
                        %
                        % poly1=polyshape(buff_lon1km,buff_lat1km);
                        % poly1 = rmholes(poly1);
                        % neighborhood_bound=fliplr(poly1.Vertices);
                        % neighborhood_bound=vertcat(neighborhood_bound,neighborhood_bound(1,:)); %%%%Close the circle

                        nnan_base_polygon=base_polygon(~isnan(base_polygon(:,1)),:);%%%%%%Remove NaN
                        [neighborhood_bound]=calc_sim_bound(app,nnan_base_polygon,neighborhood_radius,data_label1);
                    else
                        n_pts=50;
                        [temp_esc_lat, temp_esc_lon]=scircle1(base_polygon(1,1),base_polygon(1,2),km2deg(neighborhood_radius),[],[],'degrees',n_pts);
                        k=convhull(temp_esc_lon,temp_esc_lat);
                        esc_lat4=temp_esc_lat(k);
                        esc_lon4=temp_esc_lon(k);
                        neighborhood_bound=[esc_lat4,esc_lon4];
                    end
                    %%%%%%%%%%%The neighborhood bound.
                    cell_neigh=cell(1,2);
                    cell_neigh{1,2}=NaN(1,1);
                    cell_neigh{1,1}=neighborhood_bound;


                    %%%%%%%%Create convex hull and pop impact
                    cell_miti_union=vertcat(cell_neigh,cell_miti_union);
                    [num_miti_rows,~]=size(cell_miti_union);
                    cell_bound_miti=cell(num_miti_rows,10);

                    %%%%%%%%base_polygon
                    for i=1:1:num_miti_rows
                        cell_bound_miti{i,1}=cell_miti_union{i,2}; %%%%%%%%%1)Mitigation
                        if ~isnan(cell_bound_miti{i,1})
                            %temp_pts=cell_miti_union{i,1};  %%%%%make this all the previous points
                            cell_temp_pts=cell_miti_union([i:end],1);  %%%%%make this all the previous points
                            num_cells=length(cell_temp_pts);
                            cell_latlon=cell(num_cells,1);
                            for j=1:1:num_cells
                                temp_latlon=cell_temp_pts{j};
                                cell_latlon{j}=temp_latlon(:,[1,2]);
                            end
                            temp_pts=vertcat(cell_latlon{:});
                            keep_grid_pts=vertcat(base_polygon,temp_pts(:,[1,2]));

                            %%%%%%%%Find the max distance as a check
                            [idx_knn]=knnsearch(base_polygon,keep_grid_pts,'k',1); %%%Find Nearest Neighbor
                            base_knn_array=base_polygon(idx_knn,:);
                            knn_dist_bound=deg2km(distance(base_knn_array(:,1),base_knn_array(:,2),keep_grid_pts(:,1),keep_grid_pts(:,2)));%%%%Calculate Distance
                            max_knn_dist=ceil(max(knn_dist_bound))
                            cell_bound_miti{i,2}=max_knn_dist; %%%Max knn dist


                            %%%%%Convex hull the points
                            bound_idx=boundary(keep_grid_pts(:,2),keep_grid_pts(:,1),0);
                            convex_bound=keep_grid_pts(bound_idx,:);
                            cell_bound_miti{i,3}=convex_bound;
                        else
                            cell_bound_miti{i,2}=neighborhood_radius;
                            cell_bound_miti{i,3}=neighborhood_bound;
                            convex_bound=neighborhood_bound;
                        end
                        cell_bound_miti{i,5}=move_list_reliability;

                        %%%%%%%%%For each contounr, find the pop impact
                        [inside_idx]=find_points_inside_contour_two_step(app,convex_bound,census_latlon);
                        if ~isempty(inside_idx)
                            cell_bound_miti{i,7}=census_geoid(inside_idx);
                            cell_bound_miti{i,8}=sum(census_pop(inside_idx));
                        else
                            cell_bound_miti{i,7}=NaN(1,1);
                            cell_bound_miti{i,8}=0;
                        end

                        if ~isnan(cell_bound_miti{i,1})
                            %%%%%%%%%%%%%%%%Concave
                            %%%%%%Bin for each 1 degree step
                            [num_pp_pts,~]=size(base_polygon)
                            if num_pp_pts>1
                                sim_pt=horzcat(meanm(base_polygon(:,1),base_polygon(:,2)));
                            else
                                sim_pt=base_polygon;
                            end
                            min_dist_km=1;
                            [radial_bound]=radial_bound_rev2(app,sim_pt,keep_grid_pts,min_dist_km);
                            cell_bound_miti{i,6}=radial_bound;

                            %%%%%%%%%For each contounr, find the pop impact
                            [inside_idx]=find_points_inside_contour_two_step(app,radial_bound,census_latlon);
                            if ~isempty(inside_idx)
                                cell_bound_miti{i,9}=census_geoid(inside_idx);
                                cell_bound_miti{i,10}=sum(census_pop(inside_idx));
                            else
                                cell_bound_miti{i,9}=NaN(1,1);
                                cell_bound_miti{i,10}=0;
                            end
                        else
                            cell_bound_miti{i,6}=NaN(1,1);
                            cell_bound_miti{i,9}=NaN(1,1);
                            cell_bound_miti{i,10}=0;
                        end


                    end
                    cell_bound_miti

                    % % % 'Need to calculate the convexhull of each EIRP in the neigh_miti_list_bs: This is the off list.'
                    % % % 'Then find the pop impact of each mitigation zone'
                    % % % 'Put it into the data format for the pea/pop impact section'

                    %%%%%%%%Map it
                    cell_multi_con=cell_bound_miti(:,[1,3])
                    filename_bugsplat=strcat('Convex_Multi_Bound_Contours_',sim_folder,'.png');
                    title_str=strcat('Convex Multi-Contours:',sim_folder);
                    map_multi_contours_rev1(app,cell_multi_con,title_str,filename_bugsplat)


                    %%%%%%%%%%%This is the data we are putting it into

                    %%%%1)Mitigation,
                    % %%2) Max knn dist,
                    % %%3)Convex Bound,
                    % %%4)Max Interference dB,
                    % %%%5)Prop Reliability
                    %%%%%6)Radial Bound
                    %%%%%7)Convex GeoId,
                    %%%%%8)Convex Total Pop
                    %%%%%9)Concave GeoId,
                    %%%%%10)Concave Total Pop


                    %%%%%%%%%%Save
                    retry_save=1;
                    while(retry_save==1)
                        try
                            save(file_name_cell_bound_miti,'cell_bound_miti')
                            pause(0.1);
                            retry_save=0;
                        catch
                            retry_save=1;
                            pause(0.1)
                        end
                    end
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%Save
                retry_save=1;
                while(retry_save==1)
                    try
                        comp_list=NaN(1);
                        save(complete_filename,'comp_list')
                        pause(0.1);
                        retry_save=0;
                    catch
                        retry_save=1;
                        pause(0.1)
                    end
                end

                retry_cd=1;
                while(retry_cd==1)
                    try
                        cd(rev_folder)
                        pause(0.1);
                        retry_cd=0;
                    catch
                        retry_cd=1;
                        pause(0.1)
                    end
                end
                %[~]=update_generic_status_cell_rev1(app,folder_names,sim_folder,cell_status_filename);
                %%%%%%%%Update the cell_status
                tf_update_cell_status=1;
                tic;
                [~]=checkout_cell_status_rev1(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status);
                toc;
                %%%server_status_rev1(app)
                server_status_rev2(app,tf_server_status)
            end
        end
        multi_hWaitbarMsgQueue.send(0);
    end
    delete(multi_hWaitbarMsgQueue);
    close(multi_hWaitbar);
    finish_cell_status_rev1(app,rev_folder,cell_status_filename)
end
server_status_rev2(app,tf_server_status)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
