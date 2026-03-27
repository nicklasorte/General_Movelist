function results = validate_subchunk_agg_check_maxazi_rev11_rev20_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
%VALIDATE_SUBCHUNK_AGG_CHECK_MAXAZI_REV11_REV20_STATISTICAL
% Fail-closed statistical validation of rev20 against golden rev11 only.

must_exist('subchunk_agg_check_maxazi_rev11','MissingRev11');
must_exist('subchunk_agg_check_maxazi_rev20','MissingRev20');

opts=struct();
opts.AziChunkRev11=128;
opts.AziChunkRev20=128;
opts.NumTimingRuns=3;
opts.CoreAbsDrift_dB=0.250;
opts.CoreRelDrift=0.020;
opts.TailAbsDrift_dB=0.150;
opts.TailRelDrift=0.010;

fprintf('\n=== VALIDATION: REV11 vs REV20 (STATISTICAL) ===\n');
fprintf('Thresholds (fail-closed): core=max(%.3f dB, %.3f*|rev11|), tail=max(%.3f dB, %.3f*|rev11|)\n', ...
    opts.CoreAbsDrift_dB,opts.CoreRelDrift,opts.TailAbsDrift_dB,opts.TailRelDrift);

runtime11=zeros(opts.NumTimingRuns,1);
runtime20=zeros(opts.NumTimingRuns,1);
out11=[];
out20=[];
for run_idx=1:opts.NumTimingRuns
    t=tic;
    out11=subchunk_agg_check_maxazi_rev11(app,cell_aas_dist_data,array_bs_azi_data, ...
        radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
        cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
        custom_antenna_pattern,sub_point_idx,opts.AziChunkRev11);
    runtime11(run_idx)=toc(t);

    t=tic;
    out20=subchunk_agg_check_maxazi_rev20(app,cell_aas_dist_data,array_bs_azi_data, ...
        radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
        cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
        custom_antenna_pattern,sub_point_idx,opts.AziChunkRev20);
    runtime20(run_idx)=toc(t);
end

x11=out11(:);
x20=out20(:);
mask=isfinite(x11) & isfinite(x20);
x11=x11(mask);
x20=x20(mask);
if isempty(x11)
    error('validate_subchunk_agg_check_maxazi_rev11_rev20_statistical:NoFiniteSamples', ...
        'No finite paired samples available for comparison.');
end

metric_names={'mean','std','min','max','median','p90','p95','p99'};
tail_metrics={'p95','p99'};
qvals=[0.90 0.95 0.99];

s11=summary_stats(x11,qvals);
s20=summary_stats(x20,qvals);

drift=struct();
pass_vec=true(size(metric_names));
for k=1:numel(metric_names)
    m=metric_names{k};
    v11=s11.(m);
    v20=s20.(m);
    abs_diff=abs(v20-v11);

    is_tail=any(strcmp(m,tail_metrics));
    if is_tail
        allowed=max(opts.TailAbsDrift_dB,opts.TailRelDrift*abs(v11));
    else
        allowed=max(opts.CoreAbsDrift_dB,opts.CoreRelDrift*abs(v11));
    end

    pass_here=abs_diff<=allowed;
    pass_vec(k)=pass_here;
    drift.(m)=struct('rev11',v11,'rev20',v20,'abs_diff',abs_diff, ...
        'allowed_abs',allowed,'is_tail',is_tail,'pass',pass_here);
end

overall_pass=all(pass_vec);

fprintf('\nRuntime summary (seconds):\n');
fprintf('  rev11 runs: [%s]\n',fmt_vec(runtime11));
fprintf('  rev20 runs: [%s]\n',fmt_vec(runtime20));
fprintf('  rev11 mean: %.6f\n',mean(runtime11));
fprintf('  rev20 mean: %.6f\n',mean(runtime20));
fprintf('  speedup (rev11/rev20): %.3fx\n',mean(runtime11)/max(mean(runtime20),eps));

fprintf('\nMetric drift summary:\n');
for k=1:numel(metric_names)
    m=metric_names{k};
    d=drift.(m);
    fprintf('  %-7s | rev11=%10.4f | rev20=%10.4f | abs=%8.4f | allow=%8.4f | %s\n', ...
        m,d.rev11,d.rev20,d.abs_diff,d.allowed_abs,passfail(d.pass));
end

fprintf('\nUpper-tail emphasis:\n');
for k=1:numel(tail_metrics)
    m=tail_metrics{k};
    d=drift.(m);
    fprintf('  %-7s | rev11=%10.4f | rev20=%10.4f | abs=%8.4f | allow=%8.4f | %s\n', ...
        m,d.rev11,d.rev20,d.abs_diff,d.allowed_abs,passfail(d.pass));
end

if overall_pass
    fprintf('\nPASS / FAIL: PASS\n');
else
    fprintf('\nPASS / FAIL: FAIL\n');
    error('validate_subchunk_agg_check_maxazi_rev11_rev20_statistical:DriftExceeded', ...
        'Fail-closed: rev20 drift exceeded rev11 thresholds.');
end

results=struct();
results.options=opts;
results.n_samples=numel(x11);
results.runtime_rev11_s=runtime11;
results.runtime_rev20_s=runtime20;
results.runtime_mean_rev11_s=mean(runtime11);
results.runtime_mean_rev20_s=mean(runtime20);
results.speedup_rev11_over_rev20=mean(runtime11)/max(mean(runtime20),eps);
results.summary_rev11=s11;
results.summary_rev20=s20;
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
    error(['validate_subchunk_agg_check_maxazi_rev11_rev20_statistical:' errid], ...
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