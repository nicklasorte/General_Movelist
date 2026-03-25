function results = validate_subchunk_agg_check_rev8_rev1(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chuck_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
%VALIDATE_SUBCHUNK_AGG_CHECK_REV8_REV1 Compare rev7 vs rev8 output and runtime.

args = {app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth, ...
    base_protection_pts,point_idx,on_list_bs,cell_sim_chuck_idx,rand_seed1, ...
    agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx};

t7=tic;
out7=subchunk_agg_check_rev7(args{:});
time_rev7=toc(t7);

t8=tic;
out8_a=subchunk_agg_check_rev8(args{:});
time_rev8=toc(t8);

out8_b=subchunk_agg_check_rev8(args{:});

results=struct();
results.size_equal=isequal(size(out7),size(out8_a));
results.nan_pattern_equal=isequal(isnan(out7),isnan(out8_a));

valid_mask=~isnan(out7) & ~isnan(out8_a);
if any(valid_mask,'all')
    diff_abs=abs(out8_a(valid_mask)-out7(valid_mask));
    results.max_abs_diff=max(diff_abs,[],'all');
    results.mean_abs_diff=mean(diff_abs,'all');
else
    results.max_abs_diff=NaN;
    results.mean_abs_diff=NaN;
end

results.rev8_reproducible=isequaln(out8_a,out8_b);
results.rev7_runtime_s=time_rev7;
results.rev8_runtime_s=time_rev8;
results.percent_improvement=((time_rev7-time_rev8)/time_rev7)*100;

tol=1e-9;
results.equivalent_within_tol=results.nan_pattern_equal && all(abs(out8_a(valid_mask)-out7(valid_mask))<=tol,'all');

fprintf('size_equal: %d\n',results.size_equal);
fprintf('nan_pattern_equal: %d\n',results.nan_pattern_equal);
fprintf('max_abs_diff: %.12g\n',results.max_abs_diff);
fprintf('mean_abs_diff: %.12g\n',results.mean_abs_diff);
fprintf('rev8_reproducible: %d\n',results.rev8_reproducible);
fprintf('equivalent_within_tol(%.1e): %d\n',tol,results.equivalent_within_tol);
fprintf('runtime_rev7_s: %.6f\n',results.rev7_runtime_s);
fprintf('runtime_rev8_s: %.6f\n',results.rev8_runtime_s);
fprintf('percent_improvement: %.3f\n',results.percent_improvement);

end
