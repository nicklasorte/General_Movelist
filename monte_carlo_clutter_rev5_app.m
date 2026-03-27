function [monte_carlo_clutter_loss]=monte_carlo_clutter_rev5_app(app,reliability_range,sort_clutter_loss,rand_numbers)
%MONTE_CARLO_CLUTTER_REV5_APP Correctness-first optimized Monte Carlo clutter interpolation.
% rev5 goals:
%   1) preserve rev3 output contract and units exactly;
%   2) reduce per-TX loop overhead with shape-safe vectorized interpolation;
%   3) keep RNG-free, call-site-compatible interface for rev11-based pipelines.

DEBUG_CHECKS=false;

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

    idx_nan_prev=isnan(ind_prev);
    if any(idx_nan_prev)
        ind_prev(idx_nan_prev)=1;
    end

    idx_nan_next=isnan(ind_next);
    if any(idx_nan_next)
        ind_next(idx_nan_next)=length(reliability_range);
    end

    prev_rel=reliability_range(ind_prev);
    next_rel=reliability_range(ind_next);
    remainder=rand_numbers-prev_rel;
    span=next_rel-prev_rel;

    % Match rev3 semantics: when span==0, subtract term becomes NaN and is reset to 0.
    ratio=remainder./span;
    ratio(~isfinite(ratio))=0;

    idx_prev=sub2ind(size(sort_clutter_loss),(1:num_tx)',ind_prev);
    idx_next=sub2ind(size(sort_clutter_loss),(1:num_tx)',ind_next);

    prev_loss=sort_clutter_loss(idx_prev);
    next_loss=sort_clutter_loss(idx_next);

    temp_diff_Pr=prev_loss-next_loss;
    subtract_Pr=temp_diff_Pr.*ratio;
    subtract_Pr(~isfinite(subtract_Pr))=0;

    monte_carlo_clutter_loss=prev_loss-subtract_Pr;
end

if DEBUG_CHECKS
    if ~isequal(size(monte_carlo_clutter_loss),[num_tx,1])
        error('monte_carlo_clutter_rev5_app:ShapeMismatch', ...
            'Expected [%d x 1] clutter output, got [%d x %d].', ...
            num_tx,size(monte_carlo_clutter_loss,1),size(monte_carlo_clutter_loss,2));
    end
end

if any(isnan(monte_carlo_clutter_loss))
    'NaN Error with monte_carlo_pr_dBm'; %#ok<NASGU>
    pause;
end

if any(isinf(monte_carlo_clutter_loss))
    inf_idx=find(isinf(monte_carlo_clutter_loss));
    monte_carlo_clutter_loss(inf_idx)=0;
end

end
