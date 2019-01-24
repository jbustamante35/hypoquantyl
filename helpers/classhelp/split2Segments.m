function segs = split2Segments(trc, len, step)
%% split2Segments: split contour into pieces of len size around the segment
% This function takes a set of coordinates (typically defining a full contour)
% and splits it into many segments of len size. These segments iteratively slide
% around the contour, with the step size to skip between lengths defined by the
% step parameter.
%
% Usage:
%   segs = split2Segments(trc, len, step)
%
% Input:
%   trc: full contour as a set of x-/y-coordinates
%   len: length to split each segment around the contour
%   step: step size for each iterative slide
%
% Output:
%   segs: [len x 2 x N] matrix of N segments of len size
%

% Determine number of iterations needed to slide around contour
sIdx    = 1;
stepper = 1 : step : (length(trc) - len - 1);
segs    = zeros(len, 2, size(stepper, 2));
for s = stepper
    segs(:, :, sIdx) = trc((s : (s + len - 1)), :);
    sIdx             = sIdx + 1;
end

% Interpolate last segment if step size exceeds total length of contour [DEPRECATED]
if ~isequal(segs(end, :, end), trc(end, :))
    endIdx = stepper(end) + step;
    endSeg = trc(endIdx : end, :);
    
    try
        segs(:, :, sIdx) = interpolateOutline(endSeg, len);
    catch
        if isequal(length(endSeg), len)
            segs(:, :, sIdx) = endSeg;
        end
    end
end

% Continue generating segments to fully wrap around contour




end