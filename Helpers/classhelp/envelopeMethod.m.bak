function env = envelopeMethod(crd, seg, sz)
%% envelopeMethod: converts midpoint-normalized coordinates to coordinates within the envelope
% This function converts normalized segment coordinates to its coordinate within the envelope of
% that segment. The [x y] coordinates outputted correspond to the normalized distance
% between starting and ending points (x) and normalized the distance from the center line (y).
%
% Usage:
%   env = envelopeMethod(crd, seg, sz)
%
% Input:
%   crd: coordinates of the segment to convert to envelope coordinates
%   seg: true segment to compare to
%   sz: maximum distance from the curve to the left or right envelope
%
% Output:
%   env: converted coordinates in envelope format
%

%% Dew-it, Anikin
env = [distanceAlongCurve(crd, seg) distanceFromCurve(crd, seg, sz)];

end

