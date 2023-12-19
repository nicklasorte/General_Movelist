function [mid]=pre_sort_binary_movelist_rev2_app(app,radar_threshold,binary_sort_mc_watts)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Binary Search
mc_agg_dbm=pow2db(sum(binary_sort_mc_watts,"omitnan")*1000);



if mc_agg_dbm>radar_threshold %%%Over Threshold, binary search
    hi=length(binary_sort_mc_watts);
    lo=0;
    if hi-lo<=1
        mid=hi; %%%If it is 1, just turn everything off
    else
        while((hi-lo)>1) %%%Binary Search
            mid=ceil((hi+lo)/2);

            %%%Find Aggregate for 0:1:mid turnoff
            temp_mc_pr_watts=binary_sort_mc_watts;
            idx_cut=1:1:mid;
            temp_mc_pr_watts(idx_cut)=NaN(1);
            temp_mc_pr_watts=temp_mc_pr_watts(~isnan(temp_mc_pr_watts));  %%%%%%%%%%%Remove NaN just in case

            %Re-calculate Aggregate Power
            binary_mc_agg_dbm=pow2db(sum(temp_mc_pr_watts,"omitnan")*1000);

            %horzcat(binary_mc_agg_dbm,mid)
            if binary_mc_agg_dbm<radar_threshold
                hi=mid;
            else
                lo=mid;
            end
        end
        mid=hi;
    end

    %%%%%%%Double check
    %%%Find Aggregate for 0:1:mid turnoff
    temp_mc_pr_watts=binary_sort_mc_watts;
    idx_cut=1:1:mid;
    temp_mc_pr_watts(idx_cut,:)=NaN(1);
    temp_mc_pr_watts=temp_mc_pr_watts(~isnan(temp_mc_pr_watts));  %%%%%%%%%%%Remove NaN just in case

    %Re-calculate Aggregate Power
    check_mc_agg_dbm=pow2db(sum(temp_mc_pr_watts,"omitnan")*1000);
    if check_mc_agg_dbm>radar_threshold
        'Binary Search Error'
        check_mc_agg_dbm
        pause;
    end
else
    %%%Move List is 0
    mid=0;
end

end