function [pathloss,clutter_loss]=load_pathloss_clutter_cut_rel_rev1(app,point_idx,sim_number,data_label1,string_prop_model,reliability,target_reliability)
%%%%%%%%Load pathloss + clutter for a protection point and cut to the
%%%%%%%%target reliability range. Also runs fix_inf_pathloss_rev1.
%%%%%%%%
%%%%%%%%Inputs:
%%%%%%%%  target_reliability : vector of reliabilities to keep (min..max used)
%%%%%%%%
%%%%%%%%TIREM is treated as having no reliabilities to cut, matching the
%%%%%%%%existing behavior in agg_check / parfor_chunk_movelist.

file_name_pathloss=strcat(string_prop_model,'_pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
[pathloss]=persistent_load_var_rev1(app,file_name_pathloss,'pathloss');

file_name_clutter=strcat('P2108_clutter_loss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
[clutter_loss]=persistent_load_var_rev1(app,file_name_clutter,'clutter_loss');

[rel_first_idx]=nearestpoint_app(app,min(target_reliability),reliability);
[rel_second_idx]=nearestpoint_app(app,max(target_reliability),reliability);

if strcmp(string_prop_model,'TIREM')
    %%%%%%%%TIREM has no reliabilities to cut.
else
    pathloss=pathloss(:,[rel_first_idx:rel_second_idx]);
end
[pathloss]=fix_inf_pathloss_rev1(app,pathloss);

clutter_loss=clutter_loss(:,[rel_first_idx:rel_second_idx]);
end
