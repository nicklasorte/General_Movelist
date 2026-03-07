function [on_list_bs,off_idx] = create_on_list_bs_GPT_rev1(app,sim_array_list_bs,union_turn_off_list_data)
%makeKeepOnList  Create the keep-on list by removing turn-off rows.
%
%   [on_list_bs, off_idx] = makeKeepOnList(app, sim_array_list_bs, union_turn_off_list_data)
%
% Inputs:
%   sim_array_list_bs         [N x M] numeric array (e.g., lat/lon per BS)
%   union_turn_off_list_data  [K x M] numeric array of rows to remove (can be empty)
%
% Outputs:
%   on_list_bs  sim_array_list_bs with any rows present in union_turn_off_list_data removed
%   off_idx     indices (into sim_array_list_bs) of removed rows (sorted)
%
% Notes:
%   - Uses intersect(...,'rows') to find rows to remove.
%   - Preserves original ordering of sim_array_list_bs for remaining rows.

    arguments
        app %#ok<INUSA>  % included for App Designer consistency
        sim_array_list_bs (:,:) double
        union_turn_off_list_data (:,:) double = NaN(0, size(sim_array_list_bs,2))
    end

    % Default outputs
    on_list_bs = sim_array_list_bs;
    off_idx = [];

    if isempty(union_turn_off_list_data)
        return
    end

    % Guard: column counts must match for 'rows'
    if size(union_turn_off_list_data,2) ~= size(sim_array_list_bs,2)
        error("makeKeepOnList:SizeMismatch", ...
            "Column mismatch: sim_array_list_bs has %d cols, union_turn_off_list_data has %d cols.", ...
            size(sim_array_list_bs,2), size(union_turn_off_list_data,2));
    end

    % Find rows to turn off
    [~, off_idx] = intersect(sim_array_list_bs, union_turn_off_list_data, "rows");

    off_idx = sort(off_idx);
    on_list_bs(off_idx,:) = [];
end