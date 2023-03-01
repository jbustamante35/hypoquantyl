function figclr(fidx, toSet)
%% figclr: clear figure
%
% Usage:
%   figclr(fidx, toSet)
%
% Input:
%   fidx: index or indices to figure handles [default 0]
%   toSet: set figure handle without clearing [default 0]
if nargin < 1; fidx  = 0; end
if nargin < 2; toSet = 0; end

if fidx
    if numel(fidx) > 1
        for f = 1 : numel(fidx)
            set(0, 'CurrentFigure', fidx(f));
            if ~logical(toSet); cla;clf; end
        end
    else
        set(0, 'CurrentFigure', fidx);
        if ~logical(toSet); cla;clf; end
    end
else
    if ~logical(toSet); cla;clf; end
end

drawnow;
end
