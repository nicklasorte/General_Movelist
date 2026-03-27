function [rand_norm_eirp]=monte_carlo_super_bs_eirp_dist_rev7(app,super_array_bs_eirp_dist,reliability,rand_numbers)
%MONTE_CARLO_SUPER_BS_EIRP_DIST_REV7 Corrected fast RNG-free MC EIRP interpolation.
% Fix over rev6: correct reshape dimension order for unmkpp coefficient layout.
% unmkpp stores coefs as [dim*pieces x order] with dim consecutive rows per piece
% (dim varies fastest). Correct reshape is [dim, pieces, order], NOT [pieces, dim, order].
%
% Preserves rev5 semantics exactly: per-row spline interpolation of EIRP vs reliability.
% Strategy:
%   1) Build one spline piecewise polynomial object for all BS rows at once.
%   2) Evaluate each BS at its own random reliability via direct pp coefficients.

% app is intentionally unused (signature compatibility).

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
% spline(x,Y) with size(Y,2)==numel(x) treats each row of Y as a separate function.
pp=spline(rel_col,super_array_bs_eirp_dist);
[breaks,coefs,pieces,order,dim]=unmkpp(pp);

if order~=4
    error('monte_carlo_super_bs_eirp_dist_rev7:UnexpectedPPOrder', ...
        'Expected cubic spline order 4, got order %d.',order);
end
if dim~=num_rows
    error('monte_carlo_super_bs_eirp_dist_rev7:UnexpectedPPDim', ...
        'Expected PP dim %d, got %d.',num_rows,dim);
end

% coefs layout from unmkpp: [dim*pieces x order] with dim consecutive rows per piece.
% Row (p-1)*dim + d = piece p, dimension (BS) d.
% Correct reshape: [dim, pieces, order] so coefs3(d, p, k) = coef for BS d, piece p, power k.
coefs3=reshape(coefs,[dim,pieces,order]);
a_all=coefs3(:,:,1);  % [dim x pieces] = [num_rows x pieces]
b_all=coefs3(:,:,2);
c_all=coefs3(:,:,3);
d_all=coefs3(:,:,4);

% Locate xi interval index (1..pieces), matching ppval boundary handling.
num_samples=numel(xi);
if num_samples~=num_rows
    error('monte_carlo_super_bs_eirp_dist_rev7:SizeMismatch', ...
        'Expected rand_numbers length %d, got %d.',num_rows,num_samples);
end

% Interval index via cumulative comparison.
idx=ones(num_rows,1);
for k=2:numel(breaks)
    idx=idx + (xi>=breaks(k));
end
idx=min(idx,pieces);

base_break=breaks(idx);
dx=xi-base_break(:);

% Linear index into [dim x pieces] arrays: row d, column p → (p-1)*dim + d.
row_idx=(1:num_rows).';
lin_idx=row_idx + (idx-1)*dim;

a=a_all(lin_idx);
b=b_all(lin_idx);
c=c_all(lin_idx);
d_coef=d_all(lin_idx);

% Force column vectors.
a=a(:);
b=b(:);
c=c(:);
d_coef=d_coef(:);
dx=dx(:);

% Horner evaluation of cubic: ((a*dx + b)*dx + c)*dx + d
rand_norm_eirp=((a.*dx+b).*dx+c).*dx+d_coef;
rand_norm_eirp=rand_norm_eirp(:);

end
