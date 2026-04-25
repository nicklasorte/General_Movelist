function cleanup_parfor_waitbar_rev1(hWaitbar,hWaitbarMsgQueue)
%%%%%%%%Best-effort cleanup of the parfor waitbar pair created via
%%%%%%%%ParForWaitbarCreateMH_time. Wrapped in try/catch to match the
%%%%%%%%inline pattern used by callers.
try
    delete(hWaitbarMsgQueue);
    close(hWaitbar);
catch
end
end
