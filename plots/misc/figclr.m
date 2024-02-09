function figclr(fidx, toClear)
%% figclr: clear figure
%
% Usage:
%   figclr(fidx, toClear)
%
% Input:
%   fidx: index or indices to figure handles [default 0]
%   toClear: clear figure [default 0]
if nargin < 1; fidx    = 0; end
if nargin < 2; toClear = 0; end

if fidx
    if numel(fidx) > 1
        for f = 1 : numel(fidx)
            set(0, 'CurrentFigure', fidx(f));
            if ~logical(toClear); cla;clf; end
        end
    else
        set(0, 'CurrentFigure', fidx);
        if ~logical(toClear); cla;clf; end
    end
else
    if ~logical(toClear); cla;clf; end
end

% drawnow;
end
