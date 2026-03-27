function results=validate_subchunk_agg_check_maxazi_rev10_rev11_statistical(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx,varargin)
%VALIDATE_SUBCHUNK_AGG_CHECK_MAXAZI_REV10_REV11_STATISTICAL
% Compare rev10 vs rev11 on identical real inputs.
% Returns a results struct and prints PASS/FAIL summary.
%
% Optional name/value:
%   'AziChunk'               (default 128)
%   'EnableP999'             (default true)
%   'AbsDiffThreshold_dB'    (default 0.50)
%   'RelDiffThreshold'       (default 0.05)

opts=parse_inputs(varargin{:});

if exist('subchunk_agg_check_maxazi_rev10','file')~=2
    error('validate_subchunk_agg_check_maxazi_rev10_rev11_statistical:MissingRev10', ...
        'subchunk_agg_check_maxazi_rev10.m was not found on MATLAB path.');
end
if exist('subchunk_agg_check_maxazi_rev11','file')~=2
    error('validate_subchunk_agg_check_maxazi_rev10_rev11_statistical:MissingRev11', ...
        'subchunk_agg_check_maxazi_rev11.m was not found on MATLAB path.');
end

fprintf('\n=== rev10 vs rev11 statistical validation ===\n');
fprintf('AZI_CHUNK (rev11): %d\n',opts.AziChunk);

% Run rev10
rev10_tic=tic;
out_rev10=subchunk_agg_check_maxazi_rev10(app,cell_aas_dist_data,array_bs_azi_data, ...
    radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
    cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
    custom_antenna_pattern,sub_point_idx);
runtime_rev10=toc(rev10_tic);

% Run rev11
rev11_tic=tic;
out_rev11=subchunk_agg_check_maxazi_rev11(app,cell_aas_dist_data,array_bs_azi_data, ...
    radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
    cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
    custom_antenna_pattern,sub_point_idx,opts.AziChunk);
runtime_rev11=toc(rev11_tic);

speedup=runtime_rev10./runtime_rev11;

% Flatten and sanitize for summary stats
x10=out_rev10(:);
x11=out_rev11(:);
finite_mask=isfinite(x10) & isfinite(x11);
x10=x10(finite_mask);
x11=x11(finite_mask);

if isempty(x10)
    error('validate_subchunk_agg_check_maxazi_rev10_rev11_statistical:NoFiniteSamples', ...
        'No finite paired samples available for statistical comparison.');
end

metrics={'mean','std','min','max','median','p90','p95','p99'};
q=[0.90 0.95 0.99];

s10.mean=mean(x10,'omitnan');
s10.std=std(x10,0,'omitnan');
s10.min=min(x10,[],'omitnan');
s10.max=max(x10,[],'omitnan');
s10.median=median(x10,'omitnan');
q10=quantile(x10,q);
s10.p90=q10(1); s10.p95=q10(2); s10.p99=q10(3);

s11.mean=mean(x11,'omitnan');
s11.std=std(x11,0,'omitnan');
s11.min=min(x11,[],'omitnan');
s11.max=max(x11,[],'omitnan');
s11.median=median(x11,'omitnan');
q11=quantile(x11,q);
s11.p90=q11(1); s11.p95=q11(2); s11.p99=q11(3);

if opts.EnableP999 && numel(x10)>=1000
    metrics=[metrics {'p99_9'}]; %#ok<AGROW>
    s10.p99_9=quantile(x10,0.999);
    s11.p99_9=quantile(x11,0.999);
end

