function [sort_monte_carlo_pr_dBm_all]=vector_mc_seed_pr_eirp_clutter_rev1(app,move_list_reliability,sort_full_Pr_dBm,super_array_bs_eirp_dist,clutter_loss,sub_mc_idx,rand_seed1)
% -------------------------------------------------------------------------
% STEP 1: Deterministic MC random precompute (seed identity preserved)
% rand_*_all dimensions: [num_bs x num_mc_idx]
% -------------------------------------------------------------------------

num_mc_idx=length(sub_mc_idx);

rel_min=min(move_list_reliability);
rel_max=max(move_list_reliability);
[num_bs,~]=size(sort_full_Pr_dBm);

if rel_min==rel_max
    rand_pr_all=repmat(rel_min,num_bs,num_mc_idx);
    rand_eirp_all=rand_pr_all;
    rand_clutter_all=rand_pr_all;
else
    rand_pr_all=NaN(num_bs,num_mc_idx);
    rand_eirp_all=NaN(num_bs,num_mc_idx);
    rand_clutter_all=NaN(num_bs,num_mc_idx);

    for loop_idx=1:1:num_mc_idx
        mc_iter=sub_mc_idx(loop_idx);

        rng(rand_seed1+mc_iter); % PR draw identity
        rand_pr_all(:,loop_idx)=rand(num_bs,1)*(rel_max-rel_min)+rel_min;

        rng(rand_seed1+mc_iter+1); % EIRP draw identity
        rand_eirp_all(:,loop_idx)=rand(num_bs,1)*(rel_max-rel_min)+rel_min;

        rng(rand_seed1+mc_iter+2); % Clutter draw identity
        rand_clutter_all(:,loop_idx)=rand(num_bs,1)*(rel_max-rel_min)+rel_min;
    end
end


% -------------------------------------------------------------------------
% STEP 3/4: Compute MC terms with RNG-free rev helpers.
% -------------------------------------------------------------------------
sort_monte_carlo_pr_dBm_all=NaN(num_bs,num_mc_idx);
for loop_idx=1:1:num_mc_idx
    pre_sort_monte_carlo_pr_dBm=monte_carlo_Pr_dBm_rev2_app(app,move_list_reliability,sort_full_Pr_dBm,rand_pr_all(:,loop_idx));
    rand_norm_eirp=monte_carlo_super_bs_eirp_dist_rev5(app,super_array_bs_eirp_dist,move_list_reliability,rand_eirp_all(:,loop_idx));
    monte_carlo_clutter_loss=monte_carlo_clutter_rev3_app(app,move_list_reliability,clutter_loss,rand_clutter_all(:,loop_idx));
    sort_monte_carlo_pr_dBm_all(:,loop_idx)=pre_sort_monte_carlo_pr_dBm+rand_norm_eirp-monte_carlo_clutter_loss;
end
