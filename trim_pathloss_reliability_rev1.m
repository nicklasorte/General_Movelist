function [pathloss]=trim_pathloss_reliability_rev1(app,pathloss,move_list_reliability,reliability,string_prop_model)

%%%%%%%% Cut the reliabilities that we will use for the move list
size(pathloss)
move_list_reliability
reliability
[rel_first_idx]=nearestpoint_app(app,min(move_list_reliability),reliability)
[rel_second_idx]=nearestpoint_app(app,max(move_list_reliability),reliability)
if strcmp(string_prop_model,'TIREM')
    % % % % if TIREM, we wont cut the reliabilites because there are none to cut.
else
    pathloss=pathloss(:,[rel_first_idx:rel_second_idx]);
end
size(pathloss)

end