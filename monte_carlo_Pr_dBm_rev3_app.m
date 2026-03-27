function [monte_carlo_pr_dBm]=monte_carlo_Pr_dBm_rev3_app(app,reliability_range,cut_temp_Pr_dBm,rand_numbers)
%MONTE_CARLO_PR_DBM_REV3_APP Vectorized RNG-free Monte Carlo PR interpolation.
% rev3 goals:
%   1) preserve rev2 output contract and units exactly;
%   2) replace nearestpoint_app bracket search with discretize for speed;
%   3) vectorize per-TX interpolation loop (proven pattern from clutter_rev5);
%   4) keep RNG-free, call-site-compatible interface.
%
% rand_numbers are precomputed reliabilities (num_tx x 1).

[num_tx,~]=size(cut_temp_Pr_dBm);

% Sort reliability axis and reorder columns to match.
[reliability_range,sort_idx]=sort(reliability_range);
cut_temp_Pr_dBm=cut_temp_Pr_dBm(:,sort_idx);

monte_carlo_pr_dBm=NaN(num_tx,1);
rel_min=min(reliability_range);
rel_max=max(reliability_range);

if rel_min==rel_max
    monte_carlo_pr_dBm=cut_temp_Pr_dBm(:,1);
else
    rand_numbers=min(max(rand_numbers(:),rel_min),rel_max);
    num_rel=length(reliability_range);

    % --- Bracket search via discretize (replaces two nearestpoint_app calls) ---
    % Build bin edges from reliability_range midpoints so discretize gives the
    % "previous" index directly.  For sorted reliability_range of length R,
    % discretize(x, reliability_range) returns the index of the left edge of the
    % bin containing x, which is exactly ind_prev.
    % Edge cases: values exactly at reliability_range(end) go into bin R-1
    % via 'IncludedEdge','right'.
    edges=reliability_range(:).';
    ind_prev=discretize(rand_numbers,edges,'IncludedEdge','right');

    % Handle boundary: discretize returns NaN for values outside edges.
    % After clamping rand_numbers to [rel_min, rel_max], this should only happen
    % at exact-minimum edge with 'right' inclusion. Fix: values at rel_min get bin 1.
    nan_mask_prev=isnan(ind_prev);
    if any(nan_mask_prev)
        ind_prev(nan_mask_prev)=1;
    end

    % ind_next is simply ind_prev + 1, clamped to num_rel.
    ind_next=min(ind_prev+1,num_rel);

    % --- Vectorized interpolation (proven pattern from clutter_rev5) ---
    prev_rel=reliability_range(ind_prev);
    next_rel=reliability_range(ind_next);
    remainder=rand_numbers-prev_rel(:);
    span=next_rel(:)-prev_rel(:);

    % Match rev2 semantics: when span==0, remainder/span -> NaN -> subtract=0.
    ratio=remainder./span;
    ratio(~isfinite(ratio))=0;

    % Gather Pr values at bracket indices using sub2ind.
    row_idx=(1:num_tx).';
    idx_prev=sub2ind(size(cut_temp_Pr_dBm),row_idx,ind_prev);
    idx_next=sub2ind(size(cut_temp_Pr_dBm),row_idx,ind_next);

    prev_Pr=cut_temp_Pr_dBm(idx_prev);
    next_Pr=cut_temp_Pr_dBm(idx_next);

    temp_diff_Pr=prev_Pr-next_Pr;
    subtract_Pr=temp_diff_Pr.*ratio;
    subtract_Pr(~isfinite(subtract_Pr))=0;

    monte_carlo_pr_dBm=prev_Pr-subtract_Pr;
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
