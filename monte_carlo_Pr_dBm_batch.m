function [all_mc_pr_dBm]=monte_carlo_Pr_dBm_batch(app,rand_seed1,mc_idx_vec,reliability_range,cut_temp_Pr_dBm)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Batch version of monte_carlo_Pr_dBm_rev1_app.
% Returns [num_tx x num_mc] instead of [num_tx x 1].
%
% One rng() call per chunk rather than one per mc_iter.
% griddedInterpolant pre-processes knots once per TX row, faster than
% repeated nearestpoint_app + manual lerp on large matrices.
% Seed: rand_seed1 + mc_idx_vec(1)*3  (Pr stream, offset 0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[num_tx,~]=size(cut_temp_Pr_dBm);
num_mc=length(mc_idx_vec);

[reliability_range,sort_idx]=sort(reliability_range);
cut_temp_Pr_dBm=cut_temp_Pr_dBm(:,sort_idx);

rel_min=min(reliability_range);
rel_max=max(reliability_range);

if rel_min==rel_max
    %%%%%Deterministic case
    all_mc_pr_dBm=repmat(cut_temp_Pr_dBm(:,1),1,num_mc);
    return;
end

%%%%%One rng call, generate all random draws for this chunk at once
rng(rand_seed1+mc_idx_vec(1)*3);
all_rand=rand(num_tx,num_mc)*(rel_max-rel_min)+rel_min;  %%%%[num_tx x num_mc]
all_rand=min(max(all_rand,rel_min),rel_max);

%%%%%griddedInterpolant: pre-processes knots once per row, then evaluates
%%%%%all num_mc query points efficiently
all_mc_pr_dBm=NaN(num_tx,num_mc);
for tx=1:1:num_tx
    F=griddedInterpolant(reliability_range(:),cut_temp_Pr_dBm(tx,:)','linear');
    all_mc_pr_dBm(tx,:)=F(all_rand(tx,:));
end

%%%%%Boundary checks
lower_bound=cut_temp_Pr_dBm(:,end);
upper_bound=cut_temp_Pr_dBm(:,1);
all_mc_pr_dBm=max(all_mc_pr_dBm,lower_bound);
all_mc_pr_dBm=min(all_mc_pr_dBm,upper_bound);
all_mc_pr_dBm(isinf(all_mc_pr_dBm))=-1;

end
