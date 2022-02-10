function [blbl , tlbl] = labelContour(cntr, rng, sect)
%% labelContour: labels a section of a curve with ones
%
%
% Usage:
%   lbl = labelContour(cntr, rng, sect)
%
% Input:
%   cntr: contour
%   rng: threshold range for width of section
%   sect: label bottom (0), top (1), or both (2) [default 0]
%
% Output:
%   lbl: array of labelling of the contour
%

%%
if nargin < 2; rng  = 2; end
if nargin < 3; sect = 0; end

switch sect
    case 0
        % Label bottom
        wid  = max(cntr(:,2)) - rng;
        blbl = cntr(:,2) >= wid;
    case 1
        % Label top
        wid  = min(cntr(:,2)) + rng;
        blbl = cntr(:,2) <= wid;
    case 2
        % Label both
        blbl = labelContour(cntr, rng, 0);
        tlbl = labelContour(cntr, rng, 1);
end
end