function [temp_max_second_dbm]=turn_off_agg_rev1(app,temp_Pr_watts_azi,turn_off_idx)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%This copy is
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%what is
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%killing us
%%%%temp_search_watts_azi=temp_Pr_watts_azi;

temp_Pr_watts_azi(turn_off_idx,:)=0; %Index to set power to 0 watts

%%%%Recalculate Aggregate
temp_max_second_dbm=max(pow2db(sum(temp_Pr_watts_azi,"omitnan")*1000));

end