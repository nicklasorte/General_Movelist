function [monte_carlo_clutter_loss]=monte_carlo_clutter_rev4_app(app,reliability_range,sort_clutter_loss,rand_numbers)
%MONTE_CARLO_CLUTTER_REV4_APP RNG-free Monte Carlo clutter interpolation.
% Focused rev4 pass: reduce per-call overhead in rev3 by vectorizing the
% per-TX interpolation path while preserving units and nearestpoint semantics.

[num_tx,~]=size(sort_clutter_loss);

[reliability_range,sort_idx]=sort(reliability_range);
sort_clutter_loss=sort_clutter_loss(:,sort_idx);

monte_carlo_clutter_loss=NaN(num_tx,1);
rel_min=min(reliability_range);
rel_max=max(reliability_range);

if rel_min==rel_max
    monte_carlo_clutter_loss=sort_clutter_loss(:,1);
else
    rand_numbers=rand_numbers(:);
    rand_numbers=min(max(rand_numbers,rel_min),rel_max);

    ind_prev=nearestpoint_app(app,rand_numbers,reliability_range,'previous');
    ind_next=nearestpoint_app(app,rand_numbers,reliability_range,'next');

    ind_prev(isnan(ind_prev))=1;
    ind_next(isnan(ind_next))=length(reliability_range);

    row_idx=(1:num_tx)';
    num_rel=length(reliability_range);
    lin_prev=sub2ind([num_tx,num_rel],row_idx,ind_prev);
    lin_next=sub2ind([num_tx,num_rel],row_idx,ind_next);

    y_prev=sort_clutter_loss(lin_prev);
    y_next=sort_clutter_loss(lin_next);

    rel_prev=reliability_range(ind_prev);
    rel_next=reliability_range(ind_next);
    span=rel_next-rel_prev;
    remainder=rand_numbers-rel_prev;

    weight=remainder./span;
    weight(~isfinite(weight))=0;

    monte_carlo_clutter_loss=y_prev-((y_prev-y_next).*weight);
end

if any(isnan(monte_carlo_clutter_loss))
    'NaN Error with monte_carlo_pr_dBm'; %#ok<NASGU>
    pause;
end

if any(isinf(monte_carlo_clutter_loss))
    inf_idx=isinf(monte_carlo_clutter_loss);
    monte_carlo_clutter_loss(inf_idx)=0;
end

end