% Drift checks (documented): pass if abs diff <= max(abs threshold, rel threshold*|baseline|)
diff_table=struct();
pass_flags=true(1,numel(metrics));
for k=1:1:numel(metrics)
    m=metrics{k};
    v10=s10.(m);
    v11=s11.(m);
    abs_diff=abs(v11-v10);
    rel_diff=abs_diff/max(abs(v10),eps);
    allowed=max(opts.AbsDiffThreshold_dB,opts.RelDiffThreshold*max(abs(v10),1));

    diff_table.(m).rev10=v10;
    diff_table.(m).rev11=v11;
    diff_table.(m).abs_diff=abs_diff;
    diff_table.(m).rel_diff=rel_diff;
    diff_table.(m).allowed_abs=allowed;
    diff_table.(m).pass=abs_diff<=allowed;

    pass_flags(k)=diff_table.(m).pass;
end

% Upper-tail focused checks
tail_check=struct();
tail_fields=intersect({'p95','p99','p99_9'},metrics,'stable');
tail_pass=true;
for k=1:1:numel(tail_fields)
    tf=tail_fields{k};
    v10=diff_table.(tf).rev10;
    v11=diff_table.(tf).rev11;
    abs_diff=abs(v11-v10);
    allowed=max(opts.AbsDiffThreshold_dB,opts.RelDiffThreshold*max(abs(v10),1));
    tail_check.(tf).abs_diff=abs_diff;
    tail_check.(tf).allowed_abs=allowed;
    tail_check.(tf).pass=abs_diff<=allowed;
    tail_pass=tail_pass && tail_check.(tf).pass;
end

overall_pass=all(pass_flags) && tail_pass;

fprintf('Runtime rev10: %.6f s\n',runtime_rev10);
fprintf('Runtime rev11: %.6f s\n',runtime_rev11);
fprintf('Speedup rev10/rev11: %.3fx\n',speedup);

fprintf('\nMetric comparison (rev11 - rev10):\n');
for k=1:1:numel(metrics)
    m=metrics{k};
    fprintf('  %-7s | rev10=%10.4f | rev11=%10.4f | abs=%.4f | allow=%.4f | %s\n', ...
        m,diff_table.(m).rev10,diff_table.(m).rev11,diff_table.(m).abs_diff, ...
        diff_table.(m).allowed_abs,passfail(diff_table.(m).pass));
end

fprintf('\nUpper-tail checks:\n');
for k=1:1:numel(tail_fields)
    tf=tail_fields{k};
    fprintf('  %-7s | abs=%.4f | allow=%.4f | %s\n',tf,tail_check.(tf).abs_diff, ...
        tail_check.(tf).allowed_abs,passfail(tail_check.(tf).pass));
end

if overall_pass
    fprintf('\nPASS: rev11 is statistically equivalent to rev10 under configured thresholds.\n');
else
    fprintf('\nFAIL: rev11 drift exceeded configured thresholds.\n');
end

results=struct();
results.runtime_rev10_s=runtime_rev10;
results.runtime_rev11_s=runtime_rev11;
results.speedup_rev10_over_rev11=speedup;
results.n_samples=numel(x10);
results.metrics=metrics;
results.summary_rev10=s10;
results.summary_rev11=s11;
results.diffs=diff_table;
results.upper_tail=tail_check;
results.thresholds=opts;
results.pass=overall_pass;

end

function opts=parse_inputs(varargin)
opts=struct();
opts.AziChunk=128;
opts.EnableP999=true;
opts.AbsDiffThreshold_dB=0.50;
opts.RelDiffThreshold=0.05;

if mod(numel(varargin),2)~=0
    error('Optional arguments must be name/value pairs.');
end

for i=1:2:numel(varargin)
    name=varargin{i};
    value=varargin{i+1};
    switch lower(string(name))
        case "azichunk"
            opts.AziChunk=max(1,round(value));
        case "enablep999"
            opts.EnableP999=logical(value);
        case "absdiffthreshold_db"
            opts.AbsDiffThreshold_dB=double(value);
        case "reldiffthreshold"
            opts.RelDiffThreshold=double(value);
        otherwise
            error('Unknown option: %s',name);
    end
end
end

function txt=passfail(tf)
if tf
    txt='PASS';
else
    txt='FAIL';
end
end
