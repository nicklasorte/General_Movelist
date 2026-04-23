function [array_agg_check_95,array_agg_check_mc_dBm]=agg_check_parfor_chunk_rev7_app_TEST(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,cell_sim_data,sim_folder,parallel_flag,test_label)

%disp_progress(app,strcat('Inside Agg Check Rev1: Line 3'))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Agg Check Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
agg_check_file_name=strcat(test_label,'_',string_prop_model,'_array_agg_check_95_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
[var_exist_agg_check]=persistent_var_exist_with_corruption(app,agg_check_file_name);

%%%%%%%%%Need to save the distribution also.
agg_dist_file_name=strcat(test_label,'_',string_prop_model,'_array_agg_check_mc_dBm_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
[var_exist_agg_dist]=persistent_var_exist_with_corruption(app,agg_dist_file_name);

if var_exist_agg_check==2 && var_exist_agg_dist==2
    %%%%%%%%%%%load
    retry_load=1;
    while(retry_load==1)
        try
            load(agg_check_file_name,'array_agg_check_95')
            load(agg_dist_file_name,'array_agg_check_mc_dBm')
            retry_load=0;
        catch
            retry_load=1;
            pause(1)
        end
    end
else
    tic;
    %point_idx
    %%%%%%Persistent Load
    %disp_progress(app,strcat('Inside Agg Check Rev1: Line 29: Loading Pathloss'))
    file_name_pathloss=strcat(string_prop_model,'_pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
    retry_load=1;
    while(retry_load==1)
        try
            load(file_name_pathloss,'pathloss')
            retry_load=0;
        catch
            retry_load=1;
            pause(1)
        end
    end

    file_name_clutter=strcat('P2108_clutter_loss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
    retry_load=1;
    while(retry_load==1)
        try
            load(file_name_clutter,'clutter_loss')
            retry_load=0;
        catch
            retry_load=1;
            pause(1)
        end
    end


    %%%%%%%% Cut the reliabilities that we will use for the move list
    %disp_progress(app,strcat('Inside Agg Check Rev1: Line 44: Cutting Reliabilities'))
    size(pathloss)
    [rel_first_idx]=nearestpoint_app(app,min(agg_check_reliability),reliability);
    [rel_second_idx]=nearestpoint_app(app,max(agg_check_reliability),reliability);
    if strcmp(string_prop_model,'TIREM')
        % % % % if TIREM, we wont cut the reliabilites because there are none to cut.
    else
        pathloss=pathloss(:,[rel_first_idx:rel_second_idx]);
    end
    size(pathloss)
    min(pathloss)

    [pathloss]=fix_inf_pathloss_rev1(app,pathloss);

    %%%%%%%% Cut the reliabilities that we will use for the move list
    %size(clutter_loss)
    [rel_first_idx]=nearestpoint_app(app,min(agg_check_reliability),reliability);
    [rel_second_idx]=nearestpoint_app(app,max(agg_check_reliability),reliability);
    clutter_loss=clutter_loss(:,[rel_first_idx:rel_second_idx]);
    %size(clutter_loss)

    %%%%%%%%%Cut the pathloss and clutter from those on
    pathloss(off_idx,:)=[];  %%%%%%%Cut off_idx
    %size(clutter_loss)
    clutter_loss(off_idx,:)=[];  %%%%%%%Cut off_idx
    %size(clutter_loss)
    %size(pathloss)
    %size(on_list_bs)


    %%%%%%%Take into consideration the sector/azimuth off-axis gain
    [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,on_list_bs,norm_aas_zero_elevation_data);
    %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain  %%%%%%%%This is the data to save and export to the excel

    tic;
    on_full_Pr_dBm=on_list_bs(:,4)-pathloss(:,:)+bs_azi_gain; %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System
    toc;

    if any(isnan(bs_azi_gain))
        find(isnan(bs_azi_gain))
        %disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev1: Line 70: NaN error on bs_azi_gain'))
        pause;
    end

    if any(isnan(pathloss))
        find(isnan(pathloss))
        %disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev1: Line 76: NaN error on pathloss'))
        pause;
    end

    if any(isnan(on_full_Pr_dBm))
        on_full_Pr_dBm
        %find(isnan(sort_full_Pr_dBm(:,1)))
        %disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev1: Line 83: NaN error on on_full_Pr_dBm'))
        'ERROR PAUSE: Inside Agg Check Rev1: Line 83: NaN error on on_full_Pr_dBm'
        pause;
    end


    if isempty(on_full_Pr_dBm)
        %disp_progress(app,strcat('ERROR PAUSE: Inside Agg Check Rev1: Line 89: Empty on_full_Pr_dBm, cant calculate aggrgate'))
        array_agg_check_95=NaN(1,1);
        array_agg_check_mc_dBm=NaN(1,1);
        %'ERROR PAUSE: Inside Agg Check : Line 89: Empty on_full_Pr_dBm, cant calculate aggrgate'
        %pause;

        retry_save=1;
        while(retry_save==1)
            try
                save(agg_dist_file_name,'array_agg_check_mc_dBm')
                save(agg_check_file_name,'array_agg_check_95')
                retry_save=0;
            catch
                retry_save=1;
                pause(1)
            end
        end
    else
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%Rand Seed1 for MC Iterations
        tempx=ceil(rand(1)*mc_size);
        tempy=ceil(rand(1)*mc_size);
        rand_seed1=tempx+tempy;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%This is where we break the mc_iter into chunks, like pathloss

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%This is where we define the num_chunks
        [num_chunks,cell_sim_chunk_idx,array_rand_chunk_idx]=dynamic_mc_chunks_rev1(app,mc_size);
        [hWaitbar_agg_chunks,hWaitbarMsgQueue_agg_chunks]= ParForWaitbarCreateMH_time('Agg Check Chunks: ',num_chunks);    %%%%%%% Create ParFor Waitbar, this one covers points and chunks

        %%%%'This is where we create the chunks and do a parfor and then stitch together with a for loop'
        if parallel_flag==1
            parfor chunk_idx=1:num_chunks  %%%%%%%%%Parfor
                parfor_randchunk_aggcheck_rev7(app,agg_check_file_name,agg_dist_file_name,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,parallel_flag);
                %parfor_randchunk_aggcheck_rev8_claude(app,agg_check_file_name,agg_dist_file_name,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,parallel_flag,single_search_dist);
                hWaitbarMsgQueue_agg_chunks.send(0);
            end
        end

        %%%%'I dont think we need the tf_stop_subchunk'

        %%%%%%%%%Then Assemble with for loop
        cell_agg_check=cell(num_chunks,1);
        %%tf_stop_subchunk=0; %%%%%%Load it in.
        for chunk_idx=1:num_chunks  %%%%%%%%%Parfor
            sub_point_idx=array_rand_chunk_idx(chunk_idx);
            %horzcat(chunk_idx,sub_point_idx)

            if tf_stop_subchunk==0
                temp_parallel_flag=0
                [cell_agg_check{sub_point_idx},tf_stop_subchunk]=parfor_randchunk_aggcheck_rev7(app,agg_check_file_name,agg_dist_file_name,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,temp_parallel_flag);
            end
            % tf_stop_subchunk%%%%Once the tf_stop_subchunk
            temp_parallel_flag=0;
            %[sub_array_agg_check_mc_dBm]=parfor_randchunk_aggcheck_rev8_claude(app,agg_check_file_name,agg_dist_file_name,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,temp_parallel_flag,single_search_dist);
            cell_agg_check{sub_point_idx}=sub_array_agg_check_mc_dBm;

            if parallel_flag==0
                hWaitbarMsgQueue_agg_chunks.send(0);%%%%%%%Decrement the waitbar
            end
        end
        %%%%server_status_rev2(app,tf_server_status) %%%%%%%%%%Send an update after we done all the heavy computation


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        array_agg_check_mc_dBm=vertcat(cell_agg_check{:}); %%%%%%%%Piece it together here.

        if all(isnan(array_agg_check_mc_dBm))
            'Error array_agg_check_mc_dBm is NaN'
            pause;
        else
            %%%%%%%%Not NaN, can keep going
            %%%%%%%%%%%%%%Generate MC Iterations and Calculate Move List
            %array_agg_check_mc_dBm=NaN(mc_size,num_sim_azi);

            [mc_rows,num_azi]=size(array_agg_check_mc_dBm)
            if num_azi>1
                'need to check percentile function of array_agg_check_mc_dBm'
                pause;
            end

            size(array_agg_check_mc_dBm)
            array_agg_check_95=prctile(sort(array_agg_check_mc_dBm),mc_percentile);
            [f_y,x_dB]=ecdf(array_agg_check_mc_dBm);
            %horzcat(x_dB,f_y)


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
            per_first_in=array_agg_check_95+zero_dB;

            if ~isempty(in2_idx)
                in_ratio2=cell_sim_data{row_folder_idx,in2_idx};
            else
                in_ratio2=NaN(1,1);
            end
            if ~isempty(per2_idx)
                per2=cell_sim_data{row_folder_idx,per2_idx};

                %%%%%%Find the second percentile also
                array_agg_check_second=prctile(sort(array_agg_check_mc_dBm),per2);
                per_second_in=array_agg_check_second+zero_dB;
            else
                per2=NaN(1,1);
                per_second_in=NaN(1,1);
            end

            f2=figure;
            hold on;
            plot(x_dB+zero_dB,f_y,':b','LineWidth',3)
            yline(mc_percentile/100,'--k','LineWidth',1)
            xline(in_ratio1,'-r','LineWidth',2)
            xline(per_first_in,':r','LineWidth',2)
            xline(in_ratio2,'-g','LineWidth',2)
            yline(per2/100,'--k','LineWidth',1)
            xline(per_second_in,':g','LineWidth',2)
            plot(x_dB+zero_dB,f_y,':b','LineWidth',3)
            title('Aggregate CDF')
            xlabel('I/N [dB]')
            ylabel('Cumulative Probability')
            grid on;
            pause(0.1)
            filename1=strcat(test_label,'_','AggCheckCDF_',num2str(point_idx),'_',num2str(single_search_dist),'km.png');
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
            close(f2)


            %%%%%Save master_turn_off_idx, Persistent Save
            %disp_progress(app,strcat('Inside Agg Check Rev1: Line 194: Saving array_agg_check_95'))
            retry_save=1;
            while(retry_save==1)
                try
                    save(agg_dist_file_name,'array_agg_check_mc_dBm')
                    save(agg_check_file_name,'array_agg_check_95')
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(1)
                end
            end

        end
    end
    toc;

    %%%%'delete the chunks before leaving this function'

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'This is where we then clean up the single point'
    %%%%%%%%%%%%Double check that it is there.
    tf_file_check_loop=1;
    while(tf_file_check_loop==1)
        try
            [var_exist1]=persistent_var_exist_with_corruption(app,agg_dist_file_name);
            [var_exist2]=persistent_var_exist_with_corruption(app,agg_check_file_name);
            pause(0.1);
        catch
            var_exist1=0;
            var_exist2=0;
            pause(0.1)
        end
        if var_exist1==2 && var_exist2==2
            tf_file_check_loop=0;
        else
            tf_file_check_loop=1;
            pause(10)
        end
    end

    if var_exist1==2 && var_exist2==2
        %%%%%%%%%Loop for deleting
        for sub_point_idx=1:num_chunks
            %%file_name_agg_check_chunk=strcat('sub_',num2str(sub_point_idx),'_array_agg_check_mc_dBm_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
            file_name_agg_check_chunk=strcat('sub_',num2str(sub_point_idx),'_array_agg_check_mc_dBm_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'_',num2str(single_search_dist),'km.mat');
            persistent_delete_rev1(app,file_name_agg_check_chunk)
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End of clean up

    %%%'Need to clean up the waittimer before leaving the function'
    try
        delete(hWaitbarMsgQueue_agg_chunks);
        close(hWaitbar_agg_chunks);
    catch
    end

end
