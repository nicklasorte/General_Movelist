function results=validate_monte_carlo_super_bs_eirp_dist_rev5_rev6(app,cell_aas_dist_data,array_bs_azi_data,agg_check_reliability,rand_seed1,cell_sim_chunk_idx,sub_point_idx,varargin)
%VALIDATE_MONTE_CARLO_SUPER_BS_EIRP_DIST_REV5_REV6
% Helper-level comparator for rev5 vs rev6 using identical helper-call inputs.
% Fail-closed policy: throw if helper drift exceeds tight thresholds.

must_exist('monte_carlo_super_bs_eirp_dist_rev5','MissingRev5');
must_exist('monte_carlo_super_bs_eirp_dist_rev6','MissingRev6');

opts=struct();
opts.NumSamples=[];                 % default: infer from cell_sim_chunk_idx{sub_point_idx}
opts.MaxAbsDiffTol=1e-9;
opts.MeanAbsDiffTol=1e-10;
opts.RelDiffTol=1e-9;
opts.ReportTopK=5;
if ~isempty(varargin)
    user_opts=varargin{1};
    if isstruct(user_opts)
        opts=merge_struct(opts,user_opts);
    end
end

array_aas_dist_data=cell_aas_dist_data{2};
aas_dist_azimuth=cell_aas_dist_data{1};
mod_azi_diff_bs=array_bs_azi_data(:,4);
nn_azi_idx=nearestpoint_app(app,mod_azi_diff_bs,aas_dist_azimuth);
super_array_bs_eirp_dist=array_aas_dist_data(nn_azi_idx,:);

num_bs=size(super_array_bs_eirp_dist,1);
if isempty(opts.NumSamples)
    sub_mc_idx=cell_sim_chunk_idx{sub_point_idx};
    num_samples=length(sub_mc_idx);
else
    num_samples=max(1,round(opts.NumSamples));
end

rel_min=min(agg_check_reliability);
rel_max=max(agg_check_reliability);
if rel_min==rel_max
    rand_eirp_all=repmat(rel_min,num_bs,num_samples);
else
    rng(rand_seed1);
    rand_eirp_all=rel_min+(rel_max-rel_min).*rand(num_bs,num_samples);
end

x=agg_check_reliability(:).';
y=super_array_bs_eirp_dist;
query=rand_eirp_all;

fprintf('\n=== HELPER VALIDATION: rev5 vs rev6 ===\n');
fprintf('X (reliability grid) shape: [%d x %d]\n',size(x,1),size(x,2));
fprintf('Y (EIRP values) shape:      [%d x %d]\n',size(y,1),size(y,2));
fprintf('Query shape:                [%d x %d]\n',size(query,1),size(query,2));

out5=NaN(num_bs,num_samples);
out6=NaN(num_bs,num_samples);
for k=1:1:num_samples
    out5(:,k)=monte_carlo_super_bs_eirp_dist_rev5(app,y,x,query(:,k));
    out6(:,k)=monte_carlo_super_bs_eirp_dist_rev6(app,y,x,query(:,k));
end

delta=out6-out5;
abs_delta=abs(delta);

max_abs_diff=max(abs_delta,[],'all');
mean_abs_diff=mean(abs_delta,'all','omitnan');
den=max(abs(out5),1e-12);
rel_delta=abs_delta./den;
max_rel_diff=max(rel_delta,[],'all');
mean_rel_diff=mean(rel_delta,'all','omitnan');

lin_abs=abs_delta(:);
[sorted_abs,sorted_idx]=sort(lin_abs,'descend'); %#ok<ASGLU>
report_k=min(opts.ReportTopK,numel(sorted_idx));
worst=struct('linear_idx',cell(report_k,1),'row',[],'col',[], ...
    'query_value',[],'rev5',[],'rev6',[],'abs_diff',[],'rel_diff',[]);
for i=1:report_k
    idx=sorted_idx(i);
    [r,c]=ind2sub(size(abs_delta),idx);
    worst(i).linear_idx=idx;
    worst(i).row=r;
    worst(i).col=c;
    worst(i).query_value=query(r,c);
    worst(i).rev5=out5(r,c);
    worst(i).rev6=out6(r,c);
    worst(i).abs_diff=abs_delta(r,c);
    worst(i).rel_diff=rel_delta(r,c);
end

