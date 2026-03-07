function all_data_stats_binary = appendSearchStatsIntDist_GPT_rev1(app,all_data_stats_binary,single_search_dist,single_scrap_data)
%appendSearchStatsIntDist  Append/overwrite per-point stats at an integer distance.
%
%   all_data_stats_binary = appendSearchStatsIntDist(app, all_data_stats_binary, single_search_dist, single_scrap_data)
%
% Behavior (integer distances):
%   - If the distance already exists in a cell: overwrite that row.
%   - Else: insert the new row to keep column 1 (distance) in ascending order.
%   - If a cell is not sorted, it is sorted once before insertion (cheap guardrail).
%
% Inputs:
%   all_data_stats_binary  1xN cell; each cell is [Mi x (1+K)] numeric:
%                          col1 = distance (integer-valued), cols 2..end = stats
%   single_search_dist     scalar integer distance to append/overwrite
%   single_scrap_data      [N x K] numeric stats to append for each cell
%
% Output:
%   all_data_stats_binary  updated cell array

    arguments
        app %#ok<INUSA>
        all_data_stats_binary (1,:) cell
        single_search_dist (1,1) double {mustBeFinite}
        single_scrap_data (:,:) double
    end

    % Enforce integer distance (exact equality is then safe)
    if single_search_dist ~= round(single_search_dist)
        error("appendSearchStatsIntDist:NonIntegerDistance", ...
            "single_search_dist must be an integer. Got %g.", single_search_dist);
    end

    nPts = numel(all_data_stats_binary);
    if size(single_scrap_data,1) ~= nPts
        error("appendSearchStatsIntDist:RowMismatch", ...
            "single_scrap_data must have %d rows (one per cell). Got %d.", ...
            nPts, size(single_scrap_data,1));
    end

    for i = 1:nPts
        A = all_data_stats_binary{i};
        newRow = [single_search_dist, single_scrap_data(i,:)];

        % Empty cell fast path
        if isempty(A)
            all_data_stats_binary{i} = newRow;
            continue
        end

        expectedCols = 1 + size(single_scrap_data,2);
        if size(A,2) ~= expectedCols
            error("appendSearchStatsIntDist:ColMismatch", ...
                "Cell %d has %d cols; expected %d (1 distance + %d stats).", ...
                i, size(A,2), expectedCols, size(single_scrap_data,2));
        end

        % --- Added: sort guardrail if distances aren't already ascending ---
        if any(diff(A(:,1)) < 0)
            [~, order] = sort(A(:,1));
            A = A(order,:);
        end

        d = A(:,1);

        % Overwrite if exists
        j = find(d == single_search_dist, 1, "first");
        if ~isempty(j)
            A(j,:) = newRow;
            all_data_stats_binary{i} = A;
            continue
        end

        % Insert to keep sorted order
        k = find(d > single_search_dist, 1, "first");
        if isempty(k)
            all_data_stats_binary{i} = [A; newRow];
        else
            all_data_stats_binary{i} = [A(1:k-1,:); newRow; A(k:end,:)];
        end
    end
end