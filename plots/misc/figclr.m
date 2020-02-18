function figclr(fIdx)
%% figclr: clear figure 
if nargin == 1
    set(0, 'CurrentFigure', fIdx);
end

cla;clf;

end
