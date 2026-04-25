function persistent_save_figure_rev1(app,fig_handle,file_name) %#ok<INUSL>
%%%%%%%%Save a figure (saveas) with retry on failure.
%%%%%%%%Mirrors the inline saveas/while-retry pattern.

retry_save=1;
while(retry_save==1)
    try
        saveas(fig_handle,char(file_name))
        retry_save=0;
    catch
        retry_save=1;
        pause(1)
    end
end
end
