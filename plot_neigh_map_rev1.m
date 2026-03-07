function plot_neigh_map_rev1(app,nnan_base_polygon,base_polygon,neighborhood_bound,data_label1,CBSD_label,buffer_radius,sim_number)

                f1=figure;
                [x41,y41]=size(nnan_base_polygon)
                if x41>1
                    geoplot(base_polygon(:,1),base_polygon(:,2),'-k')
                else
                    geoplot(nnan_base_polygon(:,1),nnan_base_polygon(:,2),'ok')
                end
                hold on;
                geoplot(neighborhood_bound(:,1),neighborhood_bound(:,2),'--r')
                title({strcat(data_label1),strcat(CBSD_label,'-Neighborhood:',num2str(buffer_radius),'km')})
                grid on;
                geobasemap streets-light%landcover
                f1.Position = [100 100 1200 900];
                pause(1)
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
                close(f1)

end