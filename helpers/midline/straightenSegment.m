function crv = straightenSegment(crv, seg_lengths, isOpen, tbidx)
%% straightenSegment
%
%
% Usage:
%   crv = straightenSegment(crv, seg_lengths, tbidx)
%
% Input:
%   crv: input curve
%   seg_lengths: coordinates per section (default [53 , 51 , 53 , 52])
%   tbidx: top and bottom section index (default [2 , 4])
%
% Output:
%   crv: curve with straightened top and bottom sections

if nargin < 3; isOpen = 0;       end
if nargin < 4; tbidx  = [2 , 4]; end

%%
nsegs = numel(seg_lengths);
tidx  = tbidx(1);
bidx  = tbidx(2);

% Close contour if open
if isOpen; crv = [crv ; crv(1,:)]; end

%%
% Index of top and bottom
[~, sidx] = arrayfun(@(x) getSegment(crv, x, seg_lengths), ...
    1 : nsegs, 'UniformOutput', 0);
sTop = [sidx{tidx}(1) , sidx{tidx}(end)];
sBot = [sidx{bidx}(1) , sidx{bidx}(end)];

% Interpolate corners to segment lengths
fTop = interpolateOutline(crv(sTop,:), seg_lengths(tidx));
fBot = interpolateOutline(crv(sBot,:), seg_lengths(bidx));

% Replace with straightened sections
crv(sidx{tidx},:) = fTop;
crv(sidx{bidx},:) = fBot;

% Open contour if it started opened
if isOpen; crv(end,:) = []; end
end

