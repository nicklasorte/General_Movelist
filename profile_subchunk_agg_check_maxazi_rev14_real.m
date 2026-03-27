function results = profile_subchunk_agg_check_maxazi_rev14_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
%PROFILE_SUBCHUNK_AGG_CHECK_MAXAZI_REV14_REAL
% Profile rev14 on real inputs and report timing for targeted bottleneck path.

must_exist('subchunk_agg_check_maxazi_rev14','MissingRev14');
must_exist('monte_carlo_super_bs_eirp_dist_rev6','MissingRev6');

% Baseline from measured rev11 profile evidence.
baseline=struct();
baseline.subchunk_total_s=50.486;
baseline.eirp_helper_total_s=45.499;
baseline.interp1_total_s=44.043;
baseline.interp1_calls=380640;

opts=struct();
opts.AziChunkRev14=128;
opts.TopN=15;
opts.EnableDetailBuiltin=true;

fprintf('\n=== PROFILE REV14 (REAL INPUTS) ===\n');
fprintf('AZI_CHUNK rev14: %d\n',opts.AziChunkRev14);

profile off;
profile clear;
if opts.EnableDetailBuiltin
    profile('-memory','off','-detail','builtin');
end
profile on;

wall_tic=tic;
out=subchunk_agg_check_maxazi_rev14(app,cell_aas_dist_data,array_bs_azi_data, ...
    radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
    cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
    custom_antenna_pattern,sub_point_idx,opts.AziChunkRev14); %#ok<NASGU>
wall_runtime_s=toc(wall_tic);

profile off;
pinfo=profile('info');
if ~isfield(pinfo,'FunctionTable') || isempty(pinfo.FunctionTable)
    error('profile_subchunk_agg_check_maxazi_rev14_real:EmptyProfile', ...
        'MATLAB profile did not return function timing data.');
end

tbl=build_profile_table(pinfo.FunctionTable);
[~,idx_total]=sort(tbl.TotalTime_s,'descend','MissingPlacement','last');
top_n=min(opts.TopN,height(tbl));
top_total=tbl(idx_total(1:top_n),:);

fprintf('\nTop contributors by total time:\n');
disp(top_total);

key=struct();
key.subchunk_agg_check_maxazi_rev14=summarize_rows(tbl,match_rows(tbl,'subchunk_agg_check_maxazi_rev14'),wall_runtime_s);
key.monte_carlo_super_bs_eirp_dist_rev6=summarize_rows(tbl,match_rows(tbl,'monte_carlo_super_bs_eirp_dist_rev6'),wall_runtime_s);
key.interp1=summarize_rows(tbl,match_rows(tbl,'interp1'),wall_runtime_s);
key.monte_carlo_clutter_rev3_app=summarize_rows(tbl,match_rows(tbl,'monte_carlo_clutter_rev3_app'),wall_runtime_s);
key.monte_carlo_Pr_dBm_rev2_app=summarize_rows(tbl,match_rows(tbl,'monte_carlo_Pr_dBm_rev2_app'),wall_runtime_s);

fprintf('\nSummary timing table (requested functions):\n');
print_row('subchunk_agg_check_maxazi_rev14',key.subchunk_agg_check_maxazi_rev14);
print_row('monte_carlo_super_bs_eirp_dist_rev6',key.monte_carlo_super_bs_eirp_dist_rev6);
print_row('interp1',key.interp1);
print_row('monte_carlo_clutter_rev3_app',key.monte_carlo_clutter_rev3_app);
print_row('monte_carlo_Pr_dBm_rev2_app',key.monte_carlo_Pr_dBm_rev2_app);

interp_time_drop=(baseline.interp1_total_s-key.interp1.total_time_s)/max(baseline.interp1_total_s,eps);
interp_call_drop=(baseline.interp1_calls-key.interp1.calls)/max(baseline.interp1_calls,eps);
helper_time_drop=(baseline.eirp_helper_total_s-key.monte_carlo_super_bs_eirp_dist_rev6.total_time_s)/max(baseline.eirp_helper_total_s,eps);

