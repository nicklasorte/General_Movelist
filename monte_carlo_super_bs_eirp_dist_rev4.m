function [rand_norm_eirp]=monte_carlo_super_bs_eirp_dist_rev4(app,super_array_bs_eirp_dist,rand_seed1,mc_iter,reliability)

[num_rows,num_cols]=size(super_array_bs_eirp_dist);

if num_cols>1
    %%%%%%%Generate 1 MC Iteration
    rng(rand_seed1+mc_iter+1);%For Repeatability
    rel_min=min(reliability);
    rel_max=max(reliability);
    rand_numbers=rand(num_rows,1)*(rel_max-rel_min)+rel_min; %Create random numbers within [rel_min, rel_max]

    %%%%%griddedInterpolant: pre-processes spline knots once per row, then
    %%%%%evaluates all query points efficiently — faster than repeated interp1
    rand_norm_eirp=NaN(num_rows,1);
    for n=1:1:num_rows
        F=griddedInterpolant(reliability(:),super_array_bs_eirp_dist(n,:)','spline');
        rand_norm_eirp(n)=F(rand_numbers(n));
    end
else
    rand_norm_eirp=zeros(num_rows,1);
end


% %size(rand_norm_eirp)


