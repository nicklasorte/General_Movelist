function results = validate_agg_check_parfor_chunk_rev9_rev10_real(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,cell_sim_data,sim_folder,parallel_flag,varargin)
% Validate rev9 vs rev10 on identical real inputs.
% NOTE: rev10 assumes monte_carlo_Pr_dBm_rev3_app is present downstream.
% Validation depends on that downstream path being available in the runtime.

opts = parse_opts(varargin{:});

fprintf('\n=== VALIDATE agg_check_parfor_chunk rev9 vs rev10 (real inputs) ===\n');
fprintf('Assumption: monte_carlo_Pr_dBm_rev3_app exists and is available on path.\n');

% Run rev9
tic;
[out95_rev9,outmc_rev9] = agg_check_parfor_chunk_rev9_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,cell_sim_data,sim_folder,parallel_flag);
runtime_rev9 = toc;

% Run rev10
tic;
[out95_rev10,outmc_rev10] = agg_check_parfor_chunk_rev10_app(app,agg_check_reliability,point_idx,sim_number,mc_size,radar_beamwidth,base_protection_pts,mc_percentile,on_list_bs,data_label1,reliability,norm_aas_zero_elevation_data,string_prop_model,single_search_dist,off_idx,min_azimuth,max_azimuth,custom_antenna_pattern,cell_aas_dist_data,cell_sim_data,sim_folder,parallel_flag);
runtime_rev10 = toc;

cmp_95 = deep_compare(out95_rev9,out95_rev10,opts.abs_tol,opts.rel_tol);
cmp_mc = deep_compare(outmc_rev9,outmc_rev10,opts.abs_tol,opts.rel_tol);

max_abs_diff = max(cmp_95.max_abs_diff,cmp_mc.max_abs_diff);
max_rel_diff = max(cmp_95.max_rel_diff,cmp_mc.max_rel_diff);
all_equal = cmp_95.equal_within_tol && cmp_mc.equal_within_tol;

if runtime_rev10 > 0
    speedup = runtime_rev9 / runtime_rev10;
else
    speedup = NaN;
end

pass = all_equal && (max_abs_diff <= opts.abs_tol) && (max_rel_diff <= opts.rel_tol);

results = struct();
results.runtime_rev9 = runtime_rev9;
results.runtime_rev10 = runtime_rev10;
results.speedup = speedup;
results.max_abs_diff = max_abs_diff;
results.max_rel_diff = max_rel_diff;
results.pass = pass;
results.abs_tol = opts.abs_tol;
results.rel_tol = opts.rel_tol;
results.compare_95 = cmp_95;
results.compare_mc = cmp_mc;

fprintf('runtime_rev9 : %.6f s\n', runtime_rev9);
fprintf('runtime_rev10: %.6f s\n', runtime_rev10);
fprintf('speedup      : %.6fx (rev9/rev10)\n', speedup);
fprintf('max abs diff : %.6g\n', max_abs_diff);
fprintf('max rel diff : %.6g\n', max_rel_diff);
fprintf('thresholds   : abs<=%.3g, rel<=%.3g\n', opts.abs_tol, opts.rel_tol);
if pass
    fprintf('RESULT       : PASS\n');
else
    fprintf('RESULT       : FAIL\n');
    error('validate_agg_check_parfor_chunk_rev9_rev10_real:DriftExceeded', ...
        'rev9/rev10 drift exceeded thresholds (fail-closed).');
end

end

function opts = parse_opts(varargin)
opts = struct('abs_tol',1e-10,'rel_tol',1e-10);
if isempty(varargin)
    return;
end
if mod(numel(varargin),2) ~= 0
    error('parse_opts:NameValue','Optional args must be name/value pairs.');
end
for i = 1:2:numel(varargin)
    k = lower(string(varargin{i}));
    v = varargin{i+1};
    switch k
        case "abs_tol"
            opts.abs_tol = v;
        case "rel_tol"
            opts.rel_tol = v;
        otherwise
            error('parse_opts:UnknownOption','Unknown option: %s',k);
    end
end
end

function cmp = deep_compare(a,b,abs_tol,rel_tol)
cmp = struct('class_equal',strcmp(class(a),class(b)), ...
    'size_equal',isequal(size(a),size(b)), ...
    'nan_pattern_equal',true, ...
    'inf_pattern_equal',true, ...
    'max_abs_diff',0, ...
    'max_rel_diff',0, ...
    'equal_within_tol',true);

if ~(cmp.class_equal && cmp.size_equal)
    cmp.equal_within_tol = false;
    cmp.max_abs_diff = Inf;
    cmp.max_rel_diff = Inf;
    return;
end

if isnumeric(a) || islogical(a)
    cmp = compare_numeric(a,b,abs_tol,rel_tol,cmp);
elseif iscell(a)
    for i = 1:numel(a)
        child = deep_compare(a{i},b{i},abs_tol,rel_tol);
        cmp = merge_cmp(cmp,child,abs_tol,rel_tol);
    end
elseif isstruct(a)
    fa = fieldnames(a);
    fb = fieldnames(b);
    if ~isequal(sort(fa),sort(fb))
        cmp.equal_within_tol = false;
        cmp.max_abs_diff = Inf;
        cmp.max_rel_diff = Inf;
        return;
    end
    for k = 1:numel(a)
        for f = 1:numel(fa)
            child = deep_compare(a(k).(fa{f}),b(k).(fa{f}),abs_tol,rel_tol);
            cmp = merge_cmp(cmp,child,abs_tol,rel_tol);
        end
    end
else
    % Fallback for other MATLAB types.
    if ~isequaln(a,b)
        cmp.equal_within_tol = false;
        cmp.max_abs_diff = Inf;
        cmp.max_rel_diff = Inf;
    end
end
end

function cmp = compare_numeric(a,b,abs_tol,rel_tol,cmp)
if isempty(a) && isempty(b)
    return;
end
na = isnan(a); nb = isnan(b);
ia = isinf(a); ib = isinf(b);
cmp.nan_pattern_equal = isequal(na,nb);
cmp.inf_pattern_equal = isequal(ia,ib);
if ~(cmp.nan_pattern_equal && cmp.inf_pattern_equal)
    cmp.equal_within_tol = false;
    cmp.max_abs_diff = Inf;
    cmp.max_rel_diff = Inf;
    return;
end
finite_mask = isfinite(a) & isfinite(b);
if ~any(finite_mask(:))
    return;
end
da = abs(a(finite_mask) - b(finite_mask));
scale = max(abs(a(finite_mask)), abs(b(finite_mask)));
dr = da ./ max(scale, eps);
cmp.max_abs_diff = max(da);
cmp.max_rel_diff = max(dr);
cmp.equal_within_tol = (cmp.max_abs_diff <= abs_tol) && (cmp.max_rel_diff <= rel_tol);
end

function out = merge_cmp(a,b,abs_tol,rel_tol)
out = a;
out.class_equal = a.class_equal && b.class_equal;
out.size_equal = a.size_equal && b.size_equal;
out.nan_pattern_equal = a.nan_pattern_equal && b.nan_pattern_equal;
out.inf_pattern_equal = a.inf_pattern_equal && b.inf_pattern_equal;
out.max_abs_diff = max(a.max_abs_diff,b.max_abs_diff);
out.max_rel_diff = max(a.max_rel_diff,b.max_rel_diff);
out.equal_within_tol = out.class_equal && out.size_equal && out.nan_pattern_equal && ...
    out.inf_pattern_equal && (out.max_abs_diff <= abs_tol) && (out.max_rel_diff <= rel_tol) && ...
    a.equal_within_tol && b.equal_within_tol;
end
