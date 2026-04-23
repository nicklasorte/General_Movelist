function results = profile_subchunk_agg_check_maxazi_rev15_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
%PROFILE_SUBCHUNK_AGG_CHECK_MAXAZI_REV15_REAL
% Profile rev15 on real inputs and report timing for dominant helper paths.

must_exist('subchunk_agg_check_maxazi_rev15','MissingRev15');
must_exist('monte_carlo_clutter_rev4_app','MissingClutterRev4');

% Baseline from measured rev14 profiling evidence supplied for this pass.
baseline_rev14=struct();
baseline_rev14.monte_carlo_super_bs_eirp_dist_rev6_total_s=1.266;
baseline_rev14.monte_carlo_clutter_rev3_app_total_s=2.309;
baseline_rev14.monte_carlo_Pr_dBm_rev2_app_total_s=2.275;
baseline_rev14.nearestpoint_app_total_s=0.354;
baseline_rev14.db2pow_total_s=0.210;

opts=struct();
opts.AziChunkRev15=128;
opts.TopN=20;
opts.EnableDetailBuiltin=true;
opts.MaterialDropThresholdFraction=0.10;

fprintf('\n=== PROFILE REV15 (REAL INPUTS) ===\n');
fprintf('AZI_CHUNK rev15: %d\n',opts.AziChunkRev15);

profile off;
profile clear;
if opts.EnableDetailBuiltin
    profile('-memory','off','-detail','builtin');
end
profile on;

wall_tic=tic;
out=subchunk_agg_check_maxazi_rev15(app,cell_aas_dist_data,array_bs_azi_data, ...
    radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs, ...
    cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss, ...
    custom_antenna_pattern,sub_point_idx,opts.AziChunkRev15); %#ok<NASGU>
wall_runtime_s=toc(wall_tic);

profile off;
pinfo=profile('info');
if ~isfield(pinfo,'FunctionTable') || isempty(pinfo.FunctionTable)
    error('profile_subchunk_agg_check_maxazi_rev15_real:EmptyProfile', ...
        'MATLAB profile did not return function timing data.');
end

tbl=build_profile_table(pinfo.FunctionTable);
[~,idx_total]=sort(tbl.TotalTime_s,'descend','MissingPlacement','last');
top_n=min(opts.TopN,height(tbl));
top_total=tbl(idx_total(1:top_n),:);

key=struct();
key.subchunk_agg_check_maxazi_rev15=summarize_rows(tbl,match_rows(tbl,'subchunk_agg_check_maxazi_rev15'),wall_runtime_s);
key.monte_carlo_clutter_rev4_app=summarize_rows(tbl,match_rows(tbl,'monte_carlo_clutter_rev4_app'),wall_runtime_s);
key.monte_carlo_Pr_dBm_rev2_app=summarize_rows(tbl,match_rows(tbl,'monte_carlo_Pr_dBm_rev2_app'),wall_runtime_s);
key.monte_carlo_super_bs_eirp_dist_rev6=summarize_rows(tbl,match_rows(tbl,'monte_carlo_super_bs_eirp_dist_rev6'),wall_runtime_s);
key.nearestpoint_app=summarize_rows(tbl,match_rows(tbl,'nearestpoint_app'),wall_runtime_s);
key.db2pow=summarize_rows(tbl,match_rows(tbl,'db2pow'),wall_runtime_s);

summary_table=table( ...
    {'subchunk_agg_check_maxazi_rev15';'monte_carlo_clutter_rev4_app';'monte_carlo_Pr_dBm_rev2_app'; ...
     'monte_carlo_super_bs_eirp_dist_rev6';'nearestpoint_app';'db2pow'}, ...
    [key.subchunk_agg_check_maxazi_rev15.total_time_s;key.monte_carlo_clutter_rev4_app.total_time_s; ...
     key.monte_carlo_Pr_dBm_rev2_app.total_time_s;key.monte_carlo_super_bs_eirp_dist_rev6.total_time_s; ...
     key.nearestpoint_app.total_time_s;key.db2pow.total_time_s], ...
    [key.subchunk_agg_check_maxazi_rev15.calls;key.monte_carlo_clutter_rev4_app.calls; ...
     key.monte_carlo_Pr_dBm_rev2_app.calls;key.monte_carlo_super_bs_eirp_dist_rev6.calls; ...
     key.nearestpoint_app.calls;key.db2pow.calls], ...
    [key.subchunk_agg_check_maxazi_rev15.pct_of_wall;key.monte_carlo_clutter_rev4_app.pct_of_wall; ...
     key.monte_carlo_Pr_dBm_rev2_app.pct_of_wall;key.monte_carlo_super_bs_eirp_dist_rev6.pct_of_wall; ...
     key.nearestpoint_app.pct_of_wall;key.db2pow.pct_of_wall], ...
    'VariableNames',{'Function','TotalTime_s','Calls','PctWall'});

fprintf('\nTop contributors by total time:\n');
disp(top_total);

fprintf('\nSummary timing table (requested functions):\n');
disp(summary_table);

clutter_rev14=baseline_rev14.monte_carlo_clutter_rev3_app_total_s;
clutter_rev15=key.monte_carlo_clutter_rev4_app.total_time_s;
clutter_drop_fraction=(clutter_rev14-clutter_rev15)/max(clutter_rev14,eps);
material_clutter_drop=clutter_drop_fraction>=opts.MaterialDropThresholdFraction;

fprintf('Clutter helper comparison vs rev14 baseline: rev14=%.3f s, rev15=%.3f s, drop=%.1f%%\n', ...
    clutter_rev14,clutter_rev15,100*clutter_drop_fraction);
fprintf('Material clutter-time drop (>=%.0f%%): %s\n', ...
    100*opts.MaterialDropThresholdFraction,yesno(material_clutter_drop));

tracked_names=summary_table.Function;
tracked_time=summary_table.TotalTime_s;
[~,max_idx]=max(tracked_time);
new_top_bottleneck=tracked_names{max_idx};

fprintf('Top bottleneck among tracked functions: %s (%.3f s)\n', ...
    new_top_bottleneck,tracked_time(max_idx));

results=struct();
results.options=opts;
results.wall_runtime_s=wall_runtime_s;
results.top_by_total=top_total;
results.summary=key;
results.summary_table=summary_table;
results.baseline_rev14=baseline_rev14;
results.clutter_drop_fraction_vs_rev14=clutter_drop_fraction;
results.material_clutter_drop=material_clutter_drop;
results.new_top_bottleneck_tracked=new_top_bottleneck;
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

function val=safe_get(s,keys,default_val)
val=default_val;
for k=1:numel(keys)
    if isfield(s,keys{k})
        val=s.(keys{k});
        return;
    end
end
end

function txt=yesno(tf)
if tf
    txt='YES';
else
    txt='NO';
end
end

function must_exist(fname,errid)
if exist(fname,'file')~=2
    error(['profile_subchunk_agg_check_maxazi_rev15_real:' errid], ...
        '%s.m was not found on MATLAB path.',fname);
end
end