material_time_drop=interp_time_drop>=0.20;
material_call_drop=interp_call_drop>=0.20;
material_interp_drop=material_time_drop || material_call_drop;

fprintf('\nBaseline comparison vs rev11 evidence:\n');
fprintf('  interp1 total time: rev11=%.3f s, rev14=%.3f s, drop=%.1f%%\n', ...
    baseline.interp1_total_s,key.interp1.total_time_s,100*interp_time_drop);
fprintf('  interp1 calls:      rev11=%d, rev14=%g, drop=%.1f%%\n', ...
    baseline.interp1_calls,key.interp1.calls,100*interp_call_drop);
fprintf('  helper total time:  rev11=%.3f s, rev14=%.3f s, drop=%.1f%%\n', ...
    baseline.eirp_helper_total_s,key.monte_carlo_super_bs_eirp_dist_rev6.total_time_s,100*helper_time_drop);
if material_interp_drop
    fprintf('  MATERIAL interp1 reduction: YES\n');
else
    fprintf('  MATERIAL interp1 reduction: NO\n');
end

results=struct();
results.options=opts;
results.wall_runtime_s=wall_runtime_s;
results.top_by_total=top_total;
results.summary=key;
results.baseline_rev11=baseline;
results.interp1_time_drop_fraction=interp_time_drop;
results.interp1_call_drop_fraction=interp_call_drop;
results.helper_time_drop_fraction=helper_time_drop;
results.material_interp1_drop=material_interp_drop;
results.full_profile_table=tbl;

end

function tbl=build_profile_table(ft)
n=numel(ft);
name_col=cell(n,1);
total_col=zeros(n,1);
self_col=zeros(n,1);
calls_col=zeros(n,1);
for i=1:n
    name_col{i}=safe_get(ft(i),{'FunctionName','CompleteName','FileName'},'<unknown>');
    total_col(i)=safe_get(ft(i),{'TotalTime'},NaN);
    self_col(i)=safe_get(ft(i),{'SelfTime'},NaN);
    calls_col(i)=safe_get(ft(i),{'NumCalls'},NaN);
end
tbl=table(name_col,total_col,self_col,calls_col, ...
    'VariableNames',{'Function','TotalTime_s','SelfTime_s','NumCalls'});
end

function rows=match_rows(tbl,pattern)
rows=false(height(tbl),1);
for i=1:height(tbl)
    if contains(tbl.Function{i},pattern,'IgnoreCase',true)
        rows(i)=true;
    end
end
end

function s=summarize_rows(tbl,rows,wall_runtime_s)
if ~any(rows)
    s=struct('visible',false,'num_rows',0,'total_time_s',0,'self_time_s',0, ...
        'calls',0,'pct_of_wall',0,'matches',{{}});
    return;
end
s=struct();
s.visible=true;
s.num_rows=nnz(rows);
s.total_time_s=sum(tbl.TotalTime_s(rows),'omitnan');
s.self_time_s=sum(tbl.SelfTime_s(rows),'omitnan');
s.calls=sum(tbl.NumCalls(rows),'omitnan');
s.pct_of_wall=100*s.total_time_s/max(wall_runtime_s,eps);
s.matches=tbl.Function(rows);
end

function print_row(label,s)
if s.visible
    fprintf('  %-35s total=%10.6f s | self=%10.6f s | calls=%g\n', ...
        label,s.total_time_s,s.self_time_s,s.calls);
else
    fprintf('  %-35s not visible in current profiler table\n',label);
end
end

function val=safe_get(s,keys,default_val)
val=default_val;
for k=1:numel(keys)
    if isfield(s,keys{k})
        val=s.(keys{k});
        return;
    end
end
end

function must_exist(fname,errid)
if exist(fname,'file')~=2
    error(['profile_subchunk_agg_check_maxazi_rev14_real:' errid], ...
        '%s.m was not found on MATLAB path.',fname);
end
end