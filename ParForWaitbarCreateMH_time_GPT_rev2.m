function [hWaitbar, q] = ParForWaitbarCreateMH_time_GPT_rev2(Msg, NbrePts)
%ParForWaitbarCreateMH_time_GPT_rev2  Waitbar for PARFOR with ETA + Cancel.
%
%   [h, q] = ParForWaitbarCreateMH_time_GPT_rev2(Msg, NbrePts)
%
%   q.Progress : parallel.pool.DataQueue (workers -> client)
%   q.Cancel   : parallel.pool.PollableDataQueue (client  -> workers)
%
%   In parfor, do:
%       if ParForWaitbarShouldCancel(q.Cancel), return; end
%       send(q.Progress, 1);

arguments
    % REQUIRED first (no default)
    Msg     (1,1) string
    NbrePts (1,1) double {mustBeFinite, mustBePositive, mustBeInteger}
end

% Client-side waitbar with Cancel button
hWaitbar = waitbar(0, char(Msg), ...
    'Name', '0%', ...
    'CreateCancelBtn', 'setappdata(gcbf,''CancelRequested'',true);');
setappdata(hWaitbar, 'CancelRequested', false);

% State (kept on the figure)
S.Total      = double(NbrePts);
S.Done       = 0;
S.Msg        = Msg;
S.T0         = tic;
S.CancelSent = false;
setappdata(hWaitbar, 'ParForWaitbarState', S);

% Queues
q.Progress = parallel.pool.DataQueue;
q.Cancel   = parallel.pool.PollableDataQueue;

% Update on progress messages (client callback)
afterEach(q.Progress, @(delta) localUpdate(hWaitbar, delta, q.Cancel));

end


function tf = ParForWaitbarShouldCancel(qCancel)
%ParForWaitbarShouldCancel  Worker-side cancel check (nonblocking).
tf = false;
if isempty(qCancel)
    return
end

try
    token = poll(qCancel, 0);   % nonblocking
    tf = ~isempty(token);
catch
    % If something goes wrong (queue closed, etc.), do not cancel.
    tf = false;
end
end


function localUpdate(h, delta, qCancel)
%localUpdate  Client-side UI update: progress + ETA + Cancel broadcast.

% If waitbar is gone, quit quietly
if isempty(h) || ~ishghandle(h)
    return
end

% Default increment
if nargin < 2 || isempty(delta) || ~isscalar(delta) || ~isfinite(delta)
    delta = 1;
end

S = getappdata(h, 'ParForWaitbarState');

% Handle Cancel
if isappdata(h,'CancelRequested') && isequal(getappdata(h,'CancelRequested'), true)
    if ~S.CancelSent && ~isempty(qCancel)
        % Send a cancel token once; workers poll for it.
        try
            send(qCancel, true);
        catch
        end
        S.CancelSent = true;
    end
    setappdata(h, 'ParForWaitbarState', S);
    try, waitbar(1, h, 'Canceled.'); catch, end
    try, delete(h); catch, end
    return
end

% Progress update (clamped)
S.Done = min(S.Done + double(delta), S.Total);
fraction = max(0, min(1, S.Done / S.Total));

% ETA
elapsedSec = toc(S.T0);
if S.Done > 0
    remainSec = elapsedSec * (S.Total / S.Done - 1);
else
    remainSec = NaN;
end

txt = sprintf('%s  |  Elapsed: %s  -  Remaining: %s', ...
    S.Msg, localFmtDuration(elapsedSec), localFmtDuration(remainSec));

% Push to UI
try
    waitbar(fraction, h, txt);
    set(h, 'Name', sprintf('%.0f%%', 100*fraction));
catch
    return
end

setappdata(h, 'ParForWaitbarState', S);

% Auto-close on completion
if S.Done >= S.Total
    try, delete(h); catch, end
end

end


function s = localFmtDuration(sec)
%localFmtDuration  Format seconds as hh:mm:ss (or dd:hh:mm:ss).
if ~isfinite(sec)
    s = "--:--:--";
    return
end

d = seconds(max(0, sec));
if sec < 24*3600
    d.Format = "hh:mm:ss";
else
    d.Format = "dd:hh:mm:ss";
end
s = char(string(d));
end

% function [hWaitbar,hWaitbarMsgQueue] = ParForWaitbarCreateMH_time_GPT_rev2(Msg,NbrePts)
% %ParForWaitbarCreateMH_time Create waitbar for parfor with ETA + Cancel.
% %
% %   [h,qProgress,qCancel] = ParForWaitbarCreateMH_time(Msg,NbrePts)
% %
% %   In parfor:
% %       if ParForWaitbarShouldCancel(qCancel), break/end; end
% %       send(qProgress,1);
% %
% %   qProgress : parallel.pool.DataQueue for progress updates (worker->client)
% %   qCancel   : parallel.pool.PollableDataQueue for cancel requests (client->worker)
% 
% arguments
%     Msg (1,1) string = "Working..."
%     NbrePts (1,1) double {mustBeFinite,mustBePositive,mustBeInteger}
% end
% 
% % Waitbar with cancel button (client-side).
% hWaitbar = waitbar(0, char(Msg), ...
%     'Name','0%', ...
%     'CreateCancelBtn','setappdata(gcbf,''CancelRequested'',true);');  % :contentReference[oaicite:3]{index=3}
% setappdata(hWaitbar,'CancelRequested',false);
% 
% % Store state (cleaner than UserData-as-counter).
% S.Total = NbrePts;
% S.Done  = 0;
% S.Msg   = Msg;
% S.T0    = tic;
% setappdata(hWaitbar,'ParForWaitbarState',S);
% 
% % Queues:
% qProgress = parallel.pool.DataQueue;          % :contentReference[oaicite:4]{index=4}
% qCancel   = parallel.pool.PollableDataQueue;  % :contentReference[oaicite:5]{index=5}
% 
% % Update waitbar whenever progress data arrives.
% afterEach(qProgress, @(delta) ParForWaitbarProgressMH_time_GPT_rev2(hWaitbar,delta,qCancel)); % :contentReference[oaicite:6]{index=6}
% 
% end
