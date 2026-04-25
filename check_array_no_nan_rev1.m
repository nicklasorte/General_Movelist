function check_array_no_nan_rev1(app,array_in,var_label,context_label)
%%%%%%%%Pause execution if any NaN is found in array_in. Mirrors the
%%%%%%%%inline NaN sanity-check blocks in the parfor_chunk / agg_check
%%%%%%%%functions.
%%%%%%%%
%%%%%%%%var_label     : string name of the variable being checked
%%%%%%%%context_label : string identifying the calling context (file/line)

if any(isnan(array_in(:)))
    find(isnan(array_in)) %#ok<NOPRT>
    disp_progress(app,strcat('Error: PAUSE: ',context_label,': NaN error on ',var_label))
    pause;
end
end
