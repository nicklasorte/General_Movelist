function [pathloss,rel_first_idx,rel_second_idx]=cut_pathloss_rels_rev1(app,move_list_reliability,reliability,string_prop_model,pathloss)


if isempty(move_list_reliability) || any(isnan(move_list_reliability))
    'Error on move_list_reliability'
    move_list_reliability
    pause;
end

if isempty(reliability) || any(isnan(reliability))
    'Error on reliability'
    reliability
    pause;
end

if isempty(pathloss) %|| any(any(isnan(pathloss)))
    pathloss
    'Error on pathloss'
    pause;
end

if isempty(string_prop_model)
    'Error on string_prop_model'
    pause;
end
        %%%%%%%% Cut the reliabilities that we will use for the move list
        [rel_first_idx]=nearestpoint_app(app,min(move_list_reliability),reliability);
        [rel_second_idx]=nearestpoint_app(app,max(move_list_reliability),reliability);
        if strcmp(string_prop_model,'TIREM')
            % % % % if TIREM, we wont cut the reliabilites because there are none to cut.
        else
            pathloss=pathloss(:,[rel_first_idx:rel_second_idx]);
        end
        [pathloss]=fix_inf_pathloss_rev1(app,pathloss);

        if isempty(rel_first_idx) || isnan(rel_first_idx)
            'Error on rel_first_idx'
            pause;
        end

        if isempty(rel_second_idx) || isnan(rel_second_idx)
            'Error on rel_second_idx'
            rel_second_idx
            pause;
        end
