function [mid]=pre_sort_binary_miti_movelist_rev3_app(app,radar_threshold,binary_sort_mc_dBm,low_idx,miti_idx,rev_array_mitigation)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Function Binary Search
%%%%%For Mitigation, we need to stay in dB
%binary_sort_mc_dBm=sort_temp_mc_dBm;
%%%%%%Convert to Watts, Sum, and Find Aggregate
%%%pow2db(0.1*1000)=20, 0.1 Watts = 20dBm
%%%db2pow(20)/1000=0.1, 20dBm = 0.1 Watts
binary_sort_mc_watts=db2pow(binary_sort_mc_dBm)/1000; %%%%%%To be used for the binary search
mc_agg_dbm=pow2db(sum(binary_sort_mc_watts,"omitnan")*1000);


% 'might need to only apply mitigations from top to bottom, instead of the entire power.'
% 'need to do it in dBm?'
% pause;
% 'Start here keeping it in dBm, instead of Watts'
% pause;

if mc_agg_dbm>radar_threshold %%%Over Threshold, binary search
    hi=length(binary_sort_mc_dBm);
    lo=low_idx;
    %%%%lo=0;
    if hi-lo<=1
        mid=hi; %%%If it is 1, just turn everything off
    else
        while((hi-lo)>1) %%%Binary Search
            mid=ceil((hi+lo)/2);

            %%%Find Aggregate for 0:1:mid turnoff
            temp_mc_pr_dBm=binary_sort_mc_dBm;

            %%%idx_cut=1:1:mid;
            idx_cut=(low_idx+1):1:mid;
            if miti_idx==1 %%%%%%%%%%For the first, we turn off.
                temp_mc_pr_watts=db2pow(temp_mc_pr_dBm)/1000; %%%%%%Convert to Watts
                temp_mc_pr_watts(idx_cut)=NaN(1);
            else
                %miti_idx
                %%%%%%%%%%Find the delta between previous and current Mitigation here
                previous_miti_dB=rev_array_mitigation(miti_idx-1);
                current_miti_dB=rev_array_mitigation(miti_idx);
                delta_miti_dB=previous_miti_dB-current_miti_dB;

                %temp_mc_pr_dBm(idx_cut(1))
                temp_mc_pr_dBm(idx_cut)=temp_mc_pr_dBm(idx_cut)-delta_miti_dB;
                %temp_mc_pr_dBm(idx_cut(1))
                temp_mc_pr_watts=db2pow(temp_mc_pr_dBm)/1000; %%%%%%Convert to Watts
            end
            temp_mc_pr_watts=temp_mc_pr_watts(~isnan(temp_mc_pr_watts));  %%%%%%%%%%%Remove NaN just in case

            %%%%Re-calculate Aggregate Power
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
    %%mid

    %%%%%%%Double check Aggregate
    temp_mc_pr_dBm=binary_sort_mc_dBm;

    idx_cut=(low_idx+1):1:mid;
    if miti_idx==1 %%%%%%%%%%For the first, we turn off.
        temp_mc_pr_watts=db2pow(temp_mc_pr_dBm)/1000; %%%%%%Convert to Watts
        temp_mc_pr_watts(idx_cut)=NaN(1);
    else
        %miti_idx
        %%%%%%%%%%Find the delta between previous and current Mitigation here
        previous_miti_dB=rev_array_mitigation(miti_idx-1);
        current_miti_dB=rev_array_mitigation(miti_idx);
        delta_miti_dB=previous_miti_dB-current_miti_dB;

        %temp_mc_pr_dBm(idx_cut(1))
        temp_mc_pr_dBm(idx_cut)=temp_mc_pr_dBm(idx_cut)-delta_miti_dB;
        %temp_mc_pr_dBm(idx_cut(1))
        temp_mc_pr_watts=db2pow(temp_mc_pr_dBm)/1000; %%%%%%Convert to Watts
    end

    temp_mc_pr_watts=temp_mc_pr_watts(~isnan(temp_mc_pr_watts));  %%%%%%%%%%%Remove NaN just in case
    %%%%%Re-calculate Aggregate Power
    check_mc_agg_dbm=pow2db(sum(temp_mc_pr_watts,"omitnan")*1000);%
    if check_mc_agg_dbm>radar_threshold
        'Binary Search Error'
        check_mc_agg_dbm
        pause;
    end
else
    mid=low_idx;
end

% if mid~=low_idx && miti_idx>1
%     miti_idx
%     mid
%     low_idx
%     'check check_mc_agg_dbm'
%     'Line 1036.'
%     pause;
% end

%%%%%%%%%%%%%%%%%End of binary
%%%%%%%%%%%%%%%%%move list

