function results = profile_subchunk_agg_check_maxazi_rev20_real(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
%PROFILE_SUBCHUNK_AGG_CHECK_MAXAZI_REV20_REAL
% Profile rev20 and compare timing directly against golden rev11.

must_exist('subchunk_agg_check_maxazi_rev11','MissingRev11');
must_exist('subchunk_agg_check_maxazi_rev20','MissingRev20');

opts=struct();
opts.AziChunkRev11=128;
opts.AziChunkRev20=128;
opts.TopN=20;
opts.EnableDetailBuiltin=true;
opts.MaterialDropThreshold=0.20;

fprintf('\n=== PROFILE REV20 (REAL INPUTS, WITH REV11 BASELINE) ===\n');
fprintf('AZI_CHUNK rev11: %d | rev20: %d\n',opts.AziChunkRev11,opts.AziChunkRev20);

% Measure rev11 profile first as golden runtime baseline on identical inputs.
[baseline_tbl,baseline_wall_s,baseline_top]=run_profile_once(@subchunk_agg_check_maxazi_rev11,opts.AziChunkRev11, ...
    opts.EnableDetailBuiltin,app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth, ...
    min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx, ...
    rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);

% Measure rev20 profile on the same inputs.
[tbl,wall_runtime_s,top_total]=run_profile_once(@subchunk_agg_check_maxazi_rev20,opts.AziChunkRev20, ...
    opts.EnableDetailBuiltin,app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth, ...
    min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx, ...
    rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx);

fprintf('\nTop contributors by total time (rev20):\n');
disp(top_total);

% Required reporting targets for rev20.
key=struct();
key.subchunk_agg_check_maxazi_rev20=summarize_rows(tbl,match_rows(tbl,'subchunk_agg_check_maxazi_rev20'),wall_runtime_s);
key.monte_carlo_clutter_rev5_app=summarize_rows(tbl,match_rows(tbl,'monte_carlo_clutter_rev5_app'),wall_runtime_s);
key.monte_carlo_Pr_dBm_rev3_app=summarize_rows(tbl,match_rows(tbl,'monte_carlo_Pr_dBm_rev3_app'),wall_runtime_s);
key.monte_carlo_Pr_dBm_rev2_app=summarize_rows(tbl,match_rows(tbl,'monte_carlo_Pr_dBm_rev2_app'),wall_runtime_s);

if exist('monte_carlo_super_bs_eirp_dist_rev8','file')==2
    eirp_pattern='monte_carlo_super_bs_eirp_dist_rev8';
elseif exist('monte_carlo_super_bs_eirp_dist_rev5','file')==2
    eirp_pattern='monte_carlo_super_bs_eirp_dist_rev5';
else
    eirp_pattern='monte_carlo_super_bs_eirp_dist';
end
key.monte_carlo_super_bs_eirp_dist_valid=summarize_rows(tbl,match_rows(tbl,eirp_pattern),wall_runtime_s);
key.nearestpoint_app=summarize_rows(tbl,match_rows(tbl,'nearestpoint_app'),wall_runtime_s);
key.db2pow=summarize_rows(tbl,match_rows(tbl,'db2pow'),wall_runtime_s);
key.discretize=summarize_rows(tbl,match_rows(tbl,'discretize'),wall_runtime_s);

% Matching rev11 timing keys for direct baseline comparisons.
base=struct();
base.subchunk_agg_check_maxazi_rev11=summarize_rows(baseline_tbl,match_rows(baseline_tbl,'subchunk_agg_check_maxazi_rev11'),baseline_wall_s);
base.monte_carlo_clutter_rev3_app=summarize_rows(baseline_tbl,match_rows(baseline_tbl,'monte_carlo_clutter_rev3_app'),baseline_wall_s);
base.monte_carlo_Pr_dBm_rev2_app=summarize_rows(baseline_tbl,match_rows(baseline_tbl,'monte_carlo_Pr_dBm_rev2_app'),baseline_wall_s);
base.monte_carlo_super_bs_eirp_dist_valid=summarize_rows(baseline_tbl,match_rows(baseline_tbl,eirp_pattern),baseline_wall_s);
base.nearestpoint_app=summarize_rows(baseline_tbl,match_rows(baseline_tbl,'nearestpoint_app'),baseline_wall_s);
base.db2pow=summarize_rows(baseline_tbl,match_rows(baseline_tbl,'db2pow'),baseline_wall_s);

fprintf('\nSummary timing table (requested functions):\n');
print_row('subchunk_agg_check_maxazi_rev20',key.subchunk_agg_check_maxazi_rev20);
print_row('monte_carlo_clutter_rev5_app',key.monte_carlo_clutter_rev5_app);
print_row('monte_carlo_Pr_dBm_rev3_app',key.monte_carlo_Pr_dBm_rev3_app);
print_row('monte_carlo_Pr_dBm_rev2_app (residual)',key.monte_carlo_Pr_dBm_rev2_app);
print_row(eirp_pattern,key.monte_carlo_super_bs_eirp_dist_valid);
print_row('nearestpoint_app',key.nearestpoint_app);
print_row('db2pow',key.db2pow);
print_row('discretize',key.discretize);

pr_drop_frac=(base.monte_carlo_Pr_dBm_rev2_app.total_time_s-key.monte_carlo_Pr_dBm_rev3_app.total_time_s) ...
    /max(base.monte_carlo_Pr_dBm_rev2_app.total_time_s,eps);
material_pr_drop=pr_drop_frac>=opts.MaterialDropThreshold;

fprintf('\nRuntime comparison vs rev11 baseline (same run harness):\n');
fprintf('  subchunk total: rev11=%.6f s | rev20=%.6f s | speedup=%.3fx\n', ...
    baseline_wall_s,wall_runtime_s,baseline_wall_s/max(wall_runtime_s,eps));
fprintf('  Pr helper: rev11 rev2=%.6f s | rev20 rev3=%.6f s | drop=%.2f%%\n', ...
    base.monte_carlo_Pr_dBm_rev2_app.total_time_s,key.monte_carlo_Pr_dBm_rev3_app.total_time_s,100*pr_drop_frac);
if material_pr_drop
    fprintf('  MATERIAL Pr helper drop vs rev11: YES\n');
else
    fprintf('  MATERIAL Pr helper drop vs rev11: NO\n');
end

focus_names={'monte_carlo_Pr_dBm_rev3_app',eirp_pattern,'monte_carlo_clutter_rev5_app','nearestpoint_app','db2pow'};
focus_times=[key.monte_carlo_Pr_dBm_rev3_app.total_time_s, ...
    key.monte_carlo_super_bs_eirp_dist_valid.total_time_s, ...
    key.monte_carlo_clutter_rev5_app.total_time_s, ...
    key.nearestpoint_app.total_time_s, ...
    key.db2pow.total_time_s];
[~,top_idx]=max(focus_times);
new_top_bottleneck=focus_names{top_idx};
fprintf('  New top bottleneck (among requested targets): %s\n',new_top_bottleneck);

results=struct();
results.options=opts;
results.rev11_wall_runtime_s=baseline_wall_s;
results.rev20_wall_runtime_s=wall_runtime_s;
results.speedup_rev11_over_rev20=baseline_wall_s/max(wall_runtime_s,eps);
results.top_by_total_rev11=baseline_top;
results.top_by_total_rev20=top_total;
results.summary_rev11=base;
results.summary_rev20=key;
results.pr_drop_fraction_vs_rev11=pr_drop_frac;
results.material_pr_drop_vs_rev11=material_pr_drop;
results.new_top_bottleneck=new_top_bottleneck;
results.full_profile_table_rev11=baseline_tbl;
results.full_profile_table_rev20=tbl;

end

function [tbl,wall_runtime_s,top_total]=run_profile_once(fhandle,azi_chunk,enable_detail_builtin,app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth,base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability,on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx)
profile off;
profile clear;
if enable_detail_builtin
    profile('-memory','off','-detail','builtin');
end
profile on;

wall_tic=tic;
out=fhandle(app,cell_aas_dist_data,array_bs_azi_data,radar_beamwidth,min_azimuth,max_azimuth, ...
    base_protection_pts,point_idx,on_list_bs,cell_sim_chunk_idx,rand_seed1,agg_check_reliability, ...
    on_full_Pr_dBm,clutter_loss,custom_antenna_pattern,sub_point_idx,azi_chunk); %#ok<NASGU>
wall_runtime_s=toc(wall_tic);

profile off;
pinfo=profile('info');
if ~isfield(pinfo,'FunctionTable') || isempty(pinfo.FunctionTable)
    error('profile_subchunk_agg_check_maxazi_rev20_real:EmptyProfile', ...
        'MATLAB profile did not return function timing data.');
end

tbl=build_profile_table(pinfo.FunctionTable);
[~,idx_total]=sort(tbl.TotalTime_s,'descend','MissingPlacement','last');
top_n=min(20,height(tbl));
top_total=tbl(idx_total(1:top_n),:);
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
    fprintf('  %-42s total=%10.6f s | self=%10.6f s | calls=%g\n', ...
        label,s.total_time_s,s.self_time_s,s.calls);
else
    fprintf('  %-42s not visible in current profiler table\n',label);
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
    error(['profile_subchunk_agg_check_maxazi_rev20_real:' errid], ...
        '%s.m was not found on MATLAB path.',fname);
end
end
