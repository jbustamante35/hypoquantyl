function crd = reverseEnvelopeMethod(env, seg, sz)
%% reverseEnvelopeMethod: revert envelope to midpoint-normalized coordinates
% This function is the reverse of envelopeMethod, which takes coordinates from a 
% Curve object's SVectors and represents it as coordinates within it's envelope. 
% Envelope coordinates are represented as [x y] where x is the normalized 
% distance [0, 1] between start and end points, and y is the normalized distance 
% [-1, 1] from the center segment, between the two envelopes.
%
% Converting the an envelope's y-coordinate to it's corresponding 
% midpoint-normalized y-coordinate is the same equation for computing the 
% distance from the curve (see help distanceFromCurve), but solving for the 
% env_norm_y variable instead of the env_env_y variable:
%   env_norm_y = (curve_norm_y - maxD) - ((env_env_y * maxD) - maxD)
%
% Where:
%   env_env_y: envelope's y-coordinate represented in envelope coordinates
%   env_norm_y: envelope's y-coordinate in midpoint-normalized coordinates
%   curve_norm_y: curve's y-coordinate in midpoint-normalized coordinates
%   maxD: maximum distance from the original curve to the left or right envelope
%
% Usage:
%   crd = reverseEnvelopeMethod(env, seg, sz)
%
% Input:
%   env: segment coordinates in EnvelopeSegments representation
%   seg: original segment in SVectors representation
%   sz: distance from original segment to each envelope
%
% Output:
%   crd: segment coordinates in SVectors representation
%

%% Normal x-coordinate and y-coordinate
idx = round(findIndex(env, seg));
x   = seg(idx, 1);
y   = getDim(env2nrm(getDim(env, 2), seg(idx, :), sz), 2);
crd = [x y];

end

function idx = findIndex(env, seg)
%% findIndex: subfunction to revert envelope's y-coordinate back to normalized y-coordinate

idx = getDim(env, 1) * length(seg);

end

function nrmY = env2nrm(envY, segY, sz)
%% env2nrm: convert envelope y-coordinate to midpoint-normalized y-coordinate
% Converting the an envelope's y-coordinate to it's corresponding 
% midpoint-normalized y-coordinate is the same equation for computing the 
% distance from the curve (see help distanceFromCurve), but solving for the 
% env_norm_y variable instead of the env_env_y variable:
%       env_norm_y = (curve_norm_y - maxD) - ((env_env_y * maxD) - maxD)
%
% Old Method:
%       E2N_Y = @(a,c,d) (c - a) - ((d * a) - a);
%       y2    = getDim(E2N_Y(sz, seg(idx, :), getDim(env, 2)), 2);

nrmY = (segY - sz) - ((envY * sz) - sz);

end