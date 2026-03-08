function [all_clutter_loss]=monte_carlo_clutter_batch(app,rand_seed1,mc_idx_vec,reliability_range,sort_clutter_loss)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Batch version of monte_carlo_clutter_rev1_app.
% Returns [num_tx x num_mc] instead of [num_tx x 1].
%
% One rng() call per chunk rather than one per mc_iter.
% griddedInterpolant pre-processes knots once per TX row, faster than
% repeated nearestpoint_app + manual lerp on large matrices.
% Seed: rand_seed1 + mc_idx_vec(1)*3 + 2  (clutter stream, offset +2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[num_tx,~]=size(sort_clutter_loss);
num_mc=length(mc_idx_vec);

[reliability_range,sort_idx]=sort(reliability_range);
sort_clutter_loss=sort_clutter_loss(:,sort_idx);

rel_min=min(reliability_range);
rel_max=max(reliability_range);

if rel_min==rel_max
    %%%%%Deterministic case
    all_clutter_loss=repmat(sort_clutter_loss(:,1),1,num_mc);
    return;
end

%%%%%One rng call, generate all random draws for this chunk at once
rng(rand_seed1+mc_idx_vec(1)*3+2);
all_rand=rand(num_tx,num_mc)*(rel_max-rel_min)+rel_min;  %%%%[num_tx x num_mc]
all_rand=min(max(all_rand,rel_min),rel_max);

%%%%%griddedInterpolant: pre-processes knots once per row, then evaluates
%%%%%all num_mc query points efficiently
all_clutter_loss=NaN(num_tx,num_mc);
for tx=1:1:num_tx
    F=griddedInterpolant(reliability_range(:),sort_clutter_loss(tx,:)','linear');
    all_clutter_loss(tx,:)=F(all_rand(tx,:));
end

%%%%%Boundary check
all_clutter_loss(isinf(all_clutter_loss))=0;

end
