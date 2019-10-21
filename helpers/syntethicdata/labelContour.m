function lbl = labelContour(cntr, rng)
%% labelContour: labels the bottom of a curve with ones
%
% 
% Usage:
%   lbl = labelContour(cntr, rng)
%
% Input:
%   cntr: contour to label
%   rng: threshold range for width
%
% Output:
%   lbl: array of labelling of the contour
%

%%
if nargin < 2
    rng = 2;
end

wid = max(cntr(:,2)) - rng;
lbl = cntr(:,2) >= wid;

end

