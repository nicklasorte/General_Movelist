function [rand_norm_eirp]=monte_carlo_super_bs_eirp_dist_rev3(app,super_array_bs_eirp_dist,rand_seed1,mc_iter,num_tx,reliability)

[num_rows,num_cols]=size(super_array_bs_eirp_dist);

if num_cols>1
    %%%%%%%Generate 1 MC Iteration
    rng(rand_seed1+mc_iter+1);%For Repeatability
    rand_numbers=rand(num_rows,1)*(max(reliability)-min(reliability)+min(reliability)); %Create Random Number within Max/Min or reliability
    rand_norm_eirp=NaN(num_rows,1);
    for n=1:1:num_rows
        rand_norm_eirp(n)=interp1(reliability,super_array_bs_eirp_dist(n,:),rand_numbers(n),'spline');
    end

    % % % % horzcat(reliability,super_array_bs_eirp_dist(n,:)')
    % % % % rand_norm_eirp
    % % % % temp_rand_num

    %
    %          figure;
    % hold on;
    % plot(bs_eirp_dist(:,1),bs_eirp_dist(:,2),':b')
    % plot(rand_numbers,rand_norm_eirp,'ob','LineWidth',2)
    % grid on;
else
    rand_norm_eirp=zeros(num_tx,1);
end

%size(rand_norm_eirp)