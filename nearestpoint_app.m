function [IND, D] = nearestpoint_app(app,x,y,m)
            if nargin==1 && strcmp(x,'test'),
                return
            end
            
            %narginchk(2,3) ;
            narginchk(3,4) ; %Have to increase this due to the 'app'
            
            if nargin==3, %Have to increase this from 2 to 3 due to the 'app'
                m = 'nearest' ;
            else
                if ~ischar(m),
                    error('Mode argument should be a string (either ''nearest'', ''previous'', or ''next'')') ;
                end
            end
            
            if ~isa(x,'double') || ~isa(y,'double'),
                error('X and Y should be double matrices') ;
            end
            
            if isempty(x) || isempty(y)
                IND = [] ;
                D = [] ;
                return ;
            end
            
            % sort the input vectors
            sz = size(x) ;
            [x, xi] = sort(x(:)) ;
            [~, xi] = sort(xi) ; % for rearranging the output back to X
            nx = numel(x) ;
            cx = zeros(nx,1) ;
            qx = isnan(x) ; % for replacing NaNs with NaNs later on
            
            [y,yi] = sort(y(:)) ;
            ny = length(y) ;
            cy = ones(ny,1) ;
            
            xy = [x ; y] ;
            
            [~, xyi] = sort(xy) ;
            cxy = [cx ; cy] ;
            cxy = cxy(xyi) ; % cxy(i) = 0 -> xy(i) belongs to X, = 1 -> xy(i) belongs to Y
            ii = cumsum(cxy) ;
            ii = ii(cxy==0).' ; % ii should be a row vector
            
            % reduce overhead
            clear cxy xy xyi ;
            
            switch lower(m),
                case {'nearest','near','absolute'}
                    % the indices of the nearest point
                    ii = [ii ; ii+1] ;
                    ii(ii==0) = 1 ;
                    ii(ii>ny) = ny ;
                    yy = y(ii) ;
                    dy = abs(repmat(x.',2,1) - yy) ;
                    [~, ai] = min(dy) ;
                    IND = ii(sub2ind(size(ii),ai,1:nx)) ;
                case {'previous','prev','before'}
                    % the indices of the previous points
                    ii(ii < 1) = NaN ;
                    IND = ii ;
                case {'next','after'}
                    % the indices of the next points
                    ii = ii + 1 ;
                    ii(ii>ny) = NaN ;
                    IND = ii ;
                otherwise
                    error('Unknown method "%s"',m) ;
            end
            
            IND(qx) = NaN ; % put NaNs back in
            % IND = IND(:) ; % solves a problem for x = 1-by-n and y = 1-by-1
            
            if nargout==2,
                % also return distance if requested;
                D = NaN(1,nx) ;
                q = ~isnan(IND) ;
                if any(q)
                    D(q) = abs(x(q) - reshape(y(IND(q)),[],1)) ;
                end
                D = reshape(D(xi),sz) ;
                
            end
            
            % reshape and sort to match input X
            IND = reshape(IND(xi),sz) ;
            
            % because Y was sorted, we have to unsort the indices
            q = ~isnan(IND) ;
            IND(q) = yi(IND(q)) ;
        end