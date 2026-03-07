function [cell_status]=checkout_cell_status_GPT_rev2(app,checkout_filename,cell_status_filename,sim_folder,folder_names,tf_update_cell_status)

% checkout_cell_status_rev2
% Robust cross-server checkout/update flow for shared cell_status files.
% MATLAB R2024b compatible.

disp_TextArea_PastText(app,'checkout_cell_status_rev2: Entering checkout.')

% Use an atomic directory lock so multiple servers can coordinate safely.
lock_dir=[checkout_filename '_lockdir'];
lock_timeout_s=10*60; % stale lock threshold
poll_s=0.2;

acquire_shared_lock(lock_dir,lock_timeout_s,poll_s,app)
cleanup_lock=onCleanup(@()release_shared_lock(lock_dir,app)); %#ok<NASGU>

%%%%%%%%%%%%%%%%%Load cell_status
cell_status_exist=false;
while true
    try
        cell_status_exist=exist(cell_status_filename,'file')==2;
        break
    catch
        pause(0.5)
    end
end

if cell_status_exist
    retry_load=1;
    while(retry_load==1)
        try
            load(cell_status_filename,'cell_status')
            retry_load=0;
        catch
            retry_load=1;
            pause(0.25)
        end
    end
    disp_TextArea_PastText(app,'checkout_cell_status_rev2: cell_status loaded.')
else
    [num_folders,~]=size(folder_names);
    cell_status=cell(num_folders,2); %%%%Name and 0/1
    cell_status(:,1)=folder_names;
    cell_status(:,2)={0};
    tf_update_cell_status=1;  %%%%%%%If we're creating a new one, we need to save it.
    disp_TextArea_PastText(app,'checkout_cell_status_rev2: Creating NEW cell_status.')
end

%%%%%%%%%%%Update and Save cell_status
if tf_update_cell_status==1
    %%%%%Find the idx
    temp_cell_idx=find(strcmp(cell_status(:,1),sim_folder),1);

    if isempty(temp_cell_idx)
        cell_status=[cell_status; {sim_folder,1}];
    else
        %%%%%%%Update the Cell
        cell_status{temp_cell_idx,2}=1;
    end

    %%%%%Save the Cell
    retry_save=1;
    while(retry_save==1)
        try
            save(cell_status_filename,'cell_status')
            retry_save=0;
        catch
            retry_save=1;
            pause(0.5)
        end
    end
    disp_TextArea_PastText(app,'checkout_cell_status_rev2: cell_status SAVED.')
end

disp_TextArea_PastText(app,'checkout_cell_status_rev2: Exiting checkout.')

end

function acquire_shared_lock(lock_dir,lock_timeout_s,poll_s,app)

while true
    try
        [tf_mkdir,~]=mkdir(lock_dir);
    catch
        tf_mkdir=false;
    end

    if tf_mkdir || exist(lock_dir,'dir')==0
        write_lock_metadata(lock_dir);
        disp_TextArea_PastText(app,'checkout_cell_status_rev2: Lock acquired.')
        return
    end

    if is_stale_lock(lock_dir,lock_timeout_s)
        disp_TextArea_PastText(app,'checkout_cell_status_rev2: Stale lock detected, removing lock.')
        try
            rmdir(lock_dir,'s')
            pause(0.05+0.1*rand)
            continue
        catch
            % Another process may be holding or removing it.
        end
    end

    pause(poll_s+0.1*rand)
end

end

function tf_stale=is_stale_lock(lock_dir,lock_timeout_s)

tf_stale=false;
try
    info_file=fullfile(lock_dir,'lock_info.mat');
    if exist(info_file,'file')==2
        file_info=dir(info_file);
        if ~isempty(file_info)
            age_s=(now-file_info.datenum)*24*3600;
            tf_stale=age_s>lock_timeout_s;
            return
        end
    end

    dir_info=dir(lock_dir);
    if ~isempty(dir_info)
        age_s=(now-dir_info(1).datenum)*24*3600;
        tf_stale=age_s>lock_timeout_s;
    end
catch
    tf_stale=false;
end

end

function write_lock_metadata(lock_dir)

info_file=fullfile(lock_dir,'lock_info.mat');
lock_info=struct();
lock_info.time_utc=char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSSXXX'));
lock_info.host='unknown';
lock_info.pid=-1;

try
    [~,host]=system('hostname');
    lock_info.host=strtrim(host);
catch
end

try
    lock_info.pid=feature('getpid');
catch
end

try
    save(info_file,'lock_info')
catch
    % If metadata save fails, still keep the acquired lock directory.
end

end

function release_shared_lock(lock_dir,app)

if exist(lock_dir,'dir')~=7
    return
end

try
    rmdir(lock_dir,'s')
    disp_TextArea_PastText(app,'checkout_cell_status_rev2: Lock released.')
catch
    disp_TextArea_PastText(app,'checkout_cell_status_rev2: Warning - unable to release lock directory.')
end

end
