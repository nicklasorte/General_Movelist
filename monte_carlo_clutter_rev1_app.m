function [monte_carlo_clutter_loss]=monte_carlo_clutter_rev1_app(app,rand_seed1,mc_iter,reliability_range,sort_clutter_loss)

%size(cut_temp_Pr_dBm)

[num_tx,~]=size(sort_clutter_loss);

%%%%%%Make sure reliability order matches interpolation columns
[reliability_range,sort_idx]=sort(reliability_range);
sort_clutter_loss=sort_clutter_loss(:,sort_idx);

%%%%%Preallocate
monte_carlo_clutter_loss=NaN(num_tx,1);
rel_min=min(reliability_range);
rel_max=max(reliability_range);

if rel_min==rel_max
    %%%%%Deterministic case, such as reliability=50
    monte_carlo_clutter_loss=sort_clutter_loss(:,1);
else
    %%%%%%%Generate 1 MC Iteration
    rng(rand_seed1+mc_iter+2);%For Repeatability
    rand_numbers=rand(num_tx,1)*(rel_max-rel_min)+rel_min; %Create random numbers within [rel_min, rel_max]
    rand_numbers=min(max(rand_numbers,rel_min),rel_max);

    [ind_prev]=nearestpoint_app(app,rand_numbers,reliability_range,'previous');  %%%Find the previous and next reliability
    [ind_next]=nearestpoint_app(app,rand_numbers,reliability_range,'next');

    %%%Check for NaN in ind_prev/ind_next
    idx_nan_prev=find(isnan(ind_prev)==1);
    if ~isempty(idx_nan_prev)
        ind_prev(idx_nan_prev)=1;
    end

    idx_nan_next=find(isnan(ind_next)==1);
    if ~isempty(idx_nan_next)
        ind_next(idx_nan_next)=length(reliability_range);
    end

    %%%%Interpolate
    remainder=rand_numbers-reliability_range(ind_prev);
    span=reliability_range(ind_next)-reliability_range(ind_prev);

    for tx_idx=1:1:num_tx
        temp_diff_Pr=sort_clutter_loss(tx_idx,ind_prev(tx_idx))-sort_clutter_loss(tx_idx,ind_next(tx_idx));
        subtract_Pr=(temp_diff_Pr.*(remainder(tx_idx)./span(tx_idx)));
        if isnan(subtract_Pr)
            subtract_Pr=0;
        end
        monte_carlo_clutter_loss(tx_idx)=sort_clutter_loss(tx_idx,ind_prev(tx_idx))-subtract_Pr;
    end
end


% if any(monte_carlo_clutter_loss<=clutter_loss(:,end))
%     horzcat(monte_carlo_clutter_loss,clutter_loss(:,1),clutter_loss(:,end),monte_carlo_clutter_loss<clutter_loss(:,end))
%     'Error: MC too small'
%     pause;
% end
% 
% 
% if any(monte_carlo_clutter_loss>=clutter_loss(:,1))
%     horzcat(monte_carlo_clutter_loss,clutter_loss(:,1),clutter_loss(:,end),monte_carlo_clutter_loss>clutter_loss(:,1))
%     'Error: MC too large'
%     pause;
% end


if any(isnan(monte_carlo_clutter_loss))
    'NaN Error with monte_carlo_pr_dBm'
    pause;
end


if any(isinf(monte_carlo_clutter_loss))
    inf_idx=find(isinf(monte_carlo_clutter_loss));
    monte_carlo_clutter_loss(inf_idx)=0;
    % 'Infinity Error with monte_carlo_pr_dBm'
    % pause;
end

end