function [rand_norm_eirp]=monte_carlo_bs_eirp_dist_rev1(app,bs_eirp_dist,rand_seed1,mc_iter,num_tx)

[num_rows,~]=size(bs_eirp_dist)

if num_rows>1
            %%%%%%%Generate 1 MC Iteration
            rng(rand_seed1+mc_iter+1);%For Repeatability
            rand_numbers=rand(num_tx,1)*(max(bs_eirp_dist(:,1))-min(bs_eirp_dist(:,1)))+min(bs_eirp_dist(:,1)); %Create Random Number within Max/Min or reliability
            rand_norm_eirp=interp1(bs_eirp_dist(:,1),bs_eirp_dist(:,2),rand_numbers,'spline');
            %horzcat(rand_numbers,rand_norm_eirp)
            % 
            %          figure;
            % hold on;
            % plot(bs_eirp_dist(:,1),bs_eirp_dist(:,2),':b')
            % plot(rand_numbers,rand_norm_eirp,'ob','LineWidth',2)
            % grid on;
else
    rand_norm_eirp=zeros(num_tx,1);
end


end