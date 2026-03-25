function [monte_carlo_pr_dBm]=monte_carlo_Pr_dBm_rev2_app(app,reliability_range,cut_temp_Pr_dBm,rand_numbers)
%MONTE_CARLO_PR_DBM_REV2_APP RNG-free Monte Carlo PR interpolation.
% rand_numbers are precomputed reliabilities (num_tx x 1).

[num_tx,~]=size(cut_temp_Pr_dBm);

[reliability_range,sort_idx]=sort(reliability_range);
cut_temp_Pr_dBm=cut_temp_Pr_dBm(:,sort_idx);

monte_carlo_pr_dBm=NaN(num_tx,1);
rel_min=min(reliability_range);
rel_max=max(reliability_range);

if rel_min==rel_max
    monte_carlo_pr_dBm=cut_temp_Pr_dBm(:,1);
else
    rand_numbers=min(max(rand_numbers(:),rel_min),rel_max);

    [ind_prev]=nearestpoint_app(app,rand_numbers,reliability_range,'previous');
    [ind_next]=nearestpoint_app(app,rand_numbers,reliability_range,'next');

    idx_nan_prev=find(isnan(ind_prev)==1);
    if ~isempty(idx_nan_prev)
        ind_prev(idx_nan_prev)=1;
    end

    idx_nan_next=find(isnan(ind_next)==1);
    if ~isempty(idx_nan_next)
        ind_next(idx_nan_next)=length(reliability_range);
    end

    remainder=rand_numbers-reliability_range(ind_prev);
    span=reliability_range(ind_next)-reliability_range(ind_prev);

    for tx_idx=1:1:num_tx
        temp_diff_Pr=cut_temp_Pr_dBm(tx_idx,ind_prev(tx_idx))-cut_temp_Pr_dBm(tx_idx,ind_next(tx_idx));
        subtract_Pr=(temp_diff_Pr.*(remainder(tx_idx)./span(tx_idx)));
        if isnan(subtract_Pr)
            subtract_Pr=0;
        end
        monte_carlo_pr_dBm(tx_idx)=cut_temp_Pr_dBm(tx_idx,ind_prev(tx_idx))-subtract_Pr;
    end
end

if any(monte_carlo_pr_dBm<cut_temp_Pr_dBm(:,end))
    horzcat(monte_carlo_pr_dBm,cut_temp_Pr_dBm(:,1),cut_temp_Pr_dBm(:,end),monte_carlo_pr_dBm<cut_temp_Pr_dBm(:,end)); %#ok<NASGU>
    'Error: MC too small'; %#ok<NASGU>
    pause;
end

if any(monte_carlo_pr_dBm>cut_temp_Pr_dBm(:,1))
    horzcat(monte_carlo_pr_dBm,cut_temp_Pr_dBm(:,1),cut_temp_Pr_dBm(:,end),monte_carlo_pr_dBm>cut_temp_Pr_dBm(:,1)); %#ok<NASGU>
    'Error: MC too large'; %#ok<NASGU>
    pause;
end

if any(isnan(monte_carlo_pr_dBm))
    'NaN Error with monte_carlo_pr_dBm'; %#ok<NASGU>
    pause;
end

if any(monte_carlo_pr_dBm==0)
    'Zero Error with monte_carlo_pr_dBm'; %#ok<NASGU>
    pause;
end

if any(isinf(monte_carlo_pr_dBm))
    inf_idx=find(isinf(monte_carlo_pr_dBm));
    monte_carlo_pr_dBm(inf_idx)=-1;
end

end
