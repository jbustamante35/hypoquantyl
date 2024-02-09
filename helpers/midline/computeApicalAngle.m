function agl = computeApicalAngle(trc, slens)
%% computeApicalAngle: measure angle of apical hook
% Get angle of top segment and then compute normal of that angle
% Usage:
%   agl = computeApicalAngle(trc, slens)
%
% Input:
%   trc: contour coordinates
%   slens: lengths of left-top-right-bottom [default 60x15x60x15]
%
% Output:
%   agl: apical hook angle

if nargin < 2; slens = [60 , 15 , 60 , 15]; end

nrm = computeTopNorm(trc, slens);
agl = (atan2(-nrm(2), -nrm(1)) * 180) / pi;
end

function [nrm , tng] = computeTopNorm(trc, slens)
%% getTopNorm: get normal to top segment
top = getSeg(2, trc, slens);
tng = top(end,:) - top(1,:);
tng = tng / norm(tng);
nrm = [tng(2) , -tng(1)];
end

function [seg , crd] = getSeg(idx, trc, slens)
%% Get top, bottom, left, or right
switch numel(idx)
    case 1
        [seg , crd] = getSegment(trc, idx, slens);
    otherwise
        [seg , crd] = arrayfun(@(x) getSegment( ...
            trc, x, slens), idx, 'UniformOutput', 0);
end
end