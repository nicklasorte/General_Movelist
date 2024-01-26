function [inner_line,inner_corner1,inner_corner2]=find_dpa_line_overlap(inner_edge,dpa_input)

%%%%Approach #2 for Inner Line, do the same for outer_line
marker1=1;
for i=1:1:length(inner_edge)
    clear idx_find;
    [~,~,idx_find]=intersect(round(inner_edge(i,:),2),round(dpa_input,2),'rows');
    if isempty(idx_find)==0
       inner_idx2(marker1)=i;
       marker1=marker1+1;
    end
end
%%%Remove Zeros from inner_idx2
idx_nonzero=find(inner_idx2>0);
inner_line=inner_edge(min(inner_idx2(idx_nonzero)):max(inner_idx2(idx_nonzero)),:);
inner_corner1=inner_edge(min(inner_idx2(idx_nonzero)),:);
inner_corner2=inner_edge(max(inner_idx2(idx_nonzero)),:);

end