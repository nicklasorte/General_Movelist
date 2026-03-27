function results = profile_subchunk_agg_check_maxazi_rev11_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
%PROFILE_SUBCHUNK_AGG_CHECK_MAXAZI_REV11_REAL
% Profile rev11 on exact real inputs and report dominant runtime contributors.

if exist('subchunk_agg_check_maxazi_rev11','file')~=2
    error('profile_subchunk_agg_check_maxazi_rev11_real:MissingRev11', ...
        'subchunk_agg_check_maxazi_rev11.m was not found on MATLAB path.');
end

opts = struct();
opts.AziChunkRev11 = 128;
opts.TopN = 15;
opts.EnableDetailBuiltin = true;

fprintf('\n=== PROFILE REV11 (REAL INPUTS) ===\n');
fprintf('AZI_CHUNK rev11: %d\n',opts.AziChunkRev11);

profile off;
profile clear;
if opts.EnableDetailBuiltin
    profile('-memory','off','-detail','builtin');
end
profile on;

runtime_tic=tic;
out = subchunk_agg_check_maxazi_rev11(app,cell_aas_dist_data,array_bs_azi_data, ...
    radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
    cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
    custom_antenna_pattern,sub_point_idx,opts.AziChunkRev11); %#ok<NASGU>
wall_runtime_s=toc(runtime_tic);

profile off;
pinfo=profile('info');

if ~isfield(pinfo,'FunctionTable') || isempty(pinfo.FunctionTable)
    error('profile_subchunk_agg_check_maxazi_rev11_real:EmptyProfile', ...
        'MATLAB profile did not return function timing data.');
end

ft=pinfo.FunctionTable;
name_col=cell(numel(ft),1);
total_col=zeros(numel(ft),1);
self_col=zeros(numel(ft),1);
calls_col=zeros(numel(ft),1);
for i=1:numel(ft)
    name_col{i}=safe_get(ft(i),{'FunctionName','CompleteName','FileName'},'<unknown>');
    total_col(i)=safe_get(ft(i),{'TotalTime'},NaN);
    self_col(i)=safe_get(ft(i),{'SelfTime'},NaN);
    calls_col(i)=safe_get(ft(i),{'NumCalls'},NaN);
end

tbl=table(name_col,total_col,self_col,calls_col, ...
    'VariableNames',{'Function','TotalTime_s','SelfTime_s','NumCalls'});

[~,idx_total]=sort(tbl.TotalTime_s,'descend','MissingPlacement','last');
[~,idx_self]=sort(tbl.SelfTime_s,'descend','MissingPlacement','last');

top_n=min(opts.TopN,height(tbl));
top_total=tbl(idx_total(1:top_n),:);
top_self=tbl(idx_self(1:top_n),:);

fprintf('\nTop contributors by total time:\n');
disp(top_total);

fprintf('\nTop contributors by self time:\n');
disp(top_self);

key_names = { ...
    'subchunk_agg_check_maxazi_rev11', ...
    'monte_carlo_Pr_dBm_rev2_app', ...
    'monte_carlo_super_bs_eirp_dist_rev5', ...
    'monte_carlo_clutter_rev3_app'};

key_times = struct();
for i=1:numel(key_names)
    key=key_names{i};
    row=match_rows(tbl,key);
    key_times.(matlab.lang.makeValidName(key))=summarize_rows(tbl,row,wall_runtime_s);
end

% Off-axis gain build path proxy: nearestpoint + azimuth contributions.
off_axis_parts={'nearestpoint_app','azimuth'};
off_axis_rows=false(height(tbl),1);
for i=1:numel(off_axis_parts)
    off_axis_rows=off_axis_rows | match_rows(tbl,off_axis_parts{i});
end
off_axis_summary=summarize_rows(tbl,off_axis_rows,wall_runtime_s);

% Aggregation path proxy: db2pow/pow2db/sum/max inside rev11 aggregation loop.
agg_parts={'db2pow','pow2db','sum','max'};
agg_rows=false(height(tbl),1);
for i=1:numel(agg_parts)
    agg_rows=agg_rows | match_rows(tbl,agg_parts{i});
