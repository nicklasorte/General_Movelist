function results = validate_subchunk_agg_check_maxazi_rev11_rev12_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
%VALIDATE_SUBCHUNK_AGG_CHECK_MAXAZI_REV11_REV12_STATISTICAL
% Statistical and runtime comparison for rev11 vs rev12 using identical real inputs.

if exist('subchunk_agg_check_maxazi_rev11','file')~=2
    error('validate_subchunk_agg_check_maxazi_rev11_rev12_statistical:MissingRev11', ...
        'subchunk_agg_check_maxazi_rev11.m was not found on MATLAB path.');
end
if exist('subchunk_agg_check_maxazi_rev12','file')~=2
    error('validate_subchunk_agg_check_maxazi_rev11_rev12_statistical:MissingRev12', ...
        'subchunk_agg_check_maxazi_rev12.m was not found on MATLAB path.');
end

% Thresholds aligned in style with prior rev10-vs-rev11 validation.
opts = struct();
opts.AziChunkRev11 = 128;
opts.AziChunkRev12 = 128;
opts.AbsDiffThreshold_dB = 0.50;
opts.RelDiffThreshold = 0.05;
opts.EnableP999 = true;

fprintf('\n=== REV11 vs REV12 STATISTICAL VALIDATION ===\n');
fprintf('AZI_CHUNK rev11: %d\n',opts.AziChunkRev11);
fprintf('AZI_CHUNK rev12: %d\n',opts.AziChunkRev12);

% Runtime + output capture for rev11.
rev11_tic=tic;
out_rev11=subchunk_agg_check_maxazi_rev11(app,cell_aas_dist_data,array_bs_azi_data, ...
    radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
    cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
    custom_antenna_pattern,sub_point_idx,opts.AziChunkRev11);
runtime_rev11=toc(rev11_tic);

% Runtime + output capture for rev12.
rev12_tic=tic;
out_rev12=subchunk_agg_check_maxazi_rev12(app,cell_aas_dist_data,array_bs_azi_data, ...
    radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
    cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
    custom_antenna_pattern,sub_point_idx,opts.AziChunkRev12);
runtime_rev12=toc(rev12_tic);

speedup = runtime_rev11 ./ runtime_rev12;

x11=out_rev11(:);
x12=out_rev12(:);
finite_mask=isfinite(x11) & isfinite(x12);
x11=x11(finite_mask);
x12=x12(finite_mask);

if isempty(x11)
    error('validate_subchunk_agg_check_maxazi_rev11_rev12_statistical:NoFiniteSamples', ...
        'No finite paired samples available for statistical comparison.');
end

metrics={'mean','std','min','max','median','p90','p95','p99'};
q=[0.90 0.95 0.99];

s11.mean=mean(x11,'omitnan');
s11.std=std(x11,0,'omitnan');
s11.min=min(x11,[],'omitnan');
s11.max=max(x11,[],'omitnan');
s11.median=median(x11,'omitnan');
q11=quantile(x11,q);
s11.p90=q11(1); s11.p95=q11(2); s11.p99=q11(3);

s12.mean=mean(x12,'omitnan');
s12.std=std(x12,0,'omitnan');
s12.min=min(x12,[],'omitnan');
s12.max=max(x12,[],'omitnan');
s12.median=median(x12,'omitnan');
q12=quantile(x12,q);
s12.p90=q12(1); s12.p95=q12(2); s12.p99=q12(3);

if opts.EnableP999 && numel(x11)>=1000
    metrics=[metrics {'p99_9'}]; %#ok<AGROW>
    s11.p99_9=quantile(x11,0.999);
    s12.p99_9=quantile(x12,0.999);
end

diff_table=struct();
pass_flags=true(1,numel(metrics));
for k=1:1:numel(metrics)
    m=metrics{k};
    v11=s11.(m);
    v12=s12.(m);
    abs_diff=abs(v12-v11);
    rel_diff=abs_diff/max(abs(v11),eps);
    allowed=max(opts.AbsDiffThreshold_dB,opts.RelDiffThreshold*max(abs(v11),1));

    diff_table.(m).rev11=v11;
    diff_table.(m).rev12=v12;
    diff_table.(m).abs_diff=abs_diff;
    diff_table.(m).rel_diff=rel_diff;
    diff_table.(m).allowed_abs=allowed;
    diff_table.(m).pass=abs_diff<=allowed;

    pass_flags(k)=diff_table.(m).pass;
end

tail_fields=intersect({'p95','p99','p99_9'},metrics,'stable');
tail_check=struct();
tail_pass=true;
for k=1:1:numel(tail_fields)
    tf=tail_fields{k};
    abs_diff=diff_table.(tf).abs_diff;
    allowed=diff_table.(tf).allowed_abs;
    tail_check.(tf).abs_diff=abs_diff;
    tail_check.(tf).allowed_abs=allowed;
    tail_check.(tf).pass=abs_diff<=allowed;
    tail_pass=tail_pass && tail_check.(tf).pass;
end

overall_pass=all(pass_flags) && tail_pass;

fprintf('Runtime rev11: %.6f s\n',runtime_rev11);
fprintf('Runtime rev12: %.6f s\n',runtime_rev12);
fprintf('Speedup rev11/rev12: %.3fx\n',speedup);

fprintf('\nMetric comparison (rev12 - rev11):\n');
for k=1:1:numel(metrics)
    m=metrics{k};
    fprintf('  %-7s | rev11=%10.4f | rev12=%10.4f | abs=%.4f | allow=%.4f | %s\n', ...
        m,diff_table.(m).rev11,diff_table.(m).rev12,diff_table.(m).abs_diff, ...
        diff_table.(m).allowed_abs,passfail(diff_table.(m).pass));
end

fprintf('\nUpper-tail checks:\n');
for k=1:1:numel(tail_fields)
    tf=tail_fields{k};
    fprintf('  %-7s | abs=%.4f | allow=%.4f | %s\n',tf,tail_check.(tf).abs_diff, ...
        tail_check.(tf).allowed_abs,passfail(tail_check.(tf).pass));
end

if overall_pass
    fprintf('\nPASS: rev12 is statistically equivalent to rev11 under configured thresholds.\n');
else
    fprintf('\nFAIL: rev12 drift exceeded configured thresholds.\n');
    error('validate_subchunk_agg_check_maxazi_rev11_rev12_statistical:DriftExceeded', ...
        'Fail-closed: statistical drift exceeded configured thresholds.');
end

results=struct();
results.runtime_rev11_s=runtime_rev11;
results.runtime_rev12_s=runtime_rev12;
results.speedup_rev11_over_rev12=speedup;
results.n_samples=numel(x11);
results.metrics=metrics;
results.summary_rev11=s11;
results.summary_rev12=s12;
results.diffs=diff_table;
results.upper_tail=tail_check;
results.thresholds=opts;
results.pass=overall_pass;

end

function txt=passfail(tf)
if tf
    txt='PASS';
else
    txt='FAIL';
end
end
