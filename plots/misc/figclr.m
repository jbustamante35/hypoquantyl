function figclr(fIdx)
%% figclr: clear figure

if nargin == 1
    if numel(fIdx) > 1
        for f = 1 : numel(fIdx)
            set(0, 'CurrentFigure', f);
            cla;clf;
        end
    else
        set(0, 'CurrentFigure', fIdx);
        cla;clf;
    end
else
    cla;clf;
end

end