end
agg_summary=summarize_rows(tbl,agg_rows,wall_runtime_s);

fprintf('\nExplicit target function timings:\n');
print_key('subchunk_agg_check_maxazi_rev11',key_times.subchunk_agg_check_maxazi_rev11);
print_key('monte_carlo_Pr_dBm_rev2_app',key_times.monte_carlo_Pr_dBm_rev2_app);
print_key('monte_carlo_super_bs_eirp_dist_rev5',key_times.monte_carlo_super_bs_eirp_dist_rev5);
print_key('monte_carlo_clutter_rev3_app',key_times.monte_carlo_clutter_rev3_app);

fprintf('\nPath proxies (if visible in profiler):\n');
print_key('off-axis gain build path proxy',off_axis_summary);
print_key('aggregation path proxy',agg_summary);

% Select highest-value optimization target from measured contributors.
focus_labels={ ...
    'aggregation_path_proxy', ...
    'monte_carlo_Pr_dBm_rev2_app', ...
    'monte_carlo_super_bs_eirp_dist_rev5', ...
    'monte_carlo_clutter_rev3_app', ...
    'off_axis_gain_build_proxy'};
focus_times=[ ...
    agg_summary.total_time_s, ...
    key_times.monte_carlo_Pr_dBm_rev2_app.total_time_s, ...
    key_times.monte_carlo_super_bs_eirp_dist_rev5.total_time_s, ...
    key_times.monte_carlo_clutter_rev3_app.total_time_s, ...
    off_axis_summary.total_time_s];

[best_time,best_idx]=max(focus_times);
best_label=focus_labels{best_idx};
if ~isfinite(best_time) || best_time<=0
    recommendation='Insufficient profiler signal; rerun with detail builtin enabled and larger workload.';
else
    recommendation=sprintf('Optimize %s first (largest measured contributor: %.6f s).',best_label,best_time);
end

fprintf('\nRecommendation: %s\n',recommendation);

results=struct();
results.options=opts;
results.wall_runtime_s=wall_runtime_s;
results.top_by_total=top_total;
results.top_by_self=top_self;
results.key_timings=key_times;
results.off_axis_gain_build_path=off_axis_summary;
results.aggregation_path=agg_summary;
results.recommended_target=best_label;
results.recommendation_text=recommendation;
results.full_profile_table=tbl;

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

function rows=match_rows(tbl,pattern)
rows=false(height(tbl),1);
for i=1:height(tbl)
    fn=tbl.Function{i};
    if contains(fn,pattern,'IgnoreCase',true)
        rows(i)=true;
    end
end
end

function s=summarize_rows(tbl,rows,wall_runtime_s)
if ~any(rows)
    s=struct('visible',false,'num_rows',0,'total_time_s',0,'self_time_s',0, ...
        'pct_of_wall',0,'pct_of_profile_total',0,'calls',0,'matches',{{}});
    return;
end

total_profile_time=sum(tbl.TotalTime_s,'omitnan');
s=struct();
s.visible=true;
s.num_rows=nnz(rows);
s.total_time_s=sum(tbl.TotalTime_s(rows),'omitnan');
s.self_time_s=sum(tbl.SelfTime_s(rows),'omitnan');
s.pct_of_wall=100*s.total_time_s/max(wall_runtime_s,eps);
s.pct_of_profile_total=100*s.total_time_s/max(total_profile_time,eps);
s.calls=sum(tbl.NumCalls(rows),'omitnan');
s.matches=tbl.Function(rows);
end

function print_key(label,s)
if s.visible
    fprintf('  %-38s total=%10.6f s | self=%10.6f s | wall%%=%6.2f%% | calls=%g\n', ...
        label,s.total_time_s,s.self_time_s,s.pct_of_wall,s.calls);
else
    fprintf('  %-38s not visible in current profiler table\n',label);
end
end