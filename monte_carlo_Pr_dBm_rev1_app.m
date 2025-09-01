function [monte_carlo_pr_dBm]=monte_carlo_Pr_dBm_rev1_app(app,rand_seed1,mc_iter,reliability_range,cut_temp_Pr_dBm)

%size(cut_temp_Pr_dBm)

[num_tx,~]=size(cut_temp_Pr_dBm);
%%%%%%%Generate 1 MC Iteration
rng(rand_seed1+mc_iter);%For Repeatability
rand_numbers=rand(num_tx,1)*(max(reliability_range)-min(reliability_range))+min(reliability_range); %Create Random Number within Max/Min or reliability

[ind_prev]=nearestpoint_app(app,rand_numbers,reliability_range,'previous');  %%%Find the previous and next reliability
[ind_next]=nearestpoint_app(app,rand_numbers,reliability_range,'next');

%%%Check for NaN in ind_prev
if isempty(find(isnan(ind_prev),1))==0
    idx_nan=find(isnan(ind_prev)==1);
    ind_prev(idx_nan)=1;
end

%%%%Intrep
remainder=rand_numbers-reliability_range(ind_prev);
span=reliability_range(ind_next)-reliability_range(ind_prev);

%%%%%Preallocate
monte_carlo_pr_dBm=NaN(num_tx,1);
for tx_idx=1:1:num_tx
    temp_diff_Pr=cut_temp_Pr_dBm(tx_idx,ind_prev(tx_idx))-cut_temp_Pr_dBm(tx_idx,ind_next(tx_idx));
    subtract_Pr=(temp_diff_Pr.*(remainder(tx_idx)./span(tx_idx)));
    if isnan(subtract_Pr)
        subtract_Pr=0;
    end
    monte_carlo_pr_dBm(tx_idx)=cut_temp_Pr_dBm(tx_idx,ind_prev(tx_idx))-subtract_Pr;
end

% % all(cut_temp_Pr_dBm==monte_carlo_pr_dBm) %%%%%%%%%Just for 50%
% % horzcat(cut_temp_Pr_dBm(1:10),monte_carlo_pr_dBm(1:10))
% % 
if any(monte_carlo_pr_dBm<cut_temp_Pr_dBm(:,end))
    horzcat(monte_carlo_pr_dBm,cut_temp_Pr_dBm(:,1),cut_temp_Pr_dBm(:,end),monte_carlo_pr_dBm<cut_temp_Pr_dBm(:,end))
    'Error: MC too small'
    pause;
end


if any(monte_carlo_pr_dBm>cut_temp_Pr_dBm(:,1))
    horzcat(monte_carlo_pr_dBm,cut_temp_Pr_dBm(:,1),cut_temp_Pr_dBm(:,end),monte_carlo_pr_dBm>cut_temp_Pr_dBm(:,1))
    'Error: MC too large'
    pause;
end


if any(isnan(monte_carlo_pr_dBm))
    'NaN Error with monte_carlo_pr_dBm'
    pause;
end

if any(monte_carlo_pr_dBm==0)
    'Zero Error with monte_carlo_pr_dBm'
    pause;
end


if any(isinf(monte_carlo_pr_dBm))
    inf_idx=find(isinf(monte_carlo_pr_dBm));
    monte_carlo_pr_dBm(inf_idx)=-1;
    % 'Infinity Error with monte_carlo_pr_dBm'
    % pause;
end

end