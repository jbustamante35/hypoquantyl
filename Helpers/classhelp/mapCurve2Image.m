function [Xi, Xm] = mapCurve2Image(crds, im , pm ,md)
%% mapCurve2Image: convert midpoint-normalized curve to original reference frame
% This function takes a set of coordinates from a midpoint-normalized segment and returns both the
% pixel intensities from the inputted image and the coordinates it was converted to. The normalized
% curve is converted to the original reference frame using my reverseMidpointNorm function.
%
% Usage:
%   [Xi, Xm] = mapCurve2Image(crds, im , pm ,md)
%
% Input:
%   crds: x-/y-coordinates of curve to map
%   im: image associated with curve
%   pm: [3 x 3] P-matrix defining the computation to rotate to original reference frame
%   md: midpoint between start and end point in original image axis reference frame
%
% Output:
%   Xi: image pixel values under curve
%   Xm: x-/y-coordinates in original image axis reference frame
%

%% 
try
    %% TODO
    % Ask if this function should convert from Envelope Coordinates first
    
    % Need to figure out what to do with NaN values
    % FIX CROPPING BY BUFFERING
    Xm = reverseMidpointNorm(crds, pm) + md;
    Xi = getDim(impixel(im, round(Xm(:,1)), round(Xm(:,2))), 1);
catch
    % Need to convert Nan to something else
    % Otherwise I need to fix the buffering of cropped images
    Xi = zeros(length(Xm));
end
end