function [workers,parallel_flag]=check_parallel_toolbox(app,parallel_flag)

if parallel_flag==1
    if isdeployed==1
        tf_parallel=1;
    else
        toolbox_pull = ver;
        tf_parallel=any(strcmp(cellstr(char(toolbox_pull.Name)), 'Parallel Computing Toolbox'));
    end
else
    tf_parallel=0;
end

if tf_parallel==1 && parallel_flag==1
    %%%%%%%%%Find the number of cores
    max_cores=feature('numcores');

    %%%%%Find the memory
    [userview,systemview]=memory;
    cell_memory= struct2cell(systemview.PhysicalMemory);
    total_bytes=cell_memory{2};
    total_ram=floor(total_bytes/(1.06e+9));  %%%%Really: 1.074e+9
    ram_workers=floor(total_ram/2);
    workers=min([ram_workers,max_cores]);
    %%%%%Recommend something about total min([RAM/2GB or max_cores])
else
    parallel_flag=0;
    workers=1;
end

end