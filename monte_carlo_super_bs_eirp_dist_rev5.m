function [rand_norm_eirp]=monte_carlo_super_bs_eirp_dist_rev5(app,super_array_bs_eirp_dist,reliability,rand_numbers)
%MONTE_CARLO_SUPER_BS_EIRP_DIST_REV5 RNG-free MC EIRP interpolation.
%CODEX rewrite

[num_rows,num_cols]=size(super_array_bs_eirp_dist); %#ok<NASGU>

if num_cols>1
    [reliability,sort_idx]=sort(reliability(:).');
    super_array_bs_eirp_dist=super_array_bs_eirp_dist(:,sort_idx);

    rel_min=min(reliability);
    rel_max=max(reliability);
    rand_numbers=min(max(rand_numbers(:),rel_min),rel_max);

    rand_norm_eirp=NaN(num_rows,1);
    for n=1:1:num_rows
        rand_norm_eirp(n)=interp1(reliability,super_array_bs_eirp_dist(n,:),rand_numbers(n),'spline');
    end
else
    rand_norm_eirp=zeros(num_rows,1);
end

end