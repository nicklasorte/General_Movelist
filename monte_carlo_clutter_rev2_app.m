function monte_carlo_clutter_loss = monte_carlo_clutter_rev2_app(app,rand_seed1,mc_iter,reliability_range,clutter_loss)
%MONTE_CARLO_CLUTTER_REV2_APP One Monte Carlo draw of clutter loss vs reliability.
% Output: Mx1 column vector (M = number of TX rows in clutter_loss).
%
% Inputs match your original signature; "app" is unused here but kept for drop-in compatibility.

%#ok<*NASGU> % app retained for compatibility

% ---- Dimensions and axis cleanup
[num_tx, nRel] = size(clutter_loss);

reliability_range = reliability_range(:).';  % force row vector for sorting/indexing
if nRel ~= numel(reliability_range)
    error("clutter_loss has %d columns but reliability_range has %d elements.", ...
        nRel, numel(reliability_range));
end

% Sort reliability and keep columns aligned
[reliability_range, sort_idx] = sort(reliability_range);
clutter_loss = clutter_loss(:, sort_idx);

% De-duplicate reliability values (required for well-defined interpolation)
[reliability_range, ia] = unique(reliability_range, "stable");
clutter_loss = clutter_loss(:, ia);

rel_min = reliability_range(1);
rel_max = reliability_range(end);

% ---- Deterministic case
if rel_min == rel_max
    monte_carlo_clutter_loss = clutter_loss(:,1);   % Mx1
    return
end

% ---- Local RNG (repeatable per iteration; does not touch global stream)
stream = RandStream("twister","Seed",rand_seed1 + mc_iter);  % :contentReference[oaicite:2]{index=2}

% Sample reliabilities uniformly on [rel_min, rel_max]
rq = rel_min + (rel_max - rel_min) * rand(stream, num_tx, 1);  % Mx1
rq = min(max(rq, rel_min), rel_max);                            % clamp

% ---- Interpolation without loops, one query per TX
% Build a 2-D interpolant F(rel, txIndex) -> clutter_loss at that grid point.
% Data must be in ndgrid order: first dimension corresponds to reliability,
% second corresponds to tx index.
tx = (1:num_tx);
F = griddedInterpolant({reliability_range, tx}, clutter_loss.', "linear", "nearest"); % :contentReference[oaicite:3]{index=3}

% Evaluate at scattered points: (rq(i), i)
monte_carlo_clutter_loss = F(rq, (1:num_tx).');   % Mx1

if any(isnan(monte_carlo_clutter_loss))
    error("NaN detected in monte_carlo_clutter_loss.");
end

% Optional: keep your original behavior for Inf
inf_idx = isinf(monte_carlo_clutter_loss);
if any(inf_idx)
    monte_carlo_clutter_loss(inf_idx) = 0;
end

end