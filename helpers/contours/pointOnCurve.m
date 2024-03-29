function pts = pointOnCurve(curve_segment, point_on_curve, distance_from_curve)
%% pointOnCurve: generate a point a specified distance along the inputted curve
% This function generates a point within the envelope of a Curve object, where the user can specify
% the coordinate along the segment and the distance from the center of the curve.
%
% Usage:
%   pts = pointOnCurve(curve, point_on_curve, distance_from_curve)
%
% Input:
%   curve_segment: x-/y-coordinates of a segment of a Curve object
%   point_on_curve: coordainte along the inputted segment
%   distance_from_curve: distance away from the segment, either in the left or right envelope
%

pts = [curve_segment(point_on_curve, 1) , ...
    (curve_segment(point_on_curve, 2) - distance_from_curve)];
end