x_sorted=sort(x,'ascend');
x_unique=unique(x_sorted,'stable');
x_min=x_sorted(1);
x_max=x_sorted(end);
if numel(x_unique)>=3
    typical_step=median(diff(x_unique));
else
    typical_step=max(x_max-x_min,eps);
end
endpoint_tol=max(typical_step*0.5,1e-12);
breakpoint_tol=max(typical_step*0.05,1e-12);
clamp_tol=1e-12;

near_endpoint=(abs(query-x_min)<=endpoint_tol) | (abs(query-x_max)<=endpoint_tol);
near_breakpoint=is_near_breakpoint(query,x_unique,breakpoint_tol);
is_clamped=(abs(query-rel_min)<=clamp_tol) | (abs(query-rel_max)<=clamp_tol);

sig_mask=abs_delta>max(opts.MaxAbsDiffTol,opts.RelDiffTol*max(abs(out5),1));
cluster=struct();
cluster.total_sig=nnz(sig_mask);
if cluster.total_sig>0
    cluster.endpoint_fraction=nnz(sig_mask & near_endpoint)/cluster.total_sig;
    cluster.breakpoint_fraction=nnz(sig_mask & near_breakpoint)/cluster.total_sig;
    cluster.clamped_fraction=nnz(sig_mask & is_clamped)/cluster.total_sig;
else
    cluster.endpoint_fraction=0;
    cluster.breakpoint_fraction=0;
    cluster.clamped_fraction=0;
end

fprintf('max abs diff:  %.6e\n',max_abs_diff);
fprintf('mean abs diff: %.6e\n',mean_abs_diff);
fprintf('max rel diff:  %.6e\n',max_rel_diff);
fprintf('mean rel diff: %.6e\n',mean_rel_diff);
fprintf('Significant-diff clustering: endpoints=%.1f%%, breakpoints=%.1f%%, clamped=%.1f%%\n', ...
    100*cluster.endpoint_fraction,100*cluster.breakpoint_fraction,100*cluster.clamped_fraction);

for i=1:report_k
    w=worst(i);
    fprintf('  worst[%d] row=%d col=%d query=%.6g rev5=%.6g rev6=%.6g abs=%.3e rel=%.3e\n', ...
        i,w.row,w.col,w.query_value,w.rev5,w.rev6,w.abs_diff,w.rel_diff);
end

pass=(max_abs_diff<=opts.MaxAbsDiffTol) && (mean_abs_diff<=opts.MeanAbsDiffTol) && (max_rel_diff<=opts.RelDiffTol);
fprintf('Helper comparison result: %s\n',passfail(pass));

results=struct();
results.options=opts;
results.input_shapes=struct('X',size(x),'Y',size(y),'Query',size(query));
results.thresholds=struct('max_abs',opts.MaxAbsDiffTol,'mean_abs',opts.MeanAbsDiffTol,'max_rel',opts.RelDiffTol);
results.max_abs_diff=max_abs_diff;
results.mean_abs_diff=mean_abs_diff;
results.max_rel_diff=max_rel_diff;
results.mean_rel_diff=mean_rel_diff;
results.worst_cases=worst;
results.cluster=cluster;
results.pass=pass;

if ~pass
    error('validate_monte_carlo_super_bs_eirp_dist_rev5_rev6:DriftExceeded', ...
        ['Fail-closed: helper drift exceeded thresholds. ' ...
         'max_abs=%.3e (tol %.3e), mean_abs=%.3e (tol %.3e), max_rel=%.3e (tol %.3e).'], ...
         max_abs_diff,opts.MaxAbsDiffTol,mean_abs_diff,opts.MeanAbsDiffTol,max_rel_diff,opts.RelDiffTol);
end

end

function out=is_near_breakpoint(query,x_unique,tol)
out=false(size(query));
for i=1:1:numel(x_unique)
    out=out | abs(query-x_unique(i))<=tol;
end
end

function must_exist(fname,errid)
if exist(fname,'file')~=2
    error(['validate_monte_carlo_super_bs_eirp_dist_rev5_rev6:' errid], ...
        '%s.m was not found on MATLAB path.',fname);
end
end

function out=merge_struct(base,override)
out=base;
fn=fieldnames(override);
for i=1:numel(fn)
    out.(fn{i})=override.(fn{i});
end
end

function txt=passfail(tf)
if tf
    txt='PASS';
else
    txt='FAIL';
end
end
