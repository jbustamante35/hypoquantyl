function figclr(fIdx)
%% figclr: clear figure
%
% Usage:
%   figclr(fIdx)
%
% Input:
%   fIdx: index or indices to figure handles
if nargin == 1
    if numel(fIdx) > 1
        for f = 1 : numel(fIdx)
            set(0, 'CurrentFigure', fIdx(f));
            cla;clf;
        end
    else
        set(0, 'CurrentFigure', fIdx);
        cla;clf;
    end
else
    cla;clf;
end

drawnow;
end
