function cmid = cutMidlineAtLength(crv, lens, ltrp, mth)
%% cutoffMidline: overlay seedling time lapse with REGR
%
% Usage:
%   cmid = cutMidlineAtLength(crv, lens, ltrp, mth)
%
% Input:
%   crv: curve coordinates
%   lens: logical array (1) or distance (2) to determine where to cut curve
%   ltrp: size to interpolate cut midline [default size(crv,1)]
%   mth: measurement method (see below) [default 1]
%       method 1: use logical array
%       method 2: measure arclength using SmoothCurve class
%
% Output:
%   cmid: midline after cutting and interpolation
%

if nargin < 3; ltrp = size(crv,1); end
if nargin < 4; mth  = 1;           end

switch mth
    case 1
        % Use logical array to determine cut site
        if sum(lens) == ltrp
            lidxs = 1 : ltrp;
        else
            lidxs = [getDim(find(lens)', 1) - 1 ; find(lens)];
        end
        cthr = crv(lidxs,:);
    case 2
        % Use threshold length to detmine cut site
        c    = smoothCurve(crv);
        ul   = c.getArcLength(ltrp);
        cthr = crv(ul <= lens,:);
    otherwise
end

% Interpolate curve
cmid = interpolateOutline(cthr, ltrp);
end