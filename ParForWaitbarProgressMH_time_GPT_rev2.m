function ParForWaitbarProgressMH_time_GPT_rev2(h,NbrePts,Msg,start_time) %#ok<INUSD>
%ParForWaitbarProgressMH_time Update waitbar + ETA; signal cancel to workers.

% If waitbar is gone, quit quietly.
if isempty(h) || ~ishghandle(h) || ~isvalid(h)
    return
end

% Default increment if delta missing/invalid.
if nargin < 2 || isempty(delta) || ~isnumeric(delta) || ~isscalar(delta) || ~isfinite(delta)
    delta = 1;
end

S = getappdata(h,'ParForWaitbarState');

% If user pressed Cancel, signal workers (best-effort) and close UI.
if isappdata(h,'CancelRequested') && isequal(getappdata(h,'CancelRequested'),true)
    % Broadcast a cancel token. One send is usually enough; send a few to
    % increase chance all workers see it soon (harmless extra tokens).
    if nargin >= 3 && ~isempty(qCancel)
        for k = 1:8
            send(qCancel,true);  % send to PollableDataQueue :contentReference[oaicite:7]{index=7}
        end
    end
    try, waitbar(1,h,'Canceled.'); catch, end %#ok<CTCH>
    try, delete(h); catch, end %#ok<CTCH>  % recommended with CreateCancelBtn :contentReference[oaicite:8]{index=8}
    return
end

% Update completed steps (clamp).
S.Done = min(S.Done + double(delta), S.Total);
fraction = max(0,min(1,S.Done/S.Total));

% Timing + ETA (avoid divide-by-zero).
elapsedSec = toc(S.T0);
if S.Done > 0
    remainSec = elapsedSec*(S.Total/S.Done - 1);
else
    remainSec = NaN;
end

txt = sprintf('%s  |  Elapsed: %s  -  Remaining: %s', ...
    S.Msg, localFmtDuration(elapsedSec), localFmtDuration(remainSec));

% Update UI.
try
    waitbar(fraction,h,txt);
    set(h,'Name',sprintf('%.0f%%',100*fraction));
catch
    return
end

setappdata(h,'ParForWaitbarState',S);

% Optional: auto-close at completion.
if S.Done >= S.Total
    try, delete(h); catch, end %#ok<CTCH>
end

end

function s = localFmtDuration(sec)
% Format seconds as hh:mm:ss (or dd:hh:mm:ss) using duration.
if ~isfinite(sec), s = "--:--:--"; return, end
d = seconds(max(0,sec));
if sec < 24*3600
    d.Format = "hh:mm:ss";
else
    d.Format = "dd:hh:mm:ss";
end
s = char(string(d));
end