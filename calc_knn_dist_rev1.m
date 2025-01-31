function [knn_dist,max_knn_dist]=calc_knn_dist_rev1(app,base_polygon,list_bs)

%%%%%%%%%%%%%%Calculate the knn ON distance
nnan_base_polygon=base_polygon(~isnan(base_polygon(:,1)),:);
[tf_ml_toolbox]=check_ml_toolbox(app);
if tf_ml_toolbox==1
    [idx_knn]=knnsearch(nnan_base_polygon(:,[1,2]),list_bs(:,[1:2]),'k',1); %%%Find Nearest Neighbor
else
    [idx_knn]=nick_knnsearch(list_bs(:,[1:2]),nnan_base_polygon(:,[1,2]),1); %%%Find Nearest Neighbor
end
base_knn_array=nnan_base_polygon(idx_knn,:);
knn_dist=deg2km(distance(base_knn_array(:,1),base_knn_array(:,2),list_bs(:,1),list_bs(:,2)));%%%%Calculate Distance
knn_dist=round(knn_dist);
max_knn_dist=ceil(max(knn_dist))

end