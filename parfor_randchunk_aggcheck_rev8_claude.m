function [sub_array_agg_check_mc_dBm]=parfor_randchunk_aggcheck_rev8_claude(app,agg_check_file_name,agg_dist_file_name,array_rand_chunk_idx,chunk_idx,point_idx,sim_number,data_label1,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,parallel_flag,single_search_dist)

sub_array_agg_check_mc_dBm=NaN(1,1);

%%%%Check if the big file is there before
[var_exist1]=persistent_var_exist_with_corruption(app,agg_check_file_name);
[var_exist2]=persistent_var_exist_with_corruption(app,agg_dist_file_name);
if var_exist1==2 && var_exist2==2
    %%%%%%%%%%%%%%%%%%%%%%%%If the big file exists, and we are trying to clean up the chunks, this doesn't come back  and create more chunks.
    sub_array_agg_check_mc_dBm=NaN(1,1);
else

    %%%%%%%%%%%%%%%%%%%%The large file doesn't exist, we need to check for the chunk.
    sub_point_idx=array_rand_chunk_idx(chunk_idx);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%This was the last check point before a stop.[THIS IS the last successful checkpoint.]

    %%%%%%Check/Calculate path loss
    file_name_agg_check_chunk=strcat('sub_',num2str(sub_point_idx),'_array_agg_check_mc_dBm_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'_',num2str(single_search_dist),'km.mat');
    [var_exist3_chunk]=persistent_var_exist_with_corruption(app,file_name_agg_check_chunk);

    %%%%%%%%%%%%%%%%%%%%%%%See if we need to calculate the sub-chunk
    if var_exist3_chunk==2 && parallel_flag==0 %%%%%%%%%%%%%We should only load in the non-parllel
        retry_load=1;
        while(retry_load==1) %%%%%%
            try
                load(file_name_agg_check_chunk,'sub_array_agg_check_mc_dBm')
                temp_data=sub_array_agg_check_mc_dBm;
                clear sub_array_agg_check_mc_dBm;
                sub_array_agg_check_mc_dBm=temp_data;
                clear temp_data;
                retry_load=0;
            catch
                retry_load=1;
                pause(1)  %%%%%%%%%%%Need to catch the error here and display it.
            end
        end
    elseif var_exist3_chunk==2 && parallel_flag==1  %%%%%Parallel, just need a placeholder: No loading
        sub_array_agg_check_mc_dBm=NaN(1,1);
    else
        %%%%%%%%The sub-chunk doesn't exist and we need to calculate it
        %%%'this is where we create a function and feed the inputs'
        %%%'need to vectorize code and check with multiple sim azimuths.'
        % tic;
        % [sub_array_agg_check_mc_dBm]=subchunk_agg_check_rev7(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);
        % toc;
        %tic;
        %[sub_array_agg_check_mc_dBm]=subchunk_agg_check_rev8(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);
        %toc;

        %'A/B test rev7 and gpt Rev8'
        %results = validate_subchunk_agg_check_rev8_rev1(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % % % % % results =
        % % % % % struct with fields:
        % % % % % size_equal: 1
        % % % % % nan_pattern_equal: 1
        % % % % % max_abs_diff: 0
        % % % % % mean_abs_diff: 0
        % % % % % rev8_reproducible: 1
        % % % % % rev7_runtime_s: 5.1393
        % % % % % rev8_runtime_s: 2.3068
        % % % % % percent_improvement: 55.114
        % % % % % equivalent_within_tol: 1

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Rev9 is just the max of all azimuths.
        % 'Rev 9 time:'
        % tic;
        % [sub_array_agg_check_mc_dBm_9]=subchunk_agg_check_maxazi_rev9(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);
        % toc;


        % tic;
        % [sub_array_agg_check_mc_dBm_10]=subchunk_agg_check_maxazi_rev10(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);
        % toc;
        %isequaln(sub_array_agg_check_mc_dBm_9,sub_array_agg_check_mc_dBm_10) %%%%%%Yes

        %%%results=validate_subchunk_agg_check_maxazi_rev9_rev10_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        %          --- VALIDATION SUMMARY ---
        % Output Size Match:      1
        % Column Vector Match:    1
        % NaN Pattern Match:      1
        % Inf Pattern Match:      1
        % Class Match:            1
        % Exact Match:            1
        % Max Abs Diff:           0
        % Max Rel Diff:           0
        % Mean Abs Diff:          0
        % Worst Abs Index:        1
        % Worst Rel Index:        1
        % Finite Mismatch Count:  0
        % Tolerance Abs:          1.0e-10
        % Tolerance Rel:          1.0e-10
        % Runtime Rev9 (s):       2.523698
        % Runtime Rev10 (s):      3.938470
        % Speedup (Rev9/Rev10):   0.640781
        % Result: PASS



        tic;
        [sub_array_agg_check_mc_dBm]=subchunk_agg_check_maxazi_rev11(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);
        tic;
        %%%isequaln(sub_array_agg_check_mc_dBm_11,sub_array_agg_check_mc_dBm_10) %%%%%%%%%%%%%RNG is not the same, so this is not the same.

        %results=validate_subchunk_agg_check_maxazi_rev10_rev11_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)

        % % % % === rev10 vs rev11 statistical validation ===
        % % % % AZI_CHUNK (rev11): 128
        % % % % Runtime rev10: 2.916505 s
        % % % % Runtime rev11: 2.117821 s
        % % % % Speedup rev10/rev11: 1.377x
        % % % % 
        % % % % Metric comparison (rev11 - rev10):
        % % % % mean    | rev10=  -86.3423 | rev11=  -85.9781 | abs=0.3643 | allow=4.3171 | PASS
        % % % % std     | rev10=    3.3343 | rev11=    3.6495 | abs=0.3152 | allow=0.5000 | PASS
        % % % % min     | rev10=  -92.3004 | rev11=  -93.2843 | abs=0.9839 | allow=4.6150 | PASS
        % % % % max     | rev10=  -73.7760 | rev11=  -72.0770 | abs=1.6990 | allow=3.6888 | PASS
        % % % % median  | rev10=  -87.0898 | rev11=  -86.7112 | abs=0.3786 | allow=4.3545 | PASS
        % % % % p90     | rev10=  -81.7126 | rev11=  -80.9077 | abs=0.8049 | allow=4.0856 | PASS
        % % % % p95     | rev10=  -79.3361 | rev11=  -78.9053 | abs=0.4309 | allow=3.9668 | PASS
        % % % % p99     | rev10=  -76.9782 | rev11=  -74.9951 | abs=1.9831 | allow=3.8489 | PASS
        % % % % 
        % % % % Upper-tail checks:
        % % % % p95     | abs=0.4309 | allow=3.9668 | PASS
        % % % % p99     | abs=1.9831 | allow=3.8489 | PASS
        % % % % 
        % % % % PASS: rev11 is statistically equivalent to rev10 under configured thresholds.


        %results = benchmark_subchunk_agg_check_maxazi_rev11_chunk_sweep_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % % % Chunk    Runtime (s)    Relative to Best
        % % % 32      2.204069         1.000x
        % % % 64      6.515447         2.956x
        % % % 128      5.464187         2.479x
        % % % 256      5.400025         2.450x
        % % % 512      6.419014         2.912x
        % % % 1024      7.769072         3.525x
        % % % Best chunk: 32
        % % % Best runtime: 2.204069 s
        % % % Speedup vs chunk 128: 2.479x
        % % % Recommended chunk size for rev12 default: 32
        
        
        %results = validate_subchunk_agg_check_maxazi_rev11_rev12_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % %         === REV11 vs REV12 STATISTICAL VALIDATION ===
        % % AZI_CHUNK rev11: 128
        % % AZI_CHUNK rev12: 128
        % % Runtime rev11: 2.188578 s
        % % Runtime rev12: 2.175274 s
        % % Speedup rev11/rev12: 1.006x
        % %
        % % Metric comparison (rev12 - rev11):
        % %   mean    | rev11=  -86.2485 | rev12=  -86.2485 | abs=0.0000 | allow=4.3124 | PASS
        % %   std     | rev11=    3.5223 | rev12=    3.5223 | abs=0.0000 | allow=0.5000 | PASS
        % %   min     | rev11=  -92.4138 | rev12=  -92.4138 | abs=0.0000 | allow=4.6207 | PASS
        % %   max     | rev11=  -71.4080 | rev12=  -71.4080 | abs=0.0000 | allow=3.5704 | PASS
        % %   median  | rev11=  -86.8584 | rev12=  -86.8584 | abs=0.0000 | allow=4.3429 | PASS
        % %   p90     | rev11=  -81.2014 | rev12=  -81.2014 | abs=0.0000 | allow=4.0601 | PASS
        % %   p95     | rev11=  -79.7192 | rev12=  -79.7192 | abs=0.0000 | allow=3.9860 | PASS
        % %   p99     | rev11=  -74.9426 | rev12=  -74.9426 | abs=0.0000 | allow=3.7471 | PASS
        % %
        % % Upper-tail checks:
        % %   p95     | abs=0.0000 | allow=3.9860 | PASS
        % %   p99     | abs=0.0000 | allow=3.7471 | PASS
        % %
        % % PASS: rev12 is statistically equivalent to rev11 under configured thresholds.

        % 'Rev 12 time:'
        % tic;
        % [sub_array_agg_check_mc_dBm_12]=subchunk_agg_check_maxazi_rev12(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);
        % toc;
        %%%%%%%Rev 9 vs Rev 12 time: 7.44 vs 4.32 Seconds

        results = benchmark_subchunk_agg_check_maxazi_rev10_rev13_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % % %        === REV10 vs REV13 REAL-INPUT BENCHMARK ===
        % % % AZI_CHUNK rev13: 32
        % % % Runtime rev10: 2.244750 s
        % % % Runtime rev13: 2.230879 s
        % % % Speedup rev10/rev13: 1.006x
        
        
        results = validate_subchunk_agg_check_maxazi_rev11_rev13_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)

        % % % === REV11 vs REV13 STATISTICAL VALIDATION ===
        % % % AZI_CHUNK rev11: 128
        % % % AZI_CHUNK rev13: 32
        % % % Runtime rev11: 2.197647 s
        % % % Runtime rev13: 2.214442 s
        % % % Speedup rev11/rev13: 0.992x
        % % % 
        % % % Metric comparison (rev13 - rev11):
        % % % mean    | rev11=  -86.1101 | rev13=  -86.1101 | abs=0.0000 | allow=4.3055 | PASS
        % % % std     | rev11=    3.8168 | rev13=    3.8168 | abs=0.0000 | allow=0.5000 | PASS
        % % % min     | rev11=  -94.0030 | rev13=  -94.0030 | abs=0.0000 | allow=4.7002 | PASS
        % % % max     | rev11=  -71.5660 | rev13=  -71.5660 | abs=0.0000 | allow=3.5783 | PASS
        % % % median  | rev11=  -87.0831 | rev13=  -87.0831 | abs=0.0000 | allow=4.3542 | PASS
        % % % p90     | rev11=  -80.1925 | rev13=  -80.1925 | abs=0.0000 | allow=4.0096 | PASS
        % % % p95     | rev11=  -78.6884 | rev13=  -78.6884 | abs=0.0000 | allow=3.9344 | PASS
        % % % p99     | rev11=  -75.6916 | rev13=  -75.6916 | abs=0.0000 | allow=3.7846 | PASS
        % % % 
        % % % Upper-tail checks:
        % % % p95     | abs=0.0000 | allow=3.9344 | PASS
        % % % p99     | abs=0.0000 | allow=3.7846 | PASS
        % % % 
        % % % PASS: rev13 is statistically equivalent to rev11 under configured thresholds.


        %size(sub_array_agg_check_mc_dBm_12)
        'check the size'

        'start here'
        pause;

        %%%%%%Persistent Save
        [var_exist5]=persistent_var_exist_with_corruption(app,file_name_agg_check_chunk); %%%%%%%Check one more time if its there
        if var_exist5==0
            retry_save=1;
            while(retry_save==1)
                try
                    save(file_name_agg_check_chunk,'sub_array_agg_check_mc_dBm')
                    retry_save=0;
                catch
                    retry_save=1;
                    pause(1)
                end
            end
        end
    end
end
%sub_array_agg_check_mc_dBm