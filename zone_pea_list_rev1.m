function zone_pea_list_rev1(app,convex_label,sim_number,reliability,cell_convex_zones)


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Census Population Impact
    %%%%%%%%%%%%%%%%%%%%%%%%Load the Census Pop Data
    retry_load=1;
    while(retry_load==1)
        try
            %%%%load('Cascade_new_full_census_2010.mat','new_full_census_2010')%%%%%%%Geo Id, Center Lat, Center Lon,  NLCD (1-4), Population
            load('Cascade_new_full_census_2023_UA.mat','new_full_census_2020')%%%%%%%1) %%%%%%%1) Geo Id, 2) Center Lat, 3) Center Lon,  4) Population 5)UA Number
            retry_load=0;
        catch
            'census load fail'
            retry_load=1;
            pause(0.1)
        end
    end
    % array_geo_idx=new_full_census_2010(:,1);
    % mid_lat=new_full_census_2010(:,2);
    % mid_lon=new_full_census_2010(:,3);
    array_geo_idx=new_full_census_2020(:,1);
    mid_lat=new_full_census_2020(:,2);
    mid_lon=new_full_census_2020(:,3);
    array_pop=new_full_census_2020(:,4);
    points_latlon=horzcat(mid_lat,mid_lon);

    [num_zones,~]=size(cell_convex_zones);
    tic;
    cell_census_geo=cell(num_zones,3); %%%%%1)Name, 2)Geo IDx, 3) Pop
    for zone_idx=1:1:num_zones
        temp_cell_data=cell_convex_zones{zone_idx,2};
        temp_zone=temp_cell_data{1,2};
        temp_poly = polyshape(temp_zone(:,2),temp_zone(:,1));
        %%%Make it polyshape
        %%%%%%%%%%Population Impact (idx) and then total pop
        %%%%%%%%Find the geo_id for each census tract, population, and NLCD value
        [inside_idx]=find_points_inside_contour_two_step(app,temp_zone,points_latlon);
        if ~isempty(inside_idx)
            cell_census_geo{zone_idx,1}=cell_convex_zones{zone_idx,1};
            cell_census_geo{zone_idx,2}=array_geo_idx(inside_idx);
            cell_census_geo{zone_idx,3}=sum(array_pop(inside_idx));
        end
    end
    toc;
    cell_census_geo=cell_census_geo(~cellfun('isempty',cell_census_geo(:,1)),:)

    %%%%%%%Find the PEA impacted per zone and UA
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%PEA Table
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    retry_load=1;
    while(retry_load==1)
        try
            %%%%%%%%%%load('cell_pea_census_data.mat','cell_pea_census_data')
            load('cell_pea_census_data_2020_2023.mat','cell_pea_census_data_2020')%%%%%%%%Using the 2023 Census Tracts)
            pause(0.1)
            retry_load=0;
        catch
            retry_load=1
            pause(1)
        end
    end

    cell_pea_census_data=cell_pea_census_data_2020;

    %load('cell_pea_census_data_2020.mat','cell_pea_census_data_2020')%
    %%%%%1)PEA Name, 2)PEA Num, 3)PEA {Lat/Lon}, 4)PEA Pop 2020, 5)PEA Centroid, 6)Census {Geo ID}, 7)Census{Population}, 8)Census{NLCD}, 9)Census Centroid

    %load('cell_pea_census_data.mat','cell_pea_census_data')
    %%%%%1)PEA Name, 2)PEA Num, 3)PEA {Lat/Lon}, 4)PEA Pop, 5)PEA Centroid, 6)Census {Geo ID}, 7)Census{Population}, 8)Census{NLCD}, 9)Census Centroid


    cell_census_geo


    [num_zones2,~]=size(cell_census_geo)
    [num_peas,~]=size(cell_pea_census_data)

    cell_pea_zone=cell(num_peas,3);%%%1)Name of the PEA, 2) PEA  Number, 3) Name of the  Zones
    tic;
    for pea_idx=1:1:num_peas
        %%%%%%%%%%%%%%For each PEA, check to see which
        round((pea_idx/num_peas)*100)
        pea_census_geo_idx=cell_pea_census_data{pea_idx,6};

        temp_cell_pea_holder=cell(num_zones2,1);
        for area_idx=1:num_zones2
            temp_census_geo_idx=cell_census_geo{area_idx,2};

            % Vectorized replacement for the loop
            match_mask=ismember(pea_census_geo_idx, temp_census_geo_idx);
            temp_match_idx=find(match_mask);

            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % temp_match_idx=NaN(num_pea_census,1);
            %
            %
            % for j=1:1:num_pea_census
            %     temp_idx=find(pea_census_geo_idx(j)==temp_census_geo_idx);
            %     if ~isempty(temp_idx)
            %         temp_match_idx(j)=j;
            %     end
            % end
            % temp_match_idx=temp_match_idx(~isnan(temp_match_idx));
            if ~isempty(temp_match_idx)
                temp_cell_pea_holder{area_idx}=cell_census_geo{area_idx,1};
            end

        end
        temp_cell_pea_holder=temp_cell_pea_holder(~cellfun('isempty',temp_cell_pea_holder));
        if ~isempty(temp_cell_pea_holder)
            cell_pea_zone{pea_idx,2}=cell_pea_census_data{pea_idx,2};
            cell_pea_zone{pea_idx,1}=cell_pea_census_data{pea_idx,1};
            if length(temp_cell_pea_holder)>1
                cell_pea_zone{pea_idx,3}=strjoin(temp_cell_pea_holder, ', ');
            else
                cell_pea_zone{pea_idx,3}=temp_cell_pea_holder{1};
            end
        end
    end
    toc; %%%%13 Seconds
    cell_pea_zone=cell_pea_zone(~cellfun('isempty',cell_pea_zone(:,1)),:);
    zone_pea_table=cell2table(cell_pea_zone);
    zone_pea_table.Properties.VariableNames={'PEA_Name' 'PEA_Number' 'Zone_Location'}
    retry_save=1;
    while(retry_save==1)
        try
            writetable(zone_pea_table,strcat('Zone_PEA_2Col_',convex_label,'_',num2str(sim_number),'_',num2str(min(reliability)),'%.xlsx'));
            pause(0.1)
            retry_save=0;
        catch
            retry_save=1;
            pause(1)
        end
    end
end