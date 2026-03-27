function results=validate_monte_carlo_super_bs_eirp_dist_rev5_rev8(app,super_array_bs_eirp_dist,reliability,rand_numbers)
%VALIDATE_MONTE_CARLO_SUPER_BS_EIRP_DIST_REV5_REV8
% Helper-level validation: compare rev5 (golden) vs rev8 (fixed fast path).
% Must pass before any end-to-end integration.
%
% Checks:
%   1) Exact shape match of outputs
%   2) Max absolute error across all elements
%   3) Per-element relative error statistics
%   4) Known failure pattern detection (inversion check)
%   5) Endpoint / boundary behavior
%   6) Monotonicity preservation spot-check

fprintf('\n=== HELPER VALIDATION: rev5 vs rev8 ===\n');

% --- Run both ---
out5=monte_carlo_super_bs_eirp_dist_rev5(app,super_array_bs_eirp_dist,reliability,rand_numbers);
out8=monte_carlo_super_bs_eirp_dist_rev8(app,super_array_bs_eirp_dist,reliability,rand_numbers);

% --- Shape check ---
sz5=size(out5);
sz8=size(out8);
shape_ok=isequal(sz5,sz8);
fprintf('Shape rev5: [%s]  rev8: [%s]  match: %s\n', ...
    num2str(sz5),num2str(sz8),yesno(shape_ok));
if ~shape_ok
    error('validate_rev5_rev8:ShapeMismatch','Output shapes differ.');
end

% --- Absolute error ---
abs_err=abs(out8-out5);
max_abs_err=max(abs_err);
mean_abs_err=mean(abs_err);
fprintf('Max  absolute error: %.6e\n',max_abs_err);
fprintf('Mean absolute error: %.6e\n',mean_abs_err);

% --- Relative error (relative to rev5 magnitude, guarded) ---
denom=max(abs(out5),1e-12);
rel_err=abs_err./denom;
max_rel_err=max(rel_err);
mean_rel_err=mean(rel_err);
fprintf('Max  relative error: %.6e\n',max_rel_err);
fprintf('Mean relative error: %.6e\n',mean_rel_err);

% --- Inversion detection (the rev6 failure signature) ---
% If sign(out8 - mean(out8)) is anti-correlated with sign(out5 - mean(out5)),
% we have the same axis-swap bug.
corr_val=corr(out5(:),out8(:));
fprintf('Pearson correlation:  %.8f\n',corr_val);
inversion_detected=corr_val<0.5;
if inversion_detected
    fprintf('*** INVERSION DETECTED: correlation %.4f < 0.5 ***\n',corr_val);
end

% --- Worst-case examples (for manual inspection) ---
[~,worst_idx]=sort(abs_err,'descend');
n_show=min(5,numel(worst_idx));
fprintf('\nWorst-case elements:\n');
fprintf('  %-6s  %-12s  %-12s  %-12s  %-10s\n','idx','rev5','rev8','abs_err','query');
for k=1:n_show
    ii=worst_idx(k);
    fprintf('  %-6d  %12.6f  %12.6f  %12.6e  %10.6f\n', ...
        ii,out5(ii),out8(ii),abs_err(ii),rand_numbers(ii));
end

% --- Endpoint spot-check: query at rel_min and rel_max ---
fprintf('\nEndpoint spot-check:\n');
rel_sorted=sort(reliability(:));
rel_min=rel_sorted(1);
rel_max=rel_sorted(end);
% Test with first row's data at boundaries
rn_lo=rel_min*ones(size(rand_numbers));
rn_hi=rel_max*ones(size(rand_numbers));
out5_lo=monte_carlo_super_bs_eirp_dist_rev5(app,super_array_bs_eirp_dist,reliability,rn_lo);
out8_lo=monte_carlo_super_bs_eirp_dist_rev8(app,super_array_bs_eirp_dist,reliability,rn_lo);
out5_hi=monte_carlo_super_bs_eirp_dist_rev5(app,super_array_bs_eirp_dist,reliability,rn_hi);
out8_hi=monte_carlo_super_bs_eirp_dist_rev8(app,super_array_bs_eirp_dist,reliability,rn_hi);
lo_err=max(abs(out8_lo-out5_lo));
hi_err=max(abs(out8_hi-out5_hi));
fprintf('  At rel_min (%.6f): max abs error = %.6e\n',rel_min,lo_err);
fprintf('  At rel_max (%.6f): max abs error = %.6e\n',rel_max,hi_err);

% --- Pass/fail thresholds ---
% Spline should be numerically identical (same algorithm, same coefficients).
% Allow for floating-point rounding only.
ABS_TOL=1e-10;
REL_TOL=1e-10;
pass_abs=max_abs_err<=ABS_TOL;
pass_rel=max_rel_err<=REL_TOL;
pass_corr=corr_val>0.999;
pass_endpoints=(lo_err<=ABS_TOL) && (hi_err<=ABS_TOL);
overall_pass=pass_abs && pass_rel && pass_corr && pass_endpoints;

fprintf('\nPass/fail summary:\n');
fprintf('  Absolute error <= %.1e: %s\n',ABS_TOL,passfail(pass_abs));
fprintf('  Relative error <= %.1e: %s\n',REL_TOL,passfail(pass_rel));
fprintf('  Correlation    >  0.999:  %s\n',passfail(pass_corr));
fprintf('  Endpoints      <= %.1e: %s\n',ABS_TOL,passfail(pass_endpoints));
fprintf('  OVERALL: %s\n',passfail(overall_pass));

if ~overall_pass
    error('validate_rev5_rev8:Failed', ...
        'Helper validation FAILED. Do NOT integrate rev8 into end-to-end.');
end

% --- Build results struct ---
results=struct();
results.max_abs_err=max_abs_err;
results.mean_abs_err=mean_abs_err;
results.max_rel_err=max_rel_err;
results.mean_rel_err=mean_rel_err;
results.correlation=corr_val;
results.endpoint_lo_err=lo_err;
results.endpoint_hi_err=hi_err;
results.pass=overall_pass;
results.n_elements=numel(out5);

end

function s=yesno(tf)
if tf; s='YES'; else; s='NO'; end
end

function s=passfail(tf)
if tf; s='PASS'; else; s='FAIL'; end
end
