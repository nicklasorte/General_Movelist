function results = validate_subchunk_agg_check_maxazi_rev11_rev14_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
%VALIDATE_SUBCHUNK_AGG_CHECK_MAXAZI_REV11_REV14_STATISTICAL
% Statistical and runtime validation for rev11 vs rev14 on identical real inputs.
% Fail-closed by default when configured thresholds are exceeded.

if exist('subchunk_agg_check_maxazi_rev11','file')~=2
    error('validate_subchunk_agg_check_maxazi_rev11_rev14_statistical:MissingRev11', ...
        'subchunk_agg_check_maxazi_rev11.m was not found on MATLAB path.');
end
if exist('subchunk_agg_check_maxazi_rev14','file')~=2
    error('validate_subchunk_agg_check_maxazi_rev11_rev14_statistical:MissingRev14', ...
        'subchunk_agg_check_maxazi_rev14.m was not found on MATLAB path.');
end

opts = struct();
opts.AziChunkRev11 = 128;
opts.AziChunkRev14 = 128;
opts.NumTimingRuns = 3;
opts.AbsDiffThreshold_dB = 0.50;
opts.RelDiffThreshold = 0.05;
opts.TailAbsDiffThreshold_dB = 0.25;
opts.TailRelDiffThreshold = 0.02;
opts.EnableP999 = true;

fprintf('\n=== REV11 vs REV14 STATISTICAL VALIDATION ===\n');
fprintf('AZI_CHUNK rev11: %d\n',opts.AziChunkRev11);
fprintf('AZI_CHUNK rev14: %d\n',opts.AziChunkRev14);
fprintf('Timing runs each: %d\n',opts.NumTimingRuns);

runtime11=zeros(opts.NumTimingRuns,1);
runtime14=zeros(opts.NumTimingRuns,1);
out11=[];
out14=[];

for run_idx=1:opts.NumTimingRuns
    t11=tic;
    out11=subchunk_agg_check_maxazi_rev11(app,cell_aas_dist_data,array_bs_azi_data, ...
        radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
        cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
        custom_antenna_pattern,sub_point_idx,opts.AziChunkRev11);
    runtime11(run_idx)=toc(t11);

    t14=tic;
    out14=subchunk_agg_check_maxazi_rev14(app,cell_aas_dist_data,array_bs_azi_data, ...
        radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
        cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
        custom_antenna_pattern,sub_point_idx,opts.AziChunkRev14);
    runtime14(run_idx)=toc(t14);
end

speedup_runs=runtime11./runtime14;

x11=out11(:);
x14=out14(:);
finite_mask=isfinite(x11) & isfinite(x14);
x11=x11(finite_mask);
x14=x14(finite_mask);

if isempty(x11)
    error('validate_subchunk_agg_check_maxazi_rev11_rev14_statistical:NoFiniteSamples', ...
        'No finite paired samples available for statistical comparison.');
end

metrics={'mean','std','min','max','median','p90','p95','p99'};
q=[0.90 0.95 0.99];

s11=build_summary(x11,q,opts.EnableP999);
s14=build_summary(x14,q,opts.EnableP999);
if isfield(s11,'p99_9')
    metrics=[metrics {'p99_9'}]; %#ok<AGROW>
end

diff_table=struct();
pass_flags=true(1,numel(metrics));
for k=1:1:numel(metrics)
    m=metrics{k};
    v11=s11.(m);
    v14=s14.(m);
    abs_diff=abs(v14-v11);
    rel_diff=abs_diff/max(abs(v11),eps);

    is_tail=ismember(m,{'p95','p99','p99_9'});
    if is_tail
        allowed_abs=max(opts.TailAbsDiffThreshold_dB,opts.TailRelDiffThreshold*max(abs(v11),1));
    else
        allowed_abs=max(opts.AbsDiffThreshold_dB,opts.RelDiffThreshold*max(abs(v11),1));
    end

    diff_table.(m)=struct( ...
        'rev11',v11, ...
        'rev14',v14, ...
        'abs_diff',abs_diff, ...
        'rel_diff',rel_diff, ...
        'allowed_abs',allowed_abs, ...
        'pass',abs_diff<=allowed_abs, ...
        'is_tail_metric',is_tail);

    pass_flags(k)=diff_table.(m).pass;
end

tail_fields=intersect({'p95','p99','p99_9'},metrics,'stable');
tail_check=struct();
tail_pass=true;
for k=1:numel(tail_fields)
    tf=tail_fields{k};
    tail_check.(tf)=struct( ...
        'abs_diff',diff_table.(tf).abs_diff, ...
        'allowed_abs',diff_table.(tf).allowed_abs, ...
        'pass',diff_table.(tf).pass);
    tail_pass=tail_pass && tail_check.(tf).pass;
end

overall_pass=all(pass_flags) && tail_pass;

fprintf('\nRuntime (seconds)\n');
fprintf('  rev11 runs: [%s]\n',num_vec_to_text(runtime11));
fprintf('  rev14 runs: [%s]\n',num_vec_to_text(runtime14));
fprintf('  rev11 mean: %.6f s\n',mean(runtime11));
fprintf('  rev14 mean: %.6f s\n',mean(runtime14));
fprintf('  speedup rev11/rev14 (mean): %.3fx\n',mean(runtime11)/mean(runtime14));

fprintf('\nMetric comparison (rev14 - rev11):\n');
for k=1:numel(metrics)
    m=metrics{k};
    fprintf('  %-7s | rev11=%10.4f | rev14=%10.4f | abs=%.4f | allow=%.4f | %s\n', ...
        m,diff_table.(m).rev11,diff_table.(m).rev14,diff_table.(m).abs_diff, ...
        diff_table.(m).allowed_abs,passfail(diff_table.(m).pass));
end

fprintf('\nUpper-tail checks:\n');
for k=1:numel(tail_fields)
    tf=tail_fields{k};
    fprintf('  %-7s | abs=%.4f | allow=%.4f | %s\n',tf,tail_check.(tf).abs_diff, ...
        tail_check.(tf).allowed_abs,passfail(tail_check.(tf).pass));
end

if overall_pass
    fprintf('\nPASS: rev14 is statistically equivalent to rev11 under configured thresholds.\n');
else
    fprintf('\nFAIL: rev14 drift exceeded configured thresholds (fail-closed).\n');
    error('validate_subchunk_agg_check_maxazi_rev11_rev14_statistical:DriftExceeded', ...
        'Fail-closed: statistical drift exceeded configured thresholds.');
end

results=struct();
results.options=opts;
results.runtime_rev11_s=runtime11;
results.runtime_rev14_s=runtime14;
results.speedup_rev11_over_rev14=speedup_runs;
results.speedup_mean_rev11_over_rev14=mean(runtime11)/mean(runtime14);
results.n_samples=numel(x11);
results.metrics=metrics;
results.summary_rev11=s11;
results.summary_rev14=s14;
results.diffs=diff_table;
results.upper_tail=tail_check;
results.pass=overall_pass;

end

function s=build_summary(x,q,enable_p999)
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
if enable_p999 && numel(x)>=1000
    s.p99_9=quantile(x,0.999);
end
end

function txt=passfail(tf)
if tf
    txt='PASS';
else
    txt='FAIL';
end
end

function txt=num_vec_to_text(v)
txt=sprintf('%.6f ',v);
txt=strtrim(txt);
end
