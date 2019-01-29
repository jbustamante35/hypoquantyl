function dst = distanceAlongCurve(envelope_coordinate, curve)
%% distanceAlongCurve: computes distance of a coordinate along a curve
% This function calculates the normalized distance [0, 1] of a point in an 
% envelope along the length of a curve segment.
%
% Usage:
%   dst = distanceAlongCurve(envelope_coordinate, curve)
%
% Input:
%   envelope_coordinate: x-/y-coordinate of a point in an envelope
%   curve_length: total size of the segment to normalize against
%
% Output:
%   dst: distance representing distance along a point along a curve
%

%% TODO 
% I need to be more explicit about how this algorithm works 
dst = find(getDim(envelope_coordinate, 1) == getDim(curve,1)) / length(curve);

end