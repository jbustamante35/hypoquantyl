function dst = distanceFromCurve(envelope_coordinate, curve, maxD)
%% distanceFromCurve: normalized distance from envelope point to curve segment
% This function calculates the normalized distance [-1, 1] of a  point within 
% the envelope of a Curve object to the main segment of the curve.
%
% The equation for this conversion is fairly simple but could be confusing for 
% me in the future:
%   env_env_y = (maxD - ( env_norm_y - ( curve_norm_y - maxD ))) / maxD
%
% Where:
%   env_env_y: envelope's y-coordinate represented in envelope coordinates
%   env_norm_y: envelope's y-coordinate in midpoint-normalized coordinates
%   curve_norm_y: curve's y-coordinate in midpoint-normalized coordinates
%   maxD: maximum distance from the original curve to the left or right envelope
%
% Usage:
%   dst = distanceFromCurve(envelope_coordinate, curve, maxD)
%
% Input:
%   envelope_coordinate: envelope coordinate to compute distance from curve
%   curve: main segment to compute distance from
%   maxD: maximum distance from the main segment to the extent of the envelope
%

N2E_Y = @(a,b,c) (a - ( b - ( c - a ))) ./ a;
dst   = N2E_Y(maxD, getDim(envelope_coordinate, 2), ...
    findIndex(curve, envelope_coordinate));

end

function idx = findIndex(curve, envelope_coordinate)
%% findIndex: find index along curve corresponding to envelope coordinate

idx = curve(curve(:,1) == envelope_coordinate(:,1), 2);

end

