function vlen = measureVelocity(wsrc, ptrg, ipcts, rep)
%% measureVelocity: measure velocity between frames
if nargin < 4; rep = 0; end

% Make source arclengths and get difference to target arclenghts
psrc = arrayfun(@(y) arrayfun(@(x) y.calculatelength(x, 1), ipcts'), ...
    wsrc, 'UniformOutput', 0);
psrc = cat(2, psrc{:})';
vlen = ptrg - psrc;
% vlen = arrayfun(@(x) vlen(:,x), 1 : size(vlen,2), 'UniformOutput', 0)';

% Remove points where velocity == 0
if rep; vlen(vlen < 0) = 0; end
end