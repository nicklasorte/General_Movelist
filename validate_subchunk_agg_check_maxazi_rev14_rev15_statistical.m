function results = validate_subchunk_agg_check_maxazi_rev14_rev15_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
%VALIDATE_SUBCHUNK_AGG_CHECK_MAXAZI_REV14_REV15_STATISTICAL
% Statistical and runtime comparison for rev14 vs rev15 using identical real inputs.

must_exist('subchunk_agg_check_maxazi_rev14','MissingRev14');
must_exist('subchunk_agg_check_maxazi_rev15','MissingRev15');

% Fixed thresholds; fail closed on exceedance.
opts=struct();
opts.AziChunkRev14=128;
opts.AziChunkRev15=128;
opts.AbsDiffThreshold_dB=0.50;
opts.RelDiffThreshold=0.05;
opts.TailAbsDiffThreshold_dB=0.35;
opts.EnableP999=true;

fprintf('\n=== REV14 vs REV15 STATISTICAL VALIDATION ===\n');
fprintf('AZI_CHUNK rev14: %d\n',opts.AziChunkRev14);
fprintf('AZI_CHUNK rev15: %d\n',opts.AziChunkRev15);
fprintf('Thresholds: abs<=%.3f dB, rel<=%.3f, tail_abs<=%.3f dB\n', ...
    opts.AbsDiffThreshold_dB,opts.RelDiffThreshold,opts.TailAbsDiffThreshold_dB);

rev14_tic=tic;
out_rev14=subchunk_agg_check_maxazi_rev14(app,cell_aas_dist_data,array_bs_azi_data, ...
    radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
    cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
    custom_antenna_pattern,sub_point_idx,opts.AziChunkRev14);
runtime_rev14=toc(rev14_tic);

rev15_tic=tic;
out_rev15=subchunk_agg_check_maxazi_rev15(app,cell_aas_dist_data,array_bs_azi_data, ...
    radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
    cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
    custom_antenna_pattern,sub_point_idx,opts.AziChunkRev15);
runtime_rev15=toc(rev15_tic);

speedup=runtime_rev14./runtime_rev15;

x14=out_rev14(:);
x15=out_rev15(:);
finite_mask=isfinite(x14) & isfinite(x15);
x14=x14(finite_mask);
x15=x15(finite_mask);

if isempty(x14)
    error('validate_subchunk_agg_check_maxazi_rev14_rev15_statistical:NoFiniteSamples', ...
        'No finite paired samples available for statistical comparison.');
end

metrics={'mean','std','min','max','median','p90','p95','p99'};
quantiles=[0.90 0.95 0.99];

s14=build_summary(x14,quantiles);
s15=build_summary(x15,quantiles);
if opts.EnableP999 && numel(x14)>=1000
    metrics=[metrics {'p99_9'}]; %#ok<AGROW>
    s14.p99_9=quantile(x14,0.999);
    s15.p99_9=quantile(x15,0.999);
end

diff_table=struct();
pass_flags=true(1,numel(metrics));
for k=1:numel(metrics)
    m=metrics{k};
    v14=s14.(m);
    v15=s15.(m);
    abs_diff=abs(v15-v14);
    rel_diff=abs_diff/max(abs(v14),eps);
    allowed_abs=max(opts.AbsDiffThreshold_dB,opts.RelDiffThreshold*max(abs(v14),1));

    diff_table.(m)=struct('rev14',v14,'rev15',v15,'abs_diff',abs_diff, ...
        'rel_diff',rel_diff,'allowed_abs',allowed_abs,'pass',abs_diff<=allowed_abs);
    pass_flags(k)=diff_table.(m).pass;
end

tail_fields=intersect({'p95','p99','p99_9'},metrics,'stable');
tail_check=struct();
tail_pass=true;
for k=1:numel(tail_fields)
    tf=tail_fields{k};
    abs_diff=diff_table.(tf).abs_diff;
    allowed=min(diff_table.(tf).allowed_abs,opts.TailAbsDiffThreshold_dB);
    pass_tf=abs_diff<=allowed;
    tail_check.(tf)=struct('abs_diff',abs_diff,'allowed_abs',allowed,'pass',pass_tf);
    tail_pass=tail_pass && pass_tf;
end

overall_pass=all(pass_flags) && tail_pass;

fprintf('Runtime rev14: %.6f s\n',runtime_rev14);
fprintf('Runtime rev15: %.6f s\n',runtime_rev15);
fprintf('Speedup rev14/rev15: %.3fx\n',speedup);

fprintf('\nMetric comparison (rev15 - rev14):\n');
for k=1:numel(metrics)
    m=metrics{k};
    fprintf('  %-7s | rev14=%10.4f | rev15=%10.4f | abs=%.4f | allow=%.4f | %s\n', ...
        m,diff_table.(m).rev14,diff_table.(m).rev15,diff_table.(m).abs_diff, ...
        diff_table.(m).allowed_abs,passfail(diff_table.(m).pass));
end

fprintf('\nUpper-tail checks (strict):\n');
for k=1:numel(tail_fields)
    tf=tail_fields{k};
    fprintf('  %-7s | abs=%.4f | allow=%.4f | %s\n',tf,tail_check.(tf).abs_diff, ...
        tail_check.(tf).allowed_abs,passfail(tail_check.(tf).pass));
end

if overall_pass
    fprintf('\nPASS: rev15 is statistically equivalent to rev14 under configured thresholds.\n');
else
    fprintf('\nFAIL: rev15 drift exceeded configured thresholds.\n');
    error('validate_subchunk_agg_check_maxazi_rev14_rev15_statistical:DriftExceeded', ...
        'Fail-closed: statistical drift exceeded configured thresholds.');
end

results=struct();
results.runtime_rev14_s=runtime_rev14;
results.runtime_rev15_s=runtime_rev15;
results.speedup_rev14_over_rev15=speedup;
results.n_samples=numel(x14);
results.metrics=metrics;
results.summary_rev14=s14;
results.summary_rev15=s15;
results.diffs=diff_table;
results.upper_tail=tail_check;
results.thresholds=opts;
results.pass=overall_pass;

end

function s=build_summary(x,q)
s=struct();
s.mean=mean(x,'omitnan');
s.std=std(x,0,'omitnan');
s.min=min(x,[],'omitnan');
s.max=max(x,[],'omitnan');
s.median=median(x,'omitnan');
qx=quantile(x,q);
s.p90=qx(1);
s.p95=qx(2);
s.p99=qx(3);
end

function txt=passfail(tf)
if tf
    txt='PASS';
else
    txt='FAIL';
end
end

function must_exist(fname,errid)
if exist(fname,'file')~=2
    error(['validate_subchunk_agg_check_maxazi_rev14_rev15_statistical:' errid], ...
        '%s.m was not found on MATLAB path.',fname);
end
end
