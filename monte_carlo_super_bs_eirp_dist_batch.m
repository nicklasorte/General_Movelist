function [all_rand_norm_eirp]=monte_carlo_super_bs_eirp_dist_batch(app,super_array_bs_eirp_dist,rand_seed1,mc_idx_vec,reliability)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Batch version of monte_carlo_super_bs_eirp_dist_rev4.
% Returns [num_rows x num_mc] instead of [num_rows x 1].
%
% One rng() call per chunk rather than one per mc_iter.
% griddedInterpolant pre-processes spline knots once per BS row, then
% evaluates all num_mc query points efficiently — faster than repeated
% interp1 calls that recompute knots every iteration.
% Seed: rand_seed1 + mc_idx_vec(1)*3 + 1  (eirp stream, offset +1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[num_rows,num_cols]=size(super_array_bs_eirp_dist);
num_mc=length(mc_idx_vec);

if num_cols<=1
    all_rand_norm_eirp=zeros(num_rows,num_mc);
    return;
end

rel_min=min(reliability);
rel_max=max(reliability);

%%%%%One rng call, generate all random draws for this chunk at once
rng(rand_seed1+mc_idx_vec(1)*3+1);
all_rand=rand(num_rows,num_mc)*(rel_max-rel_min)+rel_min;  %%%%[num_rows x num_mc]

%%%%%griddedInterpolant: pre-processes spline knots once per row, then
%%%%%evaluates all num_mc query points in one call
all_rand_norm_eirp=NaN(num_rows,num_mc);
for n=1:1:num_rows
    F=griddedInterpolant(reliability(:),super_array_bs_eirp_dist(n,:)','spline');
    all_rand_norm_eirp(n,:)=F(all_rand(n,:));
end

end
