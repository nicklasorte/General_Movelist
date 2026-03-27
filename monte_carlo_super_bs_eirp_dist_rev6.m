function [rand_norm_eirp]=monte_carlo_super_bs_eirp_dist_rev6(app,super_array_bs_eirp_dist,reliability,rand_numbers)
%MONTE_CARLO_SUPER_BS_EIRP_DIST_REV6 Faster RNG-free MC EIRP interpolation.
% Focused optimization over rev5: remove per-row interp1 scalar calls.
% Strategy:
%   1) Build one spline piecewise polynomial object for all BS rows at once.
%   2) Evaluate each BS at its own random reliability via direct pp coefficients.
% This preserves rev5 output meaning/units and spline interpolation semantics.

% Keep signature compatibility with earlier revisions.
% app is intentionally unused.

[num_rows,num_cols]=size(super_array_bs_eirp_dist);

if num_cols<=1
    rand_norm_eirp=zeros(num_rows,1);
    return;
end

rel_col=reliability(:);
if ~issorted(rel_col)
    [rel_col,sort_idx]=sort(rel_col,'ascend');
    super_array_bs_eirp_dist=super_array_bs_eirp_dist(:,sort_idx);
end

rel_min=rel_col(1);
rel_max=rel_col(end);
xi=min(max(rand_numbers(:),rel_min),rel_max);

% Build spline PP for all rows in one call.
% For spline(x,y), numel(x) must match size(y,2). Each y row is one BS series.
y_for_spline=super_array_bs_eirp_dist;
pp=spline(rel_col,y_for_spline);
[breaks,coefs,pieces,order,dim]=unmkpp(pp);

if order~=4
    error('monte_carlo_super_bs_eirp_dist_rev6:UnexpectedPPOrder', ...
        'Expected cubic spline order 4, got order %d.',order);
end
if dim~=num_rows
    error('monte_carlo_super_bs_eirp_dist_rev6:UnexpectedPPDim', ...
        'Expected PP dim %d, got %d.',num_rows,dim);
end

% coefs layout is [pieces*dim x order] with dim blocks of "pieces" rows.
coefs3=reshape(coefs,[pieces,dim,order]);
a_all=coefs3(:,:,1);
b_all=coefs3(:,:,2);
c_all=coefs3(:,:,3);
d_all=coefs3(:,:,4);

% Locate xi interval index (1..pieces), matching ppval boundary handling.
% Since xi is clamped to [breaks(1), breaks(end)], this is bounded.
num_samples=numel(xi);
if num_samples~=num_rows
    error('monte_carlo_super_bs_eirp_dist_rev6:SizeMismatch', ...
        'Expected rand_numbers length %d, got %d.',num_rows,num_samples);
end

% Interval index: idx = 1 + count(breaks(2:end) <= xi).
% This maps xi==breaks(end) to last piece.
idx=ones(num_rows,1);
for k=2:numel(breaks)
    idx=idx + (xi>=breaks(k));
end
idx=min(idx,pieces);

base_break=breaks(idx);


dx=(xi-base_break');
% 'xdx'
% size(xi)
% size(base_break')
% size(dx)

row_idx=(1:num_rows).';
lin_idx=idx + (row_idx-1)*pieces;

a=a_all(lin_idx);
b=b_all(lin_idx);
c=c_all(lin_idx);
d=d_all(lin_idx);

% Force column vectors to avoid implicit expansion into NxN outputs.
a=a(:);
b=b(:);
c=c(:);
d=d(:);
dx=dx(:);

% 'abc'
% size(a)
% size(b)
% size(c)
% size(d)
% size(dx)
rand_norm_eirp=((a.*dx+b).*dx+c).*dx+d;
rand_norm_eirp=rand_norm_eirp(:);

end
