function single_mod_plateau_alg_rev6_geoplot_name(app,data_label1,sim_number,radar_threshold,margin,maine_exception,CBSD_label,base_polygon,base_protection_pts,tf_catb)



      

%%%Check for cell and Process
%%%temp_filename=strcat(data_label1,'_',num2str(sim_number),'_all_data_stats_binary.mat');
temp_filename=strcat(CBSD_label,'_',data_label1,'_',num2str(sim_number),'_all_data_stats_binary.mat');
if exist(temp_filename,'file')==2
    %%%%%%First Check to See if we Processed It
    %%%temp_catb_filename=strcat('mod_',data_label1,'_',num2str(sim_number),'_catb_dist_data.mat');
    temp_catb_filename=strcat(CBSD_label,'_mod_',data_label1,'_',num2str(sim_number),'_catb_dist_data.mat');
    var_catb_exist=exist(temp_catb_filename,'file');
    var_catb_exist=0; %%%%%%%%Always redo the calculation
    if var_catb_exist==2
        retry_load=1;
        while(retry_load==1)
            try
                load(temp_catb_filename,'catb_dist_data')
                retry_load=0;
                %%%%%%%%%%%%We need to do this or the parfor loop won't work.
                temp_data=catb_dist_data;
                clear catb_dist_data;
                catb_dist_data=temp_data;
                clear temp_data;
            catch
                retry_load=1;
                pause(0.1)
            end
        end
    elseif var_catb_exist==0
        retry_load=1;
        while(retry_load==1)
            try
                load(temp_filename,'all_data_stats_binary')
                retry_load=0;
                %%%%%%%%%%%%We need to do this or the parfor loop won't work.
                temp_data=all_data_stats_binary;
                clear all_data_stats_binary;
                all_data_stats_binary=temp_data;
                clear temp_data;
            catch
                retry_load=1;
                pause(0.1)
            end
        end
        
        temp_sim_pt=base_protection_pts;
        
        %Process the Data and Find the CatB Distances
        %%%%%Process the Data
        x22=length(all_data_stats_binary);
        catb_dist_data=NaN(x22,1);
        for point_idx=1:1:x22
            full_stats_catb=all_data_stats_binary{point_idx};
            
            %%%%Replace NaNs with '0'
            [x98,y98]=size(full_stats_catb);
            for k=1:1:x98
                idx_fill_nan=find(isnan(full_stats_catb(k,:))==1);
                full_stats_catb(k,idx_fill_nan)=0;
            end
            
            %%%%%Check if the last full_stats_catb is less than radar_threshold
            if full_stats_catb(end,2)>radar_threshold
                pseudo_threshold=full_stats_catb(end,2)+1;
                temp_idx_fix=find(full_stats_catb(:,2)<pseudo_threshold);
                full_stats_catb(temp_idx_fix,2)=radar_threshold;
            end
            
            if isempty(full_stats_catb)==0
                %%%%Find the First Point within the agg margin (Original Algorithm)
                tf_agg=full_stats_catb(:,2)>(radar_threshold+margin);
                tf_agg2=full_stats_catb(:,2)<(radar_threshold+margin);
                if all(tf_agg)==1 || all(tf_agg2)==1 %%%%%%This checks to see if all the points are above or below the radar threshold
                    catb_dist_data(point_idx)=NaN(1);
                else
                    idx_crossing=find(tf_agg==0,1,'first'); %%%%%Find the First Point within the agg margin
                    if isempty(idx_crossing)==1
                        [idx_crossing,~]=size(full_stats_catb);
                    end
                    catb_dist_data(point_idx)=full_stats_catb(idx_crossing,1);
                    
                    %%%%%%%%%%%%Check for the plateau with a small move list
                    movelist_size=max(full_stats_catb(:,3));
                    idx_crossing_diff=NaN(1);
                    if movelist_size<maine_exception
                        agg_diff=-1*diff(full_stats_catb(1:idx_crossing-1,2));
                        sum_agg_diff=NaN(idx_crossing-2,1);
                        for j=1:1:(idx_crossing-2)
                            sum_agg_diff(j)=sum(agg_diff(j:idx_crossing-2));
                        end
                        idx_crossing_diff=find(sum_agg_diff<margin,1,'first');
                        if isempty(idx_crossing_diff)==1
                            catb_dist_data(point_idx)=full_stats_catb(idx_crossing,1);
                        elseif idx_crossing_diff==1
                            catb_dist_data(point_idx)=NaN(1);
                        else
                            catb_dist_data(point_idx)=full_stats_catb(idx_crossing_diff,1);
                        end
                    end
                end
            end
        end
        
        if strcmp(CBSD_label,'CatB')==1 || strcmp(CBSD_label,'BS')==1
            CBSD_label='BaseStation';
        end
        if strcmp(CBSD_label,'CatA')==1 || strcmp(CBSD_label,'AP')==1
            CBSD_label='AccessPoint';
        end
        
        catb_dist_data
        [m_dist,m_idx]=max(catb_dist_data);
        fig1=figure;
        %plot(base_polygon(:,2),base_polygon(:,1),'-k')
        geoplot(base_polygon(:,1),base_polygon(:,2),'-k')%%%,'LineWidth',3,'DisplayName','Federal System')
        hold on;
        %%%%scatter3(temp_sim_pt(:,2),temp_sim_pt(:,1),catb_dist_data,20,catb_dist_data,'filled')
        %geoscatter(temp_sim_pt(:,1),temp_sim_pt(:,2),20,C,'filled')
        geoscatter(temp_sim_pt(:,1),temp_sim_pt(:,2),20,'filled')
        'Need to add the color to the geoscatter plot.'
        catb_dist_data(isnan(catb_dist_data))=-Inf;
        [~,sort_idx]=sort(catb_dist_data,'descend');
        catb_dist_data(isinf(catb_dist_data))=NaN(1);
        if length(catb_dist_data)>10
            %%%plot(temp_sim_pt(sort_idx(1:10),2),temp_sim_pt(sort_idx(1:10),1),'sr','MarkerSize',10,'LineWidth',2)
            geoplot(temp_sim_pt(sort_idx(1:10),1),temp_sim_pt(sort_idx(1:10),2),'sr','MarkerSize',10,'LineWidth',2)
        end
        %%%plot(temp_sim_pt(m_idx,2),temp_sim_pt(m_idx,1),'ok','MarkerSize',20,'LineWidth',4)
        geoplot(temp_sim_pt(m_idx,1),temp_sim_pt(m_idx,2),'ok','MarkerSize',20,'LineWidth',4)
        colormap(jet);
        title({strcat(data_label1),strcat('Neighborhood Distances [km]'),strcat(CBSD_label)})
        c=colorbar;
        c.Label.String='[km]';
        grid on;
        %xlabel('Longitude')
        %ylabel('Latitude')
        %%%plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
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
        close(fig1)
        
        
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
       
        
        fig1=figure;
        hold on;
        plot(catb_dist_data,'-ob')
        grid on;
        grid on;
        ylabel('Aggregate Interference [dBm]')
        xlabel('Neighborhood Distance')
        title({strcat(data_label1),strcat('Neighborhood:',num2str(max(catb_dist_data)),'km'),strcat(CBSD_label)})
        filename1=strcat(CBSD_label,'_mod_',data_label1,'_AllPoints_',num2str(sim_number),'.png');
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
        
        %%%Find Max Distance and Look at Individual Plot
        [~,point_idx]=max(catb_dist_data);
        fig1=figure;
        hold on;
        full_stats_catb=all_data_stats_binary{point_idx};
        plot(full_stats_catb(:,1),full_stats_catb(:,2),'-sk')
        line([min(xlim),max(xlim)],[radar_threshold,radar_threshold],'Color','r','LineWidth',2)
        fill([min(xlim),max(xlim),max(xlim),min(xlim),min(xlim)],[radar_threshold+1,radar_threshold+1,min(ylim),min(ylim),radar_threshold+1],'g','FaceAlpha',0.25)
        line([min(xlim),max(xlim)],[radar_threshold,radar_threshold],'Color','r','LineWidth',2)
        line([catb_dist_data(point_idx),catb_dist_data(point_idx)],[min(ylim),max(ylim)],'Color','b','LineWidth',2)
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
        
        
        
        %%%%%%%%%%%%%Draw the Neighborhood around the base_polygon
        nnan_base_polygon=base_polygon(~isnan(base_polygon(:,1)),:);%%%%%%Remove NaN
        buffer_radius=catb_dist_data(point_idx);
        
        if isnan(buffer_radius)==1 || buffer_radius==0
            buffer_radius=1;
        end
        
        
        %%%%%%%If base_polygon is a single point
        [x41,y41]=size(nnan_base_polygon)
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

            [neighborhood_bound]=calc_sim_bound(app,nnan_base_polygon,buffer_radius,data_label1);
        else
            n_pts=50;
            [temp_esc_lat, temp_esc_lon]=scircle1(nnan_base_polygon(1,1),nnan_base_polygon(1,2),km2deg(buffer_radius),[],[],'degrees',n_pts);
            k=convhull(temp_esc_lon,temp_esc_lat);
            esc_lat4=temp_esc_lat(k);
            esc_lon4=temp_esc_lon(k);
            neighborhood_bound=[esc_lat4,esc_lon4];
        end
        

        fig1=figure;
       
        if x41>1
            %%%plot(base_polygon(:,2),base_polygon(:,1),'-k')
            geoplot(base_polygon(:,1),base_polygon(:,2),'-k')
        else
            %%%plot(nnan_base_polygon(:,2),nnan_base_polygon(:,1),'ok')
            geoplot(nnan_base_polygon(:,1),nnan_base_polygon(:,2),'ok')
        end
         hold on;
        %%%plot(neighborhood_bound(:,2),neighborhood_bound(:,1),'--r')
        geoplot(neighborhood_bound(:,1),neighborhood_bound(:,2),'--r')
        %geoplot(neighborhood_bound2(:,1),neighborhood_bound2(:,2),'--g')
        title({strcat(data_label1),strcat(CBSD_label,'-Neighborhood:',num2str(buffer_radius),'km')})
        grid on;
        %xlabel('Longitude')
        %ylabel('Latitude')
        geobasemap streets-light%landcover
        f1.Position = [100 100 1200 900];
        pause(1)
        %plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
        filename1=strcat(CBSD_label,'_mod_',data_label1,'_Neighborhood_',num2str(sim_number),'.png');
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
        
        %%%%%%%%Save the CatB Neighborhood Polygon
        
        retry_save=1;
        while(retry_save==1)
            try
                save(strcat(CBSD_label,'_',data_label1,'_neighborhood_bound.mat'),'neighborhood_bound')
                pause(0.1);
                retry_save=0;
            catch
                retry_save=1;
                pause(0.1)
            end
        end
        
        if tf_catb==1
            catb_neighborhood_radius=buffer_radius;
            retry_save=1;
            while(retry_save==1)
                try
                    save(strcat(CBSD_label,'_',data_label1,'_catb_neighborhood_radius.mat'),'catb_neighborhood_radius')
                    pause(0.1);
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(0.1)
                end
            end
            retry_save=1;
            while(retry_save==1)
                try
                    save(strcat(CBSD_label,'_mod_',data_label1,'_',num2str(sim_number),'_catb_dist_data.mat'),'catb_dist_data')
                    pause(0.1);
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(0.1)
                end
            end
        else
            cata_neighborhood_radius=buffer_radius;
            retry_save=1;
            while(retry_save==1)
                try
                    save(strcat(CBSD_label,'_',data_label1,'_cata_neighborhood_radius.mat'),'cata_neighborhood_radius')
                    pause(0.1);
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(0.1)
                end
            end
            cata_dist_data=catb_dist_data;
            retry_save=1;
            while(retry_save==1)
                try
                    save(strcat(CBSD_label,'_mod_',data_label1,'_',num2str(sim_number),'_cata_dist_data.mat'),'cata_dist_data')
                    pause(0.1);
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(0.1)
                end
            end
        end
    end
    strcat(CBSD_label,'-Distance:',num2str(max(catb_dist_data)))
end
end