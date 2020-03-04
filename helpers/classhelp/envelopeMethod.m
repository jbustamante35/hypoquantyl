function env = envelopeMethod(crd, seg, maxD)
%% envelopeMethod: converts midpoint-normalized to envelope coordinates 
% This function converts midpoint-normalized segment coordinates to its 
% coordinate within the envelope of that segment. The [x y] resulting 
% coordinates correspond to the normalized distance between starting and ending 
% points (x) and normalized the distance from the center line (y).
%
% Usage:
%   env = envelopeMethod(crd, seg, maxD)
%
% Input:
%   crd: coordinates of the segment to convert to envelope coordinates
%   seg: true segment to compare to
%   maxD: maximum distance from curve to either envelope
%
% Output:
%   env: converted coordinates in envelope format
%

%% Dew-it, Anikin
try
    env  = [distanceAlongCurve(crd, seg) distanceFromCurve(crd, seg, maxD)];
catch e
    fprintf(2, '%s\n', e.getReport);
end
end

