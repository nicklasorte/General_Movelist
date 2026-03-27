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
        % 'Rev 7 Time:'
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



        % tic;
        % [sub_array_agg_check_mc_dBm]=subchunk_agg_check_maxazi_rev11(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);
        % tic;
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

        %results = benchmark_subchunk_agg_check_maxazi_rev10_rev13_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % % %        === REV10 vs REV13 REAL-INPUT BENCHMARK ===
        % % % AZI_CHUNK rev13: 32
        % % % Runtime rev10: 2.244750 s
        % % % Runtime rev13: 2.230879 s
        % % % Speedup rev10/rev13: 1.006x
        
        
        %results = validate_subchunk_agg_check_maxazi_rev11_rev13_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)

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



        %results = profile_subchunk_agg_check_maxazi_rev11_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % % % === PROFILE REV11 (REAL INPUTS) ===
        % % % AZI_CHUNK rev11: 128
        % % % 
        % % % Top contributors by total time:
        % % % Function                        TotalTime_s    SelfTime_s     NumCalls
        % % % ________________________________________________    ___________    __________    __________
        % % % 
        % % % {'init_run_folder_FSS_neigh_rev16_double_IN'   }       50.528         NaN                 1
        % % % {'parfor_randchunk_aggcheck_rev8_claude'       }       50.527         NaN                 1
        % % % {'profile_subchunk_agg_check_maxazi_rev11_real'}       50.527         NaN                 1
        % % % {'subchunk_agg_check_maxazi_rev11'             }       50.486         NaN                 1
        % % % {'monte_carlo_super_bs_eirp_dist_rev5'         }       45.499         NaN               416
        % % % {'interp1'                                     }       44.043         NaN        3.8064e+05
        % % % {'interp1>parseinputs'                         }       15.306         NaN        3.8064e+05
        % % % {'interp1>reshapeAndSortXandV'                 }       8.3156         NaN        3.8064e+05
        % % % {'interp1>sanitycheckmethod'                   }       4.7676         NaN        3.8064e+05
        % % % {'interp1>reshapeValuesV'                      }       3.1237         NaN        3.8064e+05
        % % % {'interp1>isScalarTextArg'                     }       2.6478         NaN        7.6128e+05
        % % % {'monte_carlo_clutter_rev3_app'                }       2.3514         NaN               416
        % % % {'monte_carlo_Pr_dBm_rev2_app'                 }       2.3012         NaN               416
        % % % {'cast'                                        }      0.55641         NaN        3.8064e+05
        % % % {'nearestpoint_app'                            }      0.34182         NaN              1674
        % % % 
        % % % 
        % % % Top contributors by self time:
        % % % Function                      TotalTime_s    SelfTime_s    NumCalls
        % % % ___________________________________________    ___________    __________    ________
        % % % 
        % % % {'nearestpoint_app'                       }       0.34182        NaN          1674
        % % % {'clear'                                  }      0.043223        NaN          1674
        % % % {'sub2ind'                                }     0.0033428        NaN            10
        % % % {'subchunk_agg_check_maxazi_rev11'        }        50.486        NaN             1
        % % % {'monte_carlo_Pr_dBm_rev2_app'            }        2.3012        NaN           416
        % % % {'monte_carlo_clutter_rev3_app'           }        2.3514        NaN           416
        % % % {'calc_sim_azimuths_rev3_360_azimuths_app'}     0.0007988        NaN             1
        % % % {'cellfun'                                }     0.0011541        NaN             4
        % % % {'isnan'                                  }       8.2e-06        NaN             2
        % % % {'deg2rad'                                }     0.0002608        NaN             4
        % % % {'rad2deg'                                }     0.0002257        NaN             2
        % % % {'mapgeodesy\private\expandScalarInputs'  }     0.0032992        NaN             1
        % % % {'maputils\private\abstractAngleConv'     }     0.0021029        NaN             3
        % % % {'mapgeodesy\private\parseDistAzInputs'   }      0.010467        NaN             1
        % % % {'toRadians'                              }     0.0020198        NaN             1
        % % % 
        % % % 
        % % % Explicit target function timings:
        % % % subchunk_agg_check_maxazi_rev11        total=101.013121 s | self=  0.000000 s | wall%=200.07% | calls=2
        % % % monte_carlo_Pr_dBm_rev2_app            total=  2.301193 s | self=  0.000000 s | wall%=  4.56% | calls=416
        % % % monte_carlo_super_bs_eirp_dist_rev5    total= 45.498819 s | self=  0.000000 s | wall%= 90.12% | calls=416
        % % % monte_carlo_clutter_rev3_app           total=  2.351379 s | self=  0.000000 s | wall%=  4.66% | calls=416
        % % % 
        % % % Path proxies (if visible in profiler):
        % % % off-axis gain build path proxy         total=  0.368085 s | self=  0.000000 s | wall%=  0.73% | calls=1676
        % % % aggregation path proxy                 total=101.202928 s | self=  0.000000 s | wall%=200.45% | calls=834
        % % % 
        % % % Recommendation: Optimize aggregation_path_proxy first (largest measured contributor: 101.202928 s).



        %results = validate_subchunk_agg_check_maxazi_rev11_rev14_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % % % === REV11 vs REV14 STATISTICAL VALIDATION ===
        % % % AZI_CHUNK rev11: 128
        % % % AZI_CHUNK rev14: 128
        % % % Timing runs each: 3
        % % % 
        % % % Runtime (seconds)
        % % % rev11 runs: [2.351019 2.280123 2.228370]
        % % % rev14 runs: [2.194176 2.040738 2.029484]
        % % % rev11 mean: 2.286504 s
        % % % rev14 mean: 2.088133 s
        % % % speedup rev11/rev14 (mean): 1.095x
        % % % 
        % % % Metric comparison (rev14 - rev11):
        % % % mean    | rev11=  -85.9484 | rev14=  -85.9484 | abs=0.0000 | allow=4.2974 | PASS
        % % % std     | rev11=    3.6424 | rev14=    3.6424 | abs=0.0000 | allow=0.5000 | PASS
        % % % min     | rev11=  -92.1428 | rev14=  -92.1428 | abs=0.0000 | allow=4.6071 | PASS
        % % % max     | rev11=  -69.9242 | rev14=  -69.9242 | abs=0.0000 | allow=3.4962 | PASS
        % % % median  | rev11=  -86.6390 | rev14=  -86.6390 | abs=0.0000 | allow=4.3320 | PASS
        % % % p90     | rev11=  -80.8032 | rev14=  -80.8032 | abs=0.0000 | allow=4.0402 | PASS
        % % % p95     | rev11=  -78.5316 | rev14=  -78.5316 | abs=0.0000 | allow=1.5706 | PASS
        % % % p99     | rev11=  -75.6253 | rev14=  -75.6253 | abs=0.0000 | allow=1.5125 | PASS
        % % % 
        % % % Upper-tail checks:
        % % % p95     | abs=0.0000 | allow=1.5706 | PASS
        % % % p99     | abs=0.0000 | allow=1.5125 | PASS
        % % % 
        % % % PASS: rev14 is statistically equivalent to rev11 under configured thresholds.


        %results = profile_subchunk_agg_check_maxazi_rev14_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % % % % === PROFILE REV14 (REAL INPUTS) ===
        % % % % AZI_CHUNK rev14: 128
        % % % % 
        % % % % Top contributors by total time:
        % % % % Function                        TotalTime_s    SelfTime_s    NumCalls
        % % % % ________________________________________________    ___________    __________    ________
        % % % % 
        % % % % {'init_run_folder_FSS_neigh_rev16_double_IN'   }       6.2543         NaN             1
        % % % % {'parfor_randchunk_aggcheck_rev8_claude'       }       6.2536         NaN             1
        % % % % {'profile_subchunk_agg_check_maxazi_rev14_real'}       6.2535         NaN             1
        % % % % {'subchunk_agg_check_maxazi_rev14'             }       6.1932         NaN             1
        % % % % {'monte_carlo_clutter_rev3_app'                }       2.3085         NaN           416
        % % % % {'monte_carlo_Pr_dBm_rev2_app'                 }       2.2745         NaN           416
        % % % % {'monte_carlo_super_bs_eirp_dist_rev6'         }       1.2662         NaN           416
        % % % % {'spline'                                      }        1.017         NaN           416
        % % % % {'pwch'                                        }      0.40472         NaN           416
        % % % % {'nearestpoint_app'                            }      0.35375         NaN          1674
        % % % % {'db2pow'                                      }      0.21042         NaN           416
        % % % % {'polyfun\private\chckxy'                      }     0.098891         NaN           416
        % % % % {'spparms'                                     }     0.071059         NaN          1248
        % % % % {'clear'                                       }     0.047711         NaN          1674
        % % % % {'spdiags'                                     }     0.041677         NaN           416
        % % % % 
        % % % % 
        % % % % Summary timing table (requested functions):
        % % % % subchunk_agg_check_maxazi_rev14     total= 12.446771 s | self=  0.000000 s | calls=2
        % % % % monte_carlo_super_bs_eirp_dist_rev6 total=  1.266235 s | self=  0.000000 s | calls=416
        % % % % interp1                             not visible in current profiler table
        % % % % monte_carlo_clutter_rev3_app        total=  2.308515 s | self=  0.000000 s | calls=416
        % % % % monte_carlo_Pr_dBm_rev2_app         total=  2.274501 s | self=  0.000000 s | calls=416
        % % % % 
        % % % % Baseline comparison vs rev11 evidence:
        % % % % interp1 total time: rev11=44.043 s, rev14=0.000 s, drop=100.0%
        % % % % interp1 calls:      rev11=380640, rev14=0, drop=100.0%
        % % % % helper total time:  rev11=45.499 s, rev14=1.266 s, drop=97.2%
        % % % % MATERIAL interp1 reduction: YES


        %results = validate_subchunk_agg_check_maxazi_rev11_rev14_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % % % === VALIDATION: REV11 vs REV14 (STATISTICAL) ===
        % % % Configured thresholds:
        % % % core metrics: max(abs, rel)=max(0.500 dB, 0.050*|rev11|)
        % % % tail metrics: max(abs, rel)=max(0.250 dB, 0.020*|rev11|)
        % % % 
        % % % Runtime summary (seconds):
        % % % rev11 runs: [4.544415 2.211883 2.187537]
        % % % rev14 runs: [1.152553 1.240468 1.349523]
        % % % rev11 mean: 2.981278
        % % % rev14 mean: 1.247514
        % % % speedup (rev11/rev14): 2.390x
        % % % 
        % % % Metric drift summary:
        % % % mean    | rev11=  -86.3015 | rev14=  -93.3731 | abs=  7.0716 | allow=  4.3151 | FAIL
        % % % std     | rev11=    3.5790 | rev14=    2.8940 | abs=  0.6850 | allow=  0.5000 | FAIL
        % % % min     | rev11=  -93.0552 | rev14=  -98.7057 | abs=  5.6505 | allow=  4.6528 | FAIL
        % % % max     | rev11=  -70.9126 | rev14=  -81.8157 | abs= 10.9031 | allow=  3.5456 | FAIL
        % % % median  | rev11=  -86.9296 | rev14=  -94.0070 | abs=  7.0773 | allow=  4.3465 | FAIL
        % % % p90     | rev11=  -81.1614 | rev14=  -89.3016 | abs=  8.1402 | allow=  4.0581 | FAIL
        % % % p95     | rev11=  -79.6045 | rev14=  -87.6819 | abs=  8.0773 | allow=  1.5921 | FAIL
        % % % p99     | rev11=  -76.0443 | rev14=  -83.4923 | abs=  7.4480 | allow=  1.5209 | FAIL
        % % % 
        % % % Upper-tail emphasis:
        % % % p95     | abs=  8.0773 | allow=  1.5921 | FAIL
        % % % p99     | abs=  7.4480 | allow=  1.5209 | FAIL
        % % % 
        % % % FAIL: rev14 drift exceeded configured thresholds (fail-closed).


        %results = validate_subchunk_agg_check_maxazi_rev11_rev15_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % % % === VALIDATION: REV11 vs REV15 (STATISTICAL) ===
        % % % Thresholds (fail-closed): core=max(0.250 dB, 0.020*|rev11|), tail=max(0.150 dB, 0.010*|rev11|)
        % % % 
        % % % Runtime summary (seconds):
        % % % rev11 runs: [2.563557 2.177046 2.854717]
        % % % rev15 runs: [2.270930 2.205475 4.841164]
        % % % rev11 mean: 2.531773
        % % % rev15 mean: 3.105856
        % % % speedup (rev11/rev15): 0.815x
        % % % 
        % % % Metric drift summary:
        % % % mean    | rev11=  -86.2571 | rev15=  -86.2571 | abs=  0.0000 | allow=  1.7251 | PASS
        % % % std     | rev11=    3.6957 | rev15=    3.6957 | abs=  0.0000 | allow=  0.2500 | PASS
        % % % min     | rev11=  -93.2585 | rev15=  -93.2585 | abs=  0.0000 | allow=  1.8652 | PASS
        % % % max     | rev11=  -69.0087 | rev15=  -69.0087 | abs=  0.0000 | allow=  1.3802 | PASS
        % % % median  | rev11=  -87.1254 | rev15=  -87.1254 | abs=  0.0000 | allow=  1.7425 | PASS
        % % % p90     | rev11=  -80.8831 | rev15=  -80.8831 | abs=  0.0000 | allow=  1.6177 | PASS
        % % % p95     | rev11=  -79.2806 | rev15=  -79.2806 | abs=  0.0000 | allow=  0.7928 | PASS
        % % % p99     | rev11=  -74.8681 | rev15=  -74.8681 | abs=  0.0000 | allow=  0.7487 | PASS
        % % % 
        % % % Upper-tail emphasis:
        % % % p95     | abs=  0.0000 | allow=  0.7928 | PASS
        % % % p99     | abs=  0.0000 | allow=  0.7487 | PASS
        % % % 
        % % % PASS: rev15 statistical behavior is within configured thresholds.


        %results=validate_monte_carlo_super_bs_eirp_dist_rev5_rev6(app,cell_aas_dist_data,array_bs_azi_data,agg_check_reliability,rand_seed1,cell_sim_chunk_idx,sub_point_idx)        
        % % % === HELPER VALIDATION: rev5 vs rev6 ===
        % % % X (reliability grid) shape: [1 x 47]
        % % % Y (EIRP values) shape:      [915 x 47]
        % % % Query shape:                [915 x 416]
        % % % max abs diff:  2.299483e+01
        % % % mean abs diff: 7.897544e+00
        % % % max rel diff:  4.524028e+05
        % % % mean rel diff: 1.429894e+01
        % % % Significant-diff clustering: endpoints=1.0%, breakpoints=4.4%, clamped=0.0%
        % % % worst[1] row=6 col=177 query=99.9901 rev5=10.7457 rev6=-12.2491 abs=2.299e+01 rel=2.140e+00
        % % % worst[2] row=899 col=239 query=0.00625573 rev5=-12.2451 rev6=10.7479 abs=2.299e+01 rel=1.878e+00
        % % % worst[3] row=905 col=4 query=0.00859869 rev5=-12.2433 rev6=10.749 abs=2.299e+01 rel=1.878e+00
        % % % worst[4] row=900 col=32 query=0.00931866 rev5=-12.2428 rev6=10.7493 abs=2.299e+01 rel=1.878e+00
        % % % worst[5] row=32 col=78 query=99.9963 rev5=10.7484 rev6=-12.2374 abs=2.299e+01 rel=2.139e+00
        % % % Helper comparison result: FAIL
 

        %results = profile_subchunk_agg_check_maxazi_rev15_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % % %         === PROFILE REV15 (REAL INPUTS) ===
        % % % AZI_CHUNK rev15: 128
        % % %
        % % % Top contributors by total time:
        % % %                         Function                        TotalTime_s    SelfTime_s    NumCalls
        % % %     ________________________________________________    ___________    __________    ________
        % % %
        % % %     {'init_run_folder_FSS_neigh_rev16_double_IN'   }       4.8707         NaN             1
        % % %     {'parfor_randchunk_aggcheck_rev8_claude'       }       4.8697         NaN             1
        % % %     {'profile_subchunk_agg_check_maxazi_rev15_real'}       4.8696         NaN             1
        % % %     {'subchunk_agg_check_maxazi_rev15'             }       4.7699         NaN             1
        % % %     {'monte_carlo_Pr_dBm_rev2_app'                 }        2.293         NaN           416
        % % %     {'monte_carlo_super_bs_eirp_dist_rev6'         }       1.7391         NaN           416
        % % %     {'spline'                                      }       1.3759         NaN           416
        % % %     {'pwch'                                        }      0.60167         NaN           416
        % % %     {'nearestpoint_app'                            }      0.42125         NaN          1674
        % % %     {'monte_carlo_clutter_rev4_app'                }      0.38719         NaN           416
        % % %     {'db2pow'                                      }      0.18386         NaN           416
        % % %     {'polyfun\private\chckxy'                      }      0.13199         NaN           416
        % % %     {'spparms'                                     }     0.095034         NaN          1248
        % % %     {'sub2ind'                                     }      0.06059         NaN           842
        % % %     {'clear'                                       }     0.058507         NaN          1674
        % % %     {'spdiags'                                     }     0.055096         NaN           416
        % % %     {'mkpp'                                        }     0.040919         NaN           416
        % % %     {'rng'                                         }     0.027059         NaN             1
        % % %     {'azimuth'                                     }     0.026945         NaN             1
        % % %     {'distance'                                    }     0.025959         NaN             1
        % % %
        % % %
        % % % Summary timing table (requested functions):
        % % %                    Function                    TotalTime_s    Calls    PctWall
        % % %     _______________________________________    ___________    _____    _______
        % % %
        % % %     {'subchunk_agg_check_maxazi_rev15'    }       9.6395         2     199.35
        % % %     {'monte_carlo_clutter_rev4_app'       }      0.38719       416     8.0076
        % % %     {'monte_carlo_Pr_dBm_rev2_app'        }        2.293       416     47.422
        % % %     {'monte_carlo_super_bs_eirp_dist_rev6'}       1.7391       416     35.966
        % % %     {'nearestpoint_app'                   }      0.42125      1674      8.712
        % % %     {'db2pow'                             }      0.18386       416     3.8024
        % % %
        % % % Clutter helper comparison vs rev14 baseline: rev14=2.309 s, rev15=0.387 s, drop=83.2%
        % % % Material clutter-time drop (>=10%): YES
        % % % Top bottleneck among tracked functions: subchunk_agg_check_maxazi_rev15 (9.639 s)




        %results = validate_subchunk_agg_check_maxazi_rev14_rev15_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        %%%%%%%%%%%%%%%%%%%%Updated 15
        % % % === REV14 vs REV15 STATISTICAL VALIDATION ===
        % % % AZI_CHUNK rev14: 128
        % % % AZI_CHUNK rev15: 128
        % % % Thresholds: abs<=0.500 dB, rel<=0.050, tail_abs<=0.350 dB
        % % % Runtime rev14: 1.391056 s
        % % % Runtime rev15: 1.152978 s
        % % % Speedup rev14/rev15: 1.206x
        % % %
        % % % Metric comparison (rev15 - rev14):
        % % %   mean    | rev14=  -93.3065 | rev15=  -93.3065 | abs=0.0000 | allow=4.6653 | PASS
        % % %   std     | rev14=    2.8838 | rev15=    2.8838 | abs=0.0000 | allow=0.5000 | PASS
        % % %   min     | rev14=  -98.2261 | rev15=  -98.2261 | abs=0.0000 | allow=4.9113 | PASS
        % % %   max     | rev14=  -82.9343 | rev15=  -82.9343 | abs=0.0000 | allow=4.1467 | PASS
        % % %   median  | rev14=  -93.9497 | rev15=  -93.9497 | abs=0.0000 | allow=4.6975 | PASS
        % % %   p90     | rev14=  -89.2605 | rev15=  -89.2605 | abs=0.0000 | allow=4.4630 | PASS
        % % %   p95     | rev14=  -87.9325 | rev15=  -87.9325 | abs=0.0000 | allow=4.3966 | PASS
        % % %   p99     | rev14=  -85.1294 | rev15=  -85.1294 | abs=0.0000 | allow=4.2565 | PASS
        % % %
        % % % Upper-tail checks (strict):
        % % %   p95     | abs=0.0000 | allow=0.3500 | PASS
        % % %   p99     | abs=0.0000 | allow=0.3500 | PASS
        % % %
        % % % PASS: rev15 is statistically equivalent to rev14 under configured thresholds.

        %results = validate_subchunk_agg_check_maxazi_rev11_rev18_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % === VALIDATION: REV11 vs REV18 (STATISTICAL) ===
        % Thresholds (fail-closed): core=max(0.250 dB, 0.020*|rev11|), tail=max(0.150 dB, 0.010*|rev11|)
        % 
        % Runtime summary (seconds):
        % rev11 runs: [6.224812 4.437098 4.229300]
        % rev18 runs: [4.224717 4.783562 4.233545]
        % rev11 mean: 4.963736
        % rev18 mean: 4.413941
        % speedup (rev11/rev18): 1.125x
        % 
        % Metric drift summary:
        % mean    | rev11=  -86.1563 | rev18=  -86.1563 | abs=  0.0000 | allow=  1.7231 | PASS
        % std     | rev11=    3.8276 | rev18=    3.8276 | abs=  0.0000 | allow=  0.2500 | PASS
        % min     | rev11=  -92.0813 | rev18=  -92.0813 | abs=  0.0000 | allow=  1.8416 | PASS
        % max     | rev11=  -72.3269 | rev18=  -72.3269 | abs=  0.0000 | allow=  1.4465 | PASS
        % median  | rev11=  -87.0743 | rev18=  -87.0743 | abs=  0.0000 | allow=  1.7415 | PASS
        % p90     | rev11=  -80.4582 | rev18=  -80.4582 | abs=  0.0000 | allow=  1.6092 | PASS
        % p95     | rev11=  -78.4456 | rev18=  -78.4456 | abs=  0.0000 | allow=  0.7845 | PASS
        % p99     | rev11=  -75.0901 | rev18=  -75.0901 | abs=  0.0000 | allow=  0.7509 | PASS
        % 
        % Upper-tail emphasis:
        % p95     | rev11=  -78.4456 | rev18=  -78.4456 | abs=  0.0000 | allow=  0.7845 | PASS
        % p99     | rev11=  -75.0901 | rev18=  -75.0901 | abs=  0.0000 | allow=  0.7509 | PASS
        % 
        % PASS / FAIL: PASS




        %results = profile_subchunk_agg_check_maxazi_rev18_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % % % === PROFILE REV18 (REAL INPUTS, WITH REV11 BASELINE) ===
        % % % AZI_CHUNK rev11: 128 | rev18: 128
        % % % 
        % % % Top contributors by total time (rev18):
        % % % Function                                 TotalTime_s    SelfTime_s     NumCalls
        % % % _________________________________________________________________    ___________    __________    __________
        % % % 
        % % % {'init_run_folder_FSS_neigh_rev16_double_IN'                    }       81.628         NaN                 1
        % % % {'parfor_randchunk_aggcheck_rev8_claude'                        }       81.627         NaN                 1
        % % % {'profile_subchunk_agg_check_maxazi_rev18_real'                 }       81.627         NaN                 1
        % % % {'profile_subchunk_agg_check_maxazi_rev18_real>run_profile_once'}       81.627         NaN                 1
        % % % {'subchunk_agg_check_maxazi_rev18'                              }       81.541         NaN                 1
        % % % {'monte_carlo_super_bs_eirp_dist_rev5'                          }       77.312         NaN               416
        % % % {'interp1'                                                      }        74.51         NaN        3.8064e+05
        % % % {'interp1>parseinputs'                                          }       24.429         NaN        3.8064e+05
        % % % {'interp1>reshapeAndSortXandV'                                  }       13.947         NaN        3.8064e+05
        % % % {'interp1>sanitycheckmethod'                                    }       7.0736         NaN        3.8064e+05
        % % % {'interp1>reshapeValuesV'                                       }       5.0838         NaN        3.8064e+05
        % % % {'interp1>isScalarTextArg'                                      }       4.6321         NaN        7.6128e+05
        % % % {'monte_carlo_Pr_dBm_rev2_app'                                  }       3.2351         NaN               416
        % % % {'cast'                                                         }       1.4359         NaN        3.8064e+05
        % % % {'nearestpoint_app'                                             }      0.54881         NaN              1674
        % % % {'monte_carlo_clutter_rev5_app'                                 }      0.50549         NaN               416
        % % % {'db2pow'                                                       }      0.29382         NaN               416
        % % % {'sub2ind'                                                      }     0.076386         NaN               842
        % % % {'clear'                                                        }      0.07311         NaN              1674
        % % % {'rng'                                                          }     0.019095         NaN                 1
        % % % 
        % % % 
        % % % Summary timing table (requested functions):
        % % % subchunk_agg_check_maxazi_rev18            total=244.795085 s | self=  0.000000 s | calls=3
        % % % monte_carlo_clutter_rev5_app               total=  0.505489 s | self=  0.000000 s | calls=416
        % % % monte_carlo_Pr_dBm_rev2_app                total=  3.235080 s | self=  0.000000 s | calls=416
        % % % monte_carlo_super_bs_eirp_dist_rev5        total= 77.312248 s | self=  0.000000 s | calls=416
        % % % nearestpoint_app                           total=  0.548810 s | self=  0.000000 s | calls=1674
        % % % db2pow                                     total=  0.293816 s | self=  0.000000 s | calls=416
        % % % 
        % % % Runtime comparison vs rev11 baseline (same run harness):
        % % % subchunk total: rev11=82.258190 s | rev18=81.541516 s | speedup=1.009x
        % % % clutter helper: rev11 rev3=3.306629 s | rev18 rev5=0.505489 s | drop=84.71%
        % % % MATERIAL clutter helper drop vs rev11: YES
        % % % New top bottleneck (among requested targets): monte_carlo_super_bs_eirp_dist_rev5




        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%Update EIPR dist with Claude Code: monte_carlo_super_bs_eirp_dist_rev8
        %results = validate_subchunk_agg_check_maxazi_rev11_rev19_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % % % === VALIDATION: REV11 vs REV19 (STATISTICAL) ===
        % % % Thresholds (fail-closed): core=max(0.250 dB, 0.020*|rev11|), tail=max(0.150 dB, 0.010*|rev11|)
        % % % 
        % % % Runtime summary (seconds):
        % % % rev11 runs: [2.732172 2.881137 2.924540]
        % % % rev19 runs: [1.811989 1.478093 1.923037]
        % % % rev11 mean: 2.845950
        % % % rev19 mean: 1.737706
        % % % speedup (rev11/rev19): 1.638x
        % % % 
        % % % Metric drift summary:
        % % % mean    | rev11=  -86.0872 | rev19=  -86.0872 | abs=  0.0000 | allow=  1.7217 | PASS
        % % % std     | rev11=    3.7891 | rev19=    3.7891 | abs=  0.0000 | allow=  0.2500 | PASS
        % % % min     | rev11=  -93.2863 | rev19=  -93.2863 | abs=  0.0000 | allow=  1.8657 | PASS
        % % % max     | rev11=  -71.6779 | rev19=  -71.6779 | abs=  0.0000 | allow=  1.4336 | PASS
        % % % median  | rev11=  -87.0000 | rev19=  -87.0000 | abs=  0.0000 | allow=  1.7400 | PASS
        % % % p90     | rev11=  -80.8385 | rev19=  -80.8385 | abs=  0.0000 | allow=  1.6168 | PASS
        % % % p95     | rev11=  -78.1267 | rev19=  -78.1267 | abs=  0.0000 | allow=  0.7813 | PASS
        % % % p99     | rev11=  -74.1601 | rev19=  -74.1601 | abs=  0.0000 | allow=  0.7416 | PASS
        % % % 
        % % % Upper-tail emphasis:
        % % % p95     | rev11=  -78.1267 | rev19=  -78.1267 | abs=  0.0000 | allow=  0.7813 | PASS
        % % % p99     | rev11=  -74.1601 | rev19=  -74.1601 | abs=  0.0000 | allow=  0.7416 | PASS
        % % % 
        % % % PASS / FAIL: PASS


        %%%%%%%%%Update EIPR dist with Claude Code: monte_carlo_super_bs_eirp_dist_rev8
        %results = profile_subchunk_agg_check_maxazi_rev19_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % % % === PROFILE REV19 (REAL INPUTS, WITH REV11 BASELINE) ===
        % % % AZI_CHUNK rev11: 128 | rev19: 128
        % % % 
        % % % Top contributors by total time (rev19):
        % % % Function                                 TotalTime_s    SelfTime_s    NumCalls
        % % % _________________________________________________________________    ___________    __________    ________
        % % % 
        % % % {'init_run_folder_FSS_neigh_rev16_double_IN'                    }       5.0425         NaN             1
        % % % {'parfor_randchunk_aggcheck_rev8_claude'                        }       5.0417         NaN             1
        % % % {'profile_subchunk_agg_check_maxazi_rev19_real'                 }       5.0416         NaN             1
        % % % {'profile_subchunk_agg_check_maxazi_rev19_real>run_profile_once'}       5.0415         NaN             1
        % % % {'subchunk_agg_check_maxazi_rev19'                              }       4.9893         NaN             1
        % % % {'monte_carlo_Pr_dBm_rev2_app'                                  }       2.6116         NaN           416
        % % % {'monte_carlo_super_bs_eirp_dist_rev8'                          }        1.602         NaN           416
        % % % {'spline'                                                       }       1.2651         NaN           416
        % % % {'pwch'                                                         }      0.53736         NaN           416
        % % % {'nearestpoint_app'                                             }      0.42285         NaN          1674
        % % % {'monte_carlo_clutter_rev5_app'                                 }      0.41632         NaN           416
        % % % {'db2pow'                                                       }      0.21273         NaN           416
        % % % {'polyfun\private\chckxy'                                       }      0.12786         NaN           416
        % % % {'spparms'                                                      }     0.096435         NaN          1248
        % % % {'sub2ind'                                                      }     0.063288         NaN           842
        % % % {'clear'                                                        }     0.061782         NaN          1674
        % % % {'spdiags'                                                      }     0.050258         NaN           416
        % % % {'mkpp'                                                         }     0.038203         NaN           416
        % % % {'azimuth'                                                      }     0.012871         NaN             1
        % % % {'distance'                                                     }     0.012451         NaN             1
        % % % 
        % % % 
        % % % Summary timing table (requested functions):
        % % % subchunk_agg_check_maxazi_rev19            total= 15.072470 s | self=  0.000000 s | calls=3
        % % % monte_carlo_clutter_rev5_app               total=  0.416322 s | self=  0.000000 s | calls=416
        % % % monte_carlo_Pr_dBm_rev2_app                total=  2.611577 s | self=  0.000000 s | calls=416
        % % % monte_carlo_super_bs_eirp_dist_rev5        not visible in current profiler table
        % % % nearestpoint_app                           total=  0.422850 s | self=  0.000000 s | calls=1674
        % % % db2pow                                     total=  0.212727 s | self=  0.000000 s | calls=416
        % % % 
        % % % Runtime comparison vs rev11 baseline (same run harness):
        % % % subchunk total: rev11=67.720035 s | rev19=4.989914 s | speedup=13.571x
        % % % clutter helper: rev11 rev3=2.556206 s | rev19 rev5=0.416322 s | drop=83.71%
        % % % MATERIAL clutter helper drop vs rev11: YES
        % % % New top bottleneck (among requested targets): monte_carlo_Pr_dBm_rev2_app
   



        %%%%%%%%%%Claude Code to improve PR dBm dist
        %results = validate_subchunk_agg_check_maxazi_rev11_rev20_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
        % % % === VALIDATION: REV11 vs REV20 (STATISTICAL) ===
        % % % Thresholds (fail-closed): core=max(0.250 dB, 0.020*|rev11|), tail=max(0.150 dB, 0.010*|rev11|)
        % % % 
        % % % Runtime summary (seconds):
        % % % rev11 runs: [2.837705 7.584150 7.511614]
        % % % rev20 runs: [3.852031 2.462068 2.554941]
        % % % rev11 mean: 5.977823
        % % % rev20 mean: 2.956347
        % % % speedup (rev11/rev20): 2.022x
        % % % 
        % % % Metric drift summary:
        % % % mean    | rev11=  -86.1107 | rev20=  -86.1107 | abs=  0.0000 | allow=  1.7222 | PASS
        % % % std     | rev11=    3.5728 | rev20=    3.5728 | abs=  0.0000 | allow=  0.2500 | PASS
        % % % min     | rev11=  -92.3627 | rev20=  -92.3627 | abs=  0.0000 | allow=  1.8473 | PASS
        % % % max     | rev11=  -72.7477 | rev20=  -72.7477 | abs=  0.0000 | allow=  1.4550 | PASS
        % % % median  | rev11=  -86.7787 | rev20=  -86.7787 | abs=  0.0000 | allow=  1.7356 | PASS
        % % % p90     | rev11=  -81.1711 | rev20=  -81.1711 | abs=  0.0000 | allow=  1.6234 | PASS
        % % % p95     | rev11=  -79.1496 | rev20=  -79.1496 | abs=  0.0000 | allow=  0.7915 | PASS
        % % % p99     | rev11=  -75.0788 | rev20=  -75.0788 | abs=  0.0000 | allow=  0.7508 | PASS
        % % % 
        % % % Upper-tail emphasis:
        % % % p95     | rev11=  -79.1496 | rev20=  -79.1496 | abs=  0.0000 | allow=  0.7915 | PASS
        % % % p99     | rev11=  -75.0788 | rev20=  -75.0788 | abs=  0.0000 | allow=  0.7508 | PASS
        % % % 
        % % % PASS / FAIL: PASS


        %results = profile_subchunk_agg_check_maxazi_rev20_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)    
        % % % % === PROFILE REV20 (REAL INPUTS, WITH REV11 BASELINE) ===
        % % % % AZI_CHUNK rev11: 128 | rev20: 128
        % % % % 
        % % % % Top contributors by total time (rev20):
        % % % % Function                                 TotalTime_s    SelfTime_s    NumCalls
        % % % % _________________________________________________________________    ___________    __________    ________
        % % % % 
        % % % % {'init_run_folder_FSS_neigh_rev16_double_IN'                    }       3.8413         NaN             1
        % % % % {'parfor_randchunk_aggcheck_rev8_claude'                        }       3.8404         NaN             1
        % % % % {'profile_subchunk_agg_check_maxazi_rev20_real'                 }       3.8403         NaN             1
        % % % % {'profile_subchunk_agg_check_maxazi_rev20_real>run_profile_once'}       3.8402         NaN             1
        % % % % {'subchunk_agg_check_maxazi_rev20'                              }       3.7873         NaN             1
        % % % % {'monte_carlo_super_bs_eirp_dist_rev8'                          }       2.4665         NaN           416
        % % % % {'spline'                                                       }       1.9132         NaN           416
        % % % % {'pwch'                                                         }        0.832         NaN           416
        % % % % {'monte_carlo_clutter_rev5_app'                                 }      0.60536         NaN           416
        % % % % {'nearestpoint_app'                                             }      0.36703         NaN           842
        % % % % {'monte_carlo_Pr_dBm_rev3_app'                                  }      0.31568         NaN           416
        % % % % {'db2pow'                                                       }      0.22625         NaN           416
        % % % % {'polyfun\private\chckxy'                                       }      0.17263         NaN           416
        % % % % {'spparms'                                                      }      0.12769         NaN          1248
        % % % % {'sub2ind'                                                      }      0.11877         NaN          1674
        % % % % {'discretize'                                                   }      0.10171         NaN           416
        % % % % {'spdiags'                                                      }     0.076884         NaN           416
        % % % % {'mkpp'                                                         }     0.068848         NaN           416
        % % % % {'clear'                                                        }      0.06665         NaN           842
        % % % % {'discretize>parseNVpair'                                       }     0.025896         NaN           416
        % % % % 
        % % % % 
        % % % % Summary timing table (requested functions):
        % % % % subchunk_agg_check_maxazi_rev20            total= 11.467723 s | self=  0.000000 s | calls=3
        % % % % monte_carlo_clutter_rev5_app               total=  0.605359 s | self=  0.000000 s | calls=416
        % % % % monte_carlo_Pr_dBm_rev3_app                total=  0.315678 s | self=  0.000000 s | calls=416
        % % % % monte_carlo_Pr_dBm_rev2_app (residual)     not visible in current profiler table
        % % % % monte_carlo_super_bs_eirp_dist_rev8        total=  2.466473 s | self=  0.000000 s | calls=416
        % % % % nearestpoint_app                           total=  0.367028 s | self=  0.000000 s | calls=842
        % % % % db2pow                                     total=  0.226254 s | self=  0.000000 s | calls=416
        % % % % discretize                                 total=  0.136947 s | self=  0.000000 s | calls=2080
        % % % % 
        % % % % Runtime comparison vs rev11 baseline (same run harness):
        % % % % subchunk total: rev11=77.390047 s | rev20=3.788642 s | speedup=20.427x
        % % % % Pr helper: rev11 rev2=2.618841 s | rev20 rev3=0.315678 s | drop=87.95%
        % % % % MATERIAL Pr helper drop vs rev11: YES
        % % % % New top bottleneck (among requested targets): monte_carlo_super_bs_eirp_dist_rev8


        % % %%%%%%%%%%%%%%This is the current function to use.
        % 'Rev 11 time:'
        % tic;
        % [sub_array_agg_check_mc_dBm]=subchunk_agg_check_maxazi_rev11(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);
        % toc;
        % %[sub_array_agg_check_mc_dBm]=subchunk_agg_check_maxazi_rev19(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);
        
        %'Rev20 time:'
        %tic;
        [sub_array_agg_check_mc_dBm]=subchunk_agg_check_maxazi_rev20(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);
        %toc;
        %%%%Rev 11: 128 vs 24: 2.7 to 2.3
        %%%%Rev 20 is good to go.:Rev 11 vs Rev20: 3.05 seconds vs 1.60seconds

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