function results = profile_agg_check_parfor_chunk_rev9_real(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,cell_sim_data,sim_folder,parallel_flag,varargin)
% Profile agg_check_parfor_chunk_rev9_app on real inputs.
% NOTE: This path depends on downstream functions (including
% monte_carlo_Pr_dBm_rev3_app once wired in the active compute stack).

opts = parse_opts(varargin{:});
must_exist('agg_check_parfor_chunk_rev9_app','MissingRev9');

fprintf('\n=== PROFILE agg_check_parfor_chunk_rev9_app (real inputs) ===\n');

profile off;
profile clear;
if opts.enable_detail_builtin
    profile('-memory','off','-detail','builtin');
end
profile on;

wall_tic = tic;
[out95,outmc] = agg_check_parfor_chunk_rev9_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,cell_sim_data,sim_folder,parallel_flag); %#ok<NASGU>
wall_runtime_s = toc(wall_tic);

profile off;
pinfo = profile('info');
if ~isfield(pinfo,'FunctionTable') || isempty(pinfo.FunctionTable)
    error('profile_agg_check_parfor_chunk_rev9_real:EmptyProfile','Profiler returned no rows.');
end

tbl = build_profile_table(pinfo.FunctionTable);
[~,idx_total] = sort(tbl.TotalTime_s,'descend','MissingPlacement','last');
top_n = min(opts.top_n,height(tbl));
top_total = tbl(idx_total(1:top_n),:);

fprintf('\nTop contributors by total time:\n');
disp(top_total);

% Bucketized attribution for requested dominance statement.
orchestration_patterns = {'agg_check_parfor_chunk_rev9_app','parfor_randchunk_aggcheck_rev8_claude', ...
    'ParForWaitbar','dynamic_mc_chunks_rev1','off_axis_gain_bs2fed_rev1'};

downstream_patterns = {'subchunk_agg_check_maxazi_','monte_carlo_','interp1','nearestpoint_app'};

disk_patterns = {'save','load','persistent_var_exist_with_corruption','persistent_delete_rev1','load_variable_with_retry'};

orchestration = summarize_pattern_group(tbl,orchestration_patterns,wall_runtime_s);
downstream = summarize_pattern_group(tbl,downstream_patterns,wall_runtime_s);
diskio = summarize_pattern_group(tbl,disk_patterns,wall_runtime_s);

bucket_tbl = table( ...
    {'orchestration/parfor-wrapper';'downstream-subchunk/helper-compute';'checkpoint/disk-activity'}, ...
    [orchestration.total_time_s;downstream.total_time_s;diskio.total_time_s], ...
    [orchestration.pct_of_wall;downstream.pct_of_wall;diskio.pct_of_wall], ...
    'VariableNames',{'Bucket','TotalTime_s','PctOfWall'});

[~,dom_idx] = max(bucket_tbl.TotalTime_s);
dominant_bucket = bucket_tbl.Bucket{dom_idx};

fprintf('\nSummary table (requested dominance categories):\n');
disp(bucket_tbl);
fprintf('Dominant runtime bucket: %s\n', dominant_bucket);

results = struct();
results.runtime_s = wall_runtime_s;
results.top_contributors = top_total;
results.bucket_table = bucket_tbl;
results.dominant_bucket = dominant_bucket;
results.output_size_95 = size(out95);
results.output_size_mc = size(outmc);
results.full_profile_table = tbl;
results.notes = 'Assumes downstream path availability (including monte_carlo_Pr_dBm_rev3_app when active in compute stack).';

end

function opts = parse_opts(varargin)
opts = struct('top_n',20,'enable_detail_builtin',true);
if isempty(varargin), return; end
if mod(numel(varargin),2) ~= 0
    error('parse_opts:NameValue','Optional args must be name/value pairs.');
end
for i = 1:2:numel(varargin)
    k = lower(string(varargin{i}));
    v = varargin{i+1};
    switch k
        case "top_n"
            opts.top_n = v;
        case "enable_detail_builtin"
            opts.enable_detail_builtin = logical(v);
        otherwise
            error('parse_opts:UnknownOption','Unknown option: %s',k);
    end
end
end

function tbl = build_profile_table(ft)
n = numel(ft);
name_col = cell(n,1);
total_col = zeros(n,1);
self_col = zeros(n,1);
calls_col = zeros(n,1);
for i = 1:n
    name_col{i} = safe_get(ft(i),{'FunctionName','CompleteName','FileName'},'<unknown>');
    total_col(i) = safe_get(ft(i),{'TotalTime'},NaN);
    self_col(i) = safe_get(ft(i),{'SelfTime'},NaN);
    calls_col(i) = safe_get(ft(i),{'NumCalls'},NaN);
end
tbl = table(name_col,total_col,self_col,calls_col, ...
    'VariableNames',{'Function','TotalTime_s','SelfTime_s','NumCalls'});
end

function s = summarize_pattern_group(tbl,patterns,wall_runtime_s)
rows = false(height(tbl),1);
for p = 1:numel(patterns)
    rows = rows | match_rows(tbl,patterns{p});
end
s = struct();
s.patterns = patterns;
s.num_rows = nnz(rows);
s.total_time_s = sum(tbl.TotalTime_s(rows),'omitnan');
s.self_time_s = sum(tbl.SelfTime_s(rows),'omitnan');
s.calls = sum(tbl.NumCalls(rows),'omitnan');
s.pct_of_wall = 100*s.total_time_s/max(wall_runtime_s,eps);
s.matches = tbl.Function(rows);
end

function rows = match_rows(tbl,pattern)
rows = false(height(tbl),1);
for i = 1:height(tbl)
    if contains(tbl.Function{i},pattern,'IgnoreCase',true)
        rows(i) = true;
    end
end
end

function val = safe_get(s,keys,default_val)
val = default_val;
for k = 1:numel(keys)
    if isfield(s,keys{k})
        val = s.(keys{k});
        return;
    end
end
end

function must_exist(fname,errid)
if exist(fname,'file')~=2
    error(['profile_agg_check_parfor_chunk_rev9_real:' errid], ...
        '%s.m was not found on MATLAB path.',fname);
end
end
