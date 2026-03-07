function union_turn_off_list_data=build_union_turn_off_list(app,cell_move_list_turn_off_data)
valid_move_lists=cell_move_list_turn_off_data(~cellfun(@isempty,cell_move_list_turn_off_data));
if isempty(valid_move_lists)
    union_turn_off_list_data=[];
    return;
end

union_turn_off_list_data=unique(vertcat(valid_move_lists{:}),'rows');
if ~isempty(union_turn_off_list_data)
    union_turn_off_list_data=union_turn_off_list_data(~isnan(union_turn_off_list_data(:,1)),:);
end
end
