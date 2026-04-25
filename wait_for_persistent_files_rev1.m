function wait_for_persistent_files_rev1(app,file_name_list)
%%%%%%%%Block until every file in file_name_list reports var_exist==2 via
%%%%%%%%persistent_var_exist_with_corruption. Mirrors the tf_file_check_loop
%%%%%%%%pattern in parfor_chunk_movelist and agg_check.
%%%%%%%%
%%%%%%%%file_name_list : cell array of file name strings

if ischar(file_name_list) || isstring(file_name_list)
    file_name_list={char(file_name_list)};
end

tf_file_check_loop=1;
while(tf_file_check_loop==1)
    all_exist=1;
    for k=1:length(file_name_list)
        try
            [var_exist_k]=persistent_var_exist_with_corruption(app,file_name_list{k});
            pause(0.1);
        catch
            var_exist_k=0;
            pause(0.1)
        end
        if var_exist_k~=2
            all_exist=0;
        end
    end
    if all_exist==1
        tf_file_check_loop=0;
    else
        tf_file_check_loop=1;
        pause(10)
    end
end
end
