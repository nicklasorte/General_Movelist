function [rand_norm_eirp]=monte_carlo_super_bs_eirp_dist_rev7(app,super_array_bs_eirp_dist,reliability,rand_numbers)
%MONTE_CARLO_SUPER_BS_EIRP_DIST_REV7 Correctness-first RNG-free MC EIRP interpolation.
% rev7 policy:
%   - preserve rev5 interpolation semantics first;
%   - keep shape-safe guards to prevent silent broadcasting/shape drift;
%   - avoid aggressive spline PP rewrites unless helper validator proves exactness.

% Keep signature compatibility with prior revisions.
% app is intentionally unused.

DEBUG_CHECKS=false;

[num_rows,num_cols]=size(super_array_bs_eirp_dist);

if num_cols<=1
    rand_norm_eirp=zeros(num_rows,1);
    return;
end

rel_row=reliability(:).';
if numel(rel_row)~=num_cols
    error('monte_carlo_super_bs_eirp_dist_rev7:ReliabilityLengthMismatch', ...
        'reliability length (%d) must match number of EIRP columns (%d).',numel(rel_row),num_cols);
end

if ~issorted(rel_row)
    [rel_row,sort_idx]=sort(rel_row,'ascend');
    super_array_bs_eirp_dist=super_array_bs_eirp_dist(:,sort_idx);
end

xi=rand_numbers(:);
if numel(xi)~=num_rows
    error('monte_carlo_super_bs_eirp_dist_rev7:QueryLengthMismatch', ...
        'rand_numbers length (%d) must match number of EIRP rows (%d).',numel(xi),num_rows);
end

rel_min=rel_row(1);
rel_max=rel_row(end);
xi=min(max(xi,rel_min),rel_max);

if DEBUG_CHECKS
    assert(isrow(rel_row),'Expected reliability to be a row vector for interp1.');
    assert(size(super_array_bs_eirp_dist,1)==num_rows,'Y row size changed unexpectedly.');
    assert(size(super_array_bs_eirp_dist,2)==numel(rel_row),'Y columns must match X length.');
    if any(~isfinite(rel_row)) || any(~isfinite(super_array_bs_eirp_dist),'all') || any(~isfinite(xi))
        error('monte_carlo_super_bs_eirp_dist_rev7:NonFiniteInput', ...
            'Non-finite values detected in interpolation inputs.');
    end
end

rand_norm_eirp=NaN(num_rows,1);
for n=1:1:num_rows
    rand_norm_eirp(n)=interp1(rel_row,super_array_bs_eirp_dist(n,:),xi(n),'spline');
end

end
