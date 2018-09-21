function [raw, cnv] = convertSimulatedSegments(truX, truY, simX, simY, crv)
%% convertSimulatedSegments: convert simulated data from PCA to raw segment coordinates
% Input:
%
%
% Output:
%
%

% Get Pmat and MidPoint parameters for reverse midpoint-normalization
pmL = crv.getParameter('Pmats', ':');
mdL = crv.getMidPoint(':');

% Convert midpoint-normalized PCA data to raw segment coordinates
midNorm = @(Dx, Dy, Pm, md, n) reverseMidpointNorm([Dx(n,:) ; Dy(n,:)]', Pm(:,:,n)) + md(n,:);
raw = arrayfun(@(x) midNorm(truX, truY, pmL, mdL, x), 1:size(truX,1), 'UniformOutput', 0);
cnv = arrayfun(@(x) midNorm(simX, simY, pmL, mdL, x), 1:size(simX,1), 'UniformOutput', 0);

end