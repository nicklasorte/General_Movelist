function cleanup_subchunk_files_rev1(app,num_chunks,file_name_fn)
%%%%%%%%Delete per-chunk intermediate files for chunk indexes 1..num_chunks.
%%%%%%%%file_name_fn is a function handle that takes a chunk index and
%%%%%%%%returns the corresponding file name. Multiple file patterns can be
%%%%%%%%cleaned by passing a cell array of function handles.

if ~iscell(file_name_fn)
    file_name_fn={file_name_fn};
end

for sub_point_idx=1:num_chunks
    for k=1:length(file_name_fn)
        fn=file_name_fn{k};
        file_name_chunk=fn(sub_point_idx);
        persistent_delete_rev1(app,file_name_chunk)
    end
end
end
