function [move_list_reliability]=trim_ml_rel_tirem_rev1(app,string_prop_model,move_list_reliability)

if strcmp(string_prop_model,'TIREM')
    if length(move_list_reliability)>1
        %%%%%%%%%TIREM only does single "reliability"
        %%%%%This will make it so we aren't doing duplicate
        %%%%%calculations and thinking that we are doing a
        %%%%%calculation that really isn't being done.
        move_list_reliability=50;
    end
    if move_list_reliability~=50
        %%%%%TIREM only does "50", can't do 10% or 1%, etc.
        move_list_reliability=50;
    end
end
end