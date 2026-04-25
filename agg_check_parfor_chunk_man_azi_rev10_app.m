function [array_agg_check_95,array_agg_check_mc_dBm]=agg_check_parfor_chunk_man_azi_rev10_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,cell_sim_data,sim_folder,parallel_flag,azimuth_step,tf_man_azi_step,tf_server_status)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Agg Check Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
agg_check_file_name=strcat(string_prop_model,'_array_agg_check_95_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
[var_exist_agg_check]=persistent_var_exist_with_corruption(app,agg_check_file_name);

%%%%%%%%%Need to save the distribution also.
agg_dist_file_name=strcat(string_prop_model,'_array_agg_check_mc_dBm_',num2str(min(agg_check_reliability)),'_',num2str(max(agg_check_reliability)),'_',num2str(point_idx),'_',num2str(sim_number),'_',num2str(mc_size),'_',num2str(single_search_dist),'km.mat');
[var_exist_agg_dist]=persistent_var_exist_with_corruption(app,agg_dist_file_name);

if var_exist_agg_check==2 && var_exist_agg_dist==2
    %%%%%%%%%%%load
    [array_agg_check_95]=persistent_load_var_rev1(app,agg_check_file_name,'array_agg_check_95');
    [array_agg_check_mc_dBm]=persistent_load_var_rev1(app,agg_dist_file_name,'array_agg_check_mc_dBm');
else


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%This is where we define the num_chunks
    [num_chunks,cell_sim_chunk_idx,array_rand_chunk_idx]=dynamic_mc_chunks_rev1(app,mc_size);

    tic;
    %%%%%%%%Load pathloss + clutter, cut to agg_check_reliability range, fix Inf
    [pathloss,clutter_loss]=load_pathloss_clutter_cut_rel_rev1(app,point_idx,sim_number,data_label1,string_prop_model,reliability,agg_check_reliability);
    size(pathloss)
    min(pathloss)

    %%%%%%%%%Cut the pathloss and clutter from those on
    pathloss(off_idx,:)=[];  %%%%%%%Cut off_idx
    clutter_loss(off_idx,:)=[];  %%%%%%%Cut off_idx


    %%%%%%%Take into consideration the sector/azimuth off-axis gain
    [bs_azi_gain,array_bs_azi_data]=off_axis_gain_bs2fed_rev1(app,base_protection_pts,point_idx,on_list_bs,norm_aas_zero_elevation_data);
    %%%%%%array_bs_azi_data --> 1) bs2fed_azimuth 2) sector_azi 3) azi_diff_bs 4) mod_azi_diff_bs 5) bs_azi_gain

    tic;
    on_full_Pr_dBm=on_list_bs(:,4)-pathloss(:,:)+bs_azi_gain; %%%%%%%%%%%Non-Mitigation EIRP - Pathloss + BS Azi Gain = Power Received at Federal System
    toc;

    check_array_no_nan_rev1(app,bs_azi_gain,'bs_azi_gain','agg_check_parfor_chunk_man_azi_rev10_app')
    check_array_no_nan_rev1(app,pathloss,'pathloss','agg_check_parfor_chunk_man_azi_rev10_app')
    check_array_no_nan_rev1(app,on_full_Pr_dBm,'on_full_Pr_dBm','agg_check_parfor_chunk_man_azi_rev10_app')


    if isempty(on_full_Pr_dBm)
        array_agg_check_95=NaN(1,1);
        array_agg_check_mc_dBm=NaN(1,1);

        persistent_save_var_rev1(app,agg_dist_file_name,'array_agg_check_mc_dBm',array_agg_check_mc_dBm)
        persistent_save_var_rev1(app,agg_check_file_name,'array_agg_check_95',array_agg_check_95)
    else
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%Rand Seed1 for MC Iterations
        [rand_seed1]=gen_mc_rand_seed_rev1(mc_size);
        %%%%%%%%%%%%%%%%%This is where we break the mc_iter into chunks

        [hWaitbar_agg_chunks,hWaitbarMsgQueue_agg_chunks]= ParForWaitbarCreateMH_time('Agg Check Chunks: ',num_chunks);


        %%%%'This is where we create the chunks and do a parfor and then stitch together with a for loop'
        if parallel_flag==1
            parfor chunk_idx=1:num_chunks  %%%%%%%%%Parfor
                parfor_randchunk_aggcheck_rev9_mc_same(app,agg_check_file_name,agg_dist_file_name,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,parallel_flag,single_search_dist,tf_man_azi_step,azimuth_step);
                hWaitbarMsgQueue_agg_chunks.send(0);
            end
            server_status_rev2(app,tf_server_status)
        end


        %%%%%%%%%Then Assemble with for loop
        cell_agg_check=cell(num_chunks,1);
        for chunk_idx=1:num_chunks
            sub_point_idx=array_rand_chunk_idx(chunk_idx);

            temp_parallel_flag=0;
            [sub_array_agg_check_mc_dBm]=parfor_randchunk_aggcheck_rev9_mc_same(app,agg_check_file_name,agg_dist_file_name,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,temp_parallel_flag,single_search_dist,tf_man_azi_step,azimuth_step);
            cell_agg_check{sub_point_idx}=sub_array_agg_check_mc_dBm;

            if parallel_flag==0
                hWaitbarMsgQueue_agg_chunks.send(0);
            end
        end
        server_status_rev2(app,tf_server_status)

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        array_agg_check_mc_dBm=vertcat(cell_agg_check{:}); %%%%%%%%Piece it together here.
        if all(isnan(array_agg_check_mc_dBm))
            'Error array_agg_check_mc_dBm is NaN'
            pause;
        else
            %%%%%%%%%%%%%%Generate MC Iterations and Calculate Move List
            size(array_agg_check_mc_dBm)
            array_agg_check_95=prctile(sort(array_agg_check_mc_dBm),mc_percentile);
            [f_y,x_dB]=ecdf(array_agg_check_mc_dBm);

            %%%%%%%%%%Pull primary + secondary thresholds and I/N ratios from cell_sim_data
            [thresh]=get_dpa_thresholds_from_cell_sim_data_rev1(cell_sim_data,sim_folder);
            in_ratio1=thresh.in_ratio1;
            in_ratio2=thresh.in_ratio2;
            per2=thresh.mc_per2;
            radar_threshold=thresh.radar_threshold;

            %%%%%%%%%%This is the zero dB shift.
            zero_dB=in_ratio1-radar_threshold;
            per_first_in=array_agg_check_95+zero_dB;

            if ~isnan(per2)
                %%%%%%Find the second percentile also
                array_agg_check_second=prctile(sort(array_agg_check_mc_dBm),per2);
                per_second_in=array_agg_check_second+zero_dB;
            else
                per_second_in=NaN(1,1);
            end
            in_ratio2
            tf_second_data=thresh.tf_second_data_in;
            tf_second_data

            f2=figure;
            hold on;
            plot(x_dB+zero_dB,f_y,':b','LineWidth',3)
            yline(mc_percentile/100,'--k','LineWidth',1)
            xline(in_ratio1,'-r','LineWidth',2)
            xline(per_first_in,':r','LineWidth',2)
            if tf_second_data==1
                xline(in_ratio2,'-g','LineWidth',2)
                yline(per2/100,'--k','LineWidth',1)
                xline(per_second_in,':g','LineWidth',2)
            end
            plot(x_dB+zero_dB,f_y,':b','LineWidth',3)
            title('Aggregate CDF')
            xlabel('I/N [dB]')
            ylabel('Cumulative Probability')
            grid on;
            pause(0.1)
            filename1=strcat('AggCheckCDF_',num2str(point_idx),'_',num2str(single_search_dist),'km.png');
            persistent_save_figure_rev1(app,gcf,filename1)
            pause(0.1);
            close(f2);

            %%%%%Save master_turn_off_idx, Persistent Save
            persistent_save_var_rev1(app,agg_dist_file_name,'array_agg_check_mc_dBm',array_agg_check_mc_dBm)
            persistent_save_var_rev1(app,agg_check_file_name,'array_agg_check_95',array_agg_check_95)

        end
    end
    toc;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'This is where we then clean up the single point'
    wait_for_persistent_files_rev1(app,{agg_dist_file_name,agg_check_file_name});

    %%%%%%%%%Loop for deleting
    cleanup_subchunk_files_rev1(app,num_chunks, ...
        @(s) strcat('sub_',num2str(s),'_array_agg_check_mc_dBm_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'_',num2str(single_search_dist),'km.mat'));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%End of clean up

    %%%'Need to clean up the waittimer before leaving the function'
    try
        cleanup_parfor_waitbar_rev1(hWaitbar_agg_chunks,hWaitbarMsgQueue_agg_chunks);
    catch
    end
    server_status_rev2(app,tf_server_status)

end
end
