function [Xi, Xm] = mapCurve2Image(crds, im , pm , md)
%% mapCurve2Image: midpoint-normalized curve to original reference frame
% This function takes a set of coordinates from a midpoint-normalized segment 
% and returns both the pixel intensities from the inputted image and the 
% coordinates it was converted to. The normalized curve is converted to the 
% original reference frame using my reverseMidpointNorm function.
%
% Usage:
%   [Xi, Xm] = mapCurve2Image(crds, im , pm ,md)
%
% Input:
%   crds: x-/y-coordinates of a curve 
%   im: grayscale image associated with curve
%   pm: [3 x 3] P-matrix defining function to rotate into original frame
%   md: midpoint between start and end point in the image axis reference  frame
%
% Output:
%   Xi: image pixel values under curve
%   Xm: x-/y-coordinates in original image axis frame
%
% See also REVERSEMIDPOINTNORM

%% 
try
    %% TODO
    % Ask if this function should convert from Envelope Coordinates first
    
    % Need to figure out what to do with NaN values
    % FIX CROPPING BY BUFFERING
    Xm = reverseMidpointNorm(crds, pm) + md;
    %Xi = getDim(impixel(im, round(Xm(:,1)), round(Xm(:,2))), 1);
    Xi = ba_interp2(im,Xm(:,1),Xm(:,2));
catch
    % [ TODO ] Need to convert Nan to something else. Otherwise I need to fix 
    % the buffering of cropped images. 
    %
    % [ UPDATE ] When coordinate is out of bounds of the image, replace these 
    % values with NaN, which will  be should be converted downstream as a class 
    % 
    % [ UPDATED UPDATE ] Replace out-of-bounds coordinates with the inputted
    % val parameter, which will default to 0 if empty.
    % 
    % [ FINAL UPDATE REVISED ] Just replace NaN values separately...
    Xi = zeros(length(Xm));
    
end
end
