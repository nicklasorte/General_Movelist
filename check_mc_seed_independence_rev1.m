function [tf_coupled,max_abs_diff]=check_mc_seed_independence_rev1(rand_seed1,num_bs,num_mc_check)
%%%%%%%%check_mc_seed_independence_rev1
%%%%%%%%Standalone. Not part of the production path. Run once from the command
%%%%%%%%line to confirm (or refute) the seed-reuse finding before it is written
%%%%%%%%into the paper.
%%%%%%%%
%%%%%%%%subchunk_agg_check_maxazi_man_azi_rev10 draws, for MC iteration k:
%%%%%%%%    rng(rand_seed1+k)     -> rand_pr_all(:,k)        path-loss reliability
%%%%%%%%    rng(rand_seed1+k+1)   -> rand_eirp_all(:,k)      EIRP percentile
%%%%%%%%    rng(rand_seed1+k+2)   -> rand_clutter_all(:,k)   clutter percentile
%%%%%%%%
%%%%%%%%Because the seeds advance by 1 and the iteration index also advances by
%%%%%%%%1, the EIRP vector at iteration k should be bit-identical to the
%%%%%%%%path-loss vector at iteration k+1, and the clutter vector at iteration k
%%%%%%%%bit-identical to the path-loss vector at iteration k+2.
%%%%%%%%
%%%%%%%%This function reproduces the exact seeding pattern and reports whether
%%%%%%%%that identity holds. tf_coupled==1 means the three "independent"
%%%%%%%%randomized variables in Eq. (2) are one uniform sequence read at three
%%%%%%%%lags, and the MC draws are not an independent sample.
%%%%%%%%
%%%%%%%%The same pattern appears in the move-list path; check it there too.

if ~isscalar(rand_seed1) || rand_seed1<0 || rand_seed1~=floor(rand_seed1)
    error('check_mc_seed_independence_rev1:BadSeed','rand_seed1 must be a non-negative integer.');
end
if ~isscalar(num_bs) || num_bs<1 || num_bs~=floor(num_bs)
    error('check_mc_seed_independence_rev1:BadNumBS','num_bs must be a positive integer.');
end
if ~isscalar(num_mc_check) || num_mc_check<3 || num_mc_check~=floor(num_mc_check)
    error('check_mc_seed_independence_rev1:BadNumMC','num_mc_check must be an integer >= 3.');
end

rand_pr=NaN(num_bs,num_mc_check);
rand_eirp=NaN(num_bs,num_mc_check);
rand_clutter=NaN(num_bs,num_mc_check);

for loop_idx=1:1:num_mc_check
    mc_iter=loop_idx;                       %%%%%chunk indices are contiguous
    rng(rand_seed1+mc_iter);
    rand_pr(:,loop_idx)=rand(num_bs,1);
    rng(rand_seed1+mc_iter+1);
    rand_eirp(:,loop_idx)=rand(num_bs,1);
    rng(rand_seed1+mc_iter+2);
    rand_clutter(:,loop_idx)=rand(num_bs,1);
end

%%%%%%%%EIRP at k vs PR at k+1
d_eirp=max(max(abs(rand_eirp(:,1:end-1)-rand_pr(:,2:end))));
%%%%%%%%Clutter at k vs PR at k+2
d_clut=max(max(abs(rand_clutter(:,1:end-2)-rand_pr(:,3:end))));

max_abs_diff=max([d_eirp,d_clut]);
tf_coupled=(max_abs_diff==0);

fprintf('max |EIRP_k - PR_(k+1)|    = %.3e\n',d_eirp);
fprintf('max |Clutter_k - PR_(k+2)| = %.3e\n',d_clut);
if tf_coupled
    fprintf('RESULT: draws ARE coupled. The three randomized variables are one sequence at lags 0, 1, 2.\n');
else
    fprintf('RESULT: no exact coupling detected at these lags.\n');
end

end