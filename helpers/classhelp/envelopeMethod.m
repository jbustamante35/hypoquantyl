function env = envelopeMethod(crd, seg, maxD)
%% envelopeMethod: converts midpoint-normalized coordinates to coordinates within the envelope
% This function converts normalized segment coordinates to its coordinate within the envelope of
% that segment. The [x y] coordinates outputted correspond to the normalized distance
% between starting and ending points (x) and normalized the distance from the center line (y).
%
% Usage:
%   env = envelopeMethod(crd, seg, dOut, dInn)
%
% Input:
%   crd: coordinates of the segment to convert to envelope coordinates
%   seg: true segment to compare to
%   maxD: maximum distance from curve to either envelope
%   dOut: maximum distance vector from the curve to outer envelope [old]
%   dInn: maximum distance vector from the curve to inner envelope [old]
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

