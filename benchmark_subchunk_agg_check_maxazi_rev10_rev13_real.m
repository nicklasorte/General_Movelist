function results = benchmark_subchunk_agg_check_maxazi_rev10_rev13_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
%BENCHMARK_SUBCHUNK_AGG_CHECK_MAXAZI_REV10_REV13_REAL
% Runtime benchmark for rev10 vs rev13 using identical real inputs.

if exist('subchunk_agg_check_maxazi_rev10','file')~=2
    error('benchmark_subchunk_agg_check_maxazi_rev10_rev13_real:MissingRev10', ...
        'subchunk_agg_check_maxazi_rev10.m was not found on MATLAB path.');
end
if exist('subchunk_agg_check_maxazi_rev13','file')~=2
    error('benchmark_subchunk_agg_check_maxazi_rev10_rev13_real:MissingRev13', ...
        'subchunk_agg_check_maxazi_rev13.m was not found on MATLAB path.');
end

opts = struct();
opts.AziChunkRev13 = 32;

fprintf('\n=== REV10 vs REV13 REAL-INPUT BENCHMARK ===\n');
fprintf('AZI_CHUNK rev13: %d\n',opts.AziChunkRev13);

rev10_tic=tic;
out_rev10=subchunk_agg_check_maxazi_rev10(app,cell_aas_dist_data,array_bs_azi_data, ...
    radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
    cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
    custom_antenna_pattern,sub_point_idx); %#ok<NASGU>
runtime_rev10=toc(rev10_tic);

rev13_tic=tic;
out_rev13=subchunk_agg_check_maxazi_rev13(app,cell_aas_dist_data,array_bs_azi_data, ...
    radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
    cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
    custom_antenna_pattern,sub_point_idx,opts.AziChunkRev13); %#ok<NASGU>
runtime_rev13=toc(rev13_tic);

speedup = runtime_rev10 ./ runtime_rev13;

fprintf('Runtime rev10: %.6f s\n',runtime_rev10);
fprintf('Runtime rev13: %.6f s\n',runtime_rev13);
fprintf('Speedup rev10/rev13: %.3fx\n',speedup);

results = struct();
results.runtime_rev10 = runtime_rev10;
results.runtime_rev13 = runtime_rev13;
results.speedup = speedup;
results.azi_chunk_rev13 = opts.AziChunkRev13;

end
