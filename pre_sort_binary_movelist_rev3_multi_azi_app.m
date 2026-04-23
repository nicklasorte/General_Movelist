function [mid]=pre_sort_binary_movelist_rev3_multi_azi_app(app,radar_threshold,binary_sort_mc_watts)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Binary Search
mc_agg_dbm=pow2db(sum(binary_sort_mc_watts,"omitnan")*1000);
%%%size(mc_agg_dbm)
max_mc_agg_dbm=max(mc_agg_dbm); %%%%%%%Since we have multiple azimuths, max across azimuths


if max_mc_agg_dbm>radar_threshold %%%Over Threshold, binary search
    [hi,~]=size(binary_sort_mc_watts);
    lo=0;
    if hi-lo<=1
        mid=hi; %%%If it is 1, just turn everything off
    else
        while((hi-lo)>1) %%%Binary Search
            mid=ceil((hi+lo)/2);
            %horzcat(lo,mid,hi)

            %%%Find Aggregate for 0:1:mid turnoff
            temp_mc_pr_watts=binary_sort_mc_watts;
            idx_cut=1:1:mid;
            %size(temp_mc_pr_watts)
            temp_mc_pr_watts(idx_cut,:)=NaN(1);  %%%%%%%%%%Across Multiple Azimuths
            %size(temp_mc_pr_watts)

            temp_mc_pr_watts=temp_mc_pr_watts(~isnan(temp_mc_pr_watts(:,1)),:);  %%%%%%%%%%%Remove NaN just in case
            %size(temp_mc_pr_watts)

            %Re-calculate Aggregate Power
            binary_mc_agg_dbm=pow2db(sum(temp_mc_pr_watts,"omitnan")*1000);
            max_bin_mc_agg_dbm=max(binary_mc_agg_dbm); %%%%%%%%%Since we have multiple Azimuth

            %size(binary_mc_agg_dbm)
            %max_bin_mc_agg_dbm

            % % % % % 'Single and multiple azimuths work'
            % % % % % 'check size'
            % % % % % pause;

            %horzcat(binary_mc_agg_dbm,mid)
            if max_bin_mc_agg_dbm<radar_threshold
                hi=mid;
            else
                lo=mid;
            end
        end
        mid=hi;
    end
    %horzcat(lo,mid,hi)


    %%%%%%%Double check
    %%%Find Aggregate for 0:1:mid turnoff
    temp_mc_pr_watts=binary_sort_mc_watts;
    idx_cut=1:1:mid;
    temp_mc_pr_watts(idx_cut,:)=NaN(1); %%%%%%%%%%Across Multiple Azimuths
    temp_mc_pr_watts=temp_mc_pr_watts(~isnan(temp_mc_pr_watts(:,1)),:);  %%%%%%%%%%%Remove NaN just in case


    %Re-calculate Aggregate Power
    check_mc_agg_dbm=pow2db(sum(temp_mc_pr_watts,"omitnan")*1000);
    max_check_mc_agg_dbm=max(check_mc_agg_dbm); %%%%%%%%%Since we have multiple Azimuth

    if max_check_mc_agg_dbm>radar_threshold
        'Binary Search Error'
        check_mc_agg_dbm
        max_check_mc_agg_dbm
        radar_threshold
        pause;
    end
else
    %%%Move List is 0
    mid=0;
end
