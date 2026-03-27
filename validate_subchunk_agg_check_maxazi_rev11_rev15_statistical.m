function results = validate_subchunk_agg_check_maxazi_rev11_rev15_statistical( ...
    app, ...
    cell_aas_dist_data, ...
    array_bs_azi_data, ...
    radar_beamwidth, ...
    min_azimuth, ...
    max_azimuth, ...
    base_protection_pts, ...
    point_idx, ...
    on_list_bs, ...
    cell_sim_chunk_idx, ...
    rand_seed1, ...
    agg_check_reliability, ...
    on_full_Pr_dBm, ...
    clutter_loss, ...
    custom_antenna_pattern, ...
    sub_point_idx)
%VALIDATE_SUBCHUNK_AGG_CHECK_MAXAZI_REV11_REV15_STATISTICAL
% End-to-end runtime/statistical equivalence check for rev11 vs rev15.
% Fail-closed policy: throw on any threshold exceedance.

must_exist('subchunk_agg_check_maxazi_rev11','MissingRev11');
must_exist('subchunk_agg_check_maxazi_rev15','MissingRev15');

opts=struct();
opts.AziChunkRev11=128;
opts.AziChunkRev15=128;
opts.NumTimingRuns=3;
opts.CoreAbsDrift_dB=0.25;    % mean/std/min/max/median/p90
opts.CoreRelDrift=0.02;
opts.TailAbsDrift_dB=0.15;    % p95/p99
opts.TailRelDrift=0.01;

fprintf('\n=== VALIDATION: REV11 vs REV15 (STATISTICAL) ===\n');
fprintf('Thresholds (fail-closed): core=max(%.3f dB, %.3f*|rev11|), tail=max(%.3f dB, %.3f*|rev11|)\n', ...
    opts.CoreAbsDrift_dB,opts.CoreRelDrift,opts.TailAbsDrift_dB,opts.TailRelDrift);

runtime11=zeros(opts.NumTimingRuns,1);
runtime15=zeros(opts.NumTimingRuns,1);
out11=[];
out15=[];
for run_idx=1:opts.NumTimingRuns
    t=tic;
    out11=subchunk_agg_check_maxazi_rev11(app,cell_aas_dist_data,array_bs_azi_data, ...
        radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
        cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
        custom_antenna_pattern,sub_point_idx,opts.AziChunkRev11);
    runtime11(run_idx)=toc(t);

    t=tic;
    out15=subchunk_agg_check_maxazi_rev15(app,cell_aas_dist_data,array_bs_azi_data, ...
        radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
        cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
        custom_antenna_pattern,sub_point_idx,opts.AziChunkRev15);
    runtime15(run_idx)=toc(t);
end

x11=out11(:);
x15=out15(:);
mask=isfinite(x11) & isfinite(x15);
x11=x11(mask);
x15=x15(mask);
if isempty(x11)
    error('validate_subchunk_agg_check_maxazi_rev11_rev15_statistical:NoFiniteSamples', ...
        'No finite paired samples available for comparison.');
end

metric_names={'mean','std','min','max','median','p90','p95','p99'};
qvals=[0.90 0.95 0.99];
s11=summary_stats(x11,qvals);
s15=summary_stats(x15,qvals);

tail_metrics={'p95','p99'};
drift=struct();
pass_vec=true(size(metric_names));
for k=1:numel(metric_names)
    m=metric_names{k};
    v11=s11.(m);
    v15=s15.(m);
    abs_diff=abs(v15-v11);
    rel_diff=abs_diff/max(abs(v11),eps);

    is_tail=any(strcmp(m,tail_metrics));
    if is_tail
        allowed=max(opts.TailAbsDrift_dB,opts.TailRelDrift*max(abs(v11),1));
    else
        allowed=max(opts.CoreAbsDrift_dB,opts.CoreRelDrift*max(abs(v11),1));
    end

    pass_here=abs_diff<=allowed;
    pass_vec(k)=pass_here;
    drift.(m)=struct('rev11',v11,'rev15',v15,'abs_diff',abs_diff, ...
        'rel_diff',rel_diff,'allowed_abs',allowed,'is_tail',is_tail,'pass',pass_here);
end

overall_pass=all(pass_vec);

fprintf('\nRuntime summary (seconds):\n');
fprintf('  rev11 runs: [%s]\n',fmt_vec(runtime11));
fprintf('  rev15 runs: [%s]\n',fmt_vec(runtime15));
fprintf('  rev11 mean: %.6f\n',mean(runtime11));
fprintf('  rev15 mean: %.6f\n',mean(runtime15));
fprintf('  speedup (rev11/rev15): %.3fx\n',mean(runtime11)/mean(runtime15));

fprintf('\nMetric drift summary:\n');
for k=1:numel(metric_names)
    m=metric_names{k};
    d=drift.(m);
    fprintf('  %-7s | rev11=%10.4f | rev15=%10.4f | abs=%8.4f | allow=%8.4f | %s\n', ...
        m,d.rev11,d.rev15,d.abs_diff,d.allowed_abs,passfail(d.pass));
end

fprintf('\nUpper-tail emphasis:\n');
for k=1:numel(tail_metrics)
    m=tail_metrics{k};
    d=drift.(m);
    fprintf('  %-7s | abs=%8.4f | allow=%8.4f | %s\n',m,d.abs_diff,d.allowed_abs,passfail(d.pass));
end

if overall_pass
    fprintf('\nPASS: rev15 statistical behavior is within configured thresholds.\n');
else
    fprintf('\nFAIL: rev15 drift exceeded configured thresholds (fail-closed).\n');
    error('validate_subchunk_agg_check_maxazi_rev11_rev15_statistical:DriftExceeded', ...
        'Fail-closed: one or more statistical metrics exceeded thresholds.');
end

results=struct();
results.options=opts;
results.n_samples=numel(x11);
results.runtime_rev11_s=runtime11;
results.runtime_rev15_s=runtime15;
results.runtime_mean_rev11_s=mean(runtime11);
results.runtime_mean_rev15_s=mean(runtime15);
results.speedup_rev11_over_rev15=mean(runtime11)/mean(runtime15);
results.summary_rev11=s11;
results.summary_rev15=s15;
results.metrics=metric_names;
results.drift=drift;
results.pass=overall_pass;

end

function s=summary_stats(x,qvals)
s=struct();
s.mean=mean(x,'omitnan');
s.std=std(x,0,'omitnan');
s.min=min(x,[],'omitnan');
s.max=max(x,[],'omitnan');
s.median=median(x,'omitnan');
q=quantile(x,qvals);
s.p90=q(1);
s.p95=q(2);
s.p99=q(3);
end

function must_exist(fname,errid)
if exist(fname,'file')~=2
    error(['validate_subchunk_agg_check_maxazi_rev11_rev15_statistical:' errid], ...
        '%s.m was not found on MATLAB path.',fname);
end
end

function txt=fmt_vec(v)
txt=sprintf('%.6f ',v);
txt=strtrim(txt);
end

function txt=passfail(tf)
if tf
    txt='PASS';
else
    txt='FAIL';
end
end
