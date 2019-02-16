function [raw, cnv] = convertSimulatedSegments(truX, truY, simX, simY, crv)
%% convertSimulatedSegments: convert simulated data to raw segment coordinates
% This takes a single set of coordinates and uses the inverse normalization
% method to convert midpoint-normalized coordinates to raw image coordinates.
%
% Input:
%   truX: x-coordinates used as input for PCA
%   truY: y-coordinates used as input for PCA
%   simX: simulated x-coordinates after PCA analysis
%   simY: simulated y-coordinates after PCA analysis
%   crv: Curve object to extract P-matrix and midpoint data
%
% Output:
%   raw: converted input coordinates in image reference frame
%   cnv: converted simulated coordinates in image reference frame
%

% Get Pmat and MidPoint parameters for reverse midpoint-normalization
pmL = crv.getParameter('Pmats', ':');
mdL = crv.getMidPoint(':');

% Convert midpoint-normalized PCA data to raw segment coordinates
midNorm = @(Dx, Dy, Pm, md, n) reverseMidpointNorm([Dx(n,:) ; Dy(n,:)]', ...
    Pm(:,:,n)) + md(n,:);
raw = arrayfun(@(x) midNorm(truX, truY, pmL, mdL, x), ...
    1:size(truX,1), 'UniformOutput', 0);
cnv = arrayfun(@(x) midNorm(simX, simY, pmL, mdL, x), ...
    1:size(simX,1), 'UniformOutput', 0);

end