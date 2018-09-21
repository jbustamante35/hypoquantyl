function dst = distanceAlongCurve(envelope_coordinate, curve)
%% distanceAlongCurve: computes normalized distance of an envelope coordinate along the curve
% This function calculates the normalized distance [0, 1] of a point in an envelope along the length
% of a curve segment.
%
% Usage:
%   dst = distanceAlongCurve(envelope_coordinate, curve)
%
% Input:
%   envelope_coordinate: x-/y-coordinate of a point in an envelope
%   curve_length: total size of the segment to normalize against
%
% Output:
%   dst: normalized distance representing how far along an envelope point is within a segment
%

dst = find(getDim(envelope_coordinate, 1) == curve) / length(curve);

end