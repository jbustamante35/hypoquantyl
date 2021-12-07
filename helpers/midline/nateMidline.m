function [mline , crns] = nateMidline(trc, seg_length, rho, edg, res, mpts, fidx)
%% nateMidline:
%
% Usage:
%   [mline , crns] = nateMidline(trc, seg_length, rho, edg, res, mpts, fidx)
%
% Input:
%   trc:
%   seg_length:
%   rho:
%   edg:
%   res:
%   mpts:
%   fidx:
%
% Output:
%   mline:
%   crns:
%

%% Defaults
if nargin < 2; seg_length = [53 , 52 , 53 , 51]; end % Lengths of segments
if nargin < 3; rho        = 5;                   end % Originally 2
if nargin < 4; edg        = 3;                   end % Originally 7
if nargin < 5; res        = 0.1 ;                end % Originally 0.01
if nargin < 6; mpts       = 50;                  end % Interpolation size of midline
if nargin < 7; fidx       = 0;                   end % (0) no visual or (1) show midline walk

%% Pre-processing of contour and corners 
crns = cell2mat(arrayfun(@(x) getCornerPoint(trc, x, seg_length), ...
    1 : 4, 'UniformOutput', 0)');
bpt  = getBotMid(trc, seg_length);
trc  = trc - bpt;
crns = crns - bpt;
trc  = [trc(:,1) , -trc(:,2)];
crns = [crns(:,1) , -crns(:,2)];

%% Run midline algorithm
if fidx
    figclr(fidx);
end

skl   = hypoContour(trc, crns);
intrp = linspace(0, 1, mpts);
mobj  = skl.traceMidline(rho, edg, res, fidx);
mline = mobj.eval(intrp, 'normalized');
mline = squeeze(mline(:, 1:2, 3));

% Flip and bring back to base point
mline = [mline(:,1) , -mline(:,2)];
mline = mline + bpt;

end

function crn = getCornerPoint(trc, num, seg_length)
%% Get coordinates of corner
idx = getIndex(num, seg_length);
crn = trc(idx,:);
end

function idx = getIndex(num, seg_length)
%% Get index of corners
L   = cumsum([1 , seg_length]);
idx = L(num);
end

function mid = getBotMid(trc, seg_length)
%% Get midpoint of bottom segment
seg = getSegment(trc, 4, seg_length);
mid = mean(seg,1);
end

function seg = getSegment(trc, idx, seg_length)
%% Get top, bottom, left, or right
switch idx
    case 1
        str = getIndex(1, seg_length);
        stp = getIndex(2, seg_length);
    case 2
        str = getIndex(2, seg_length);
        stp = getIndex(3, seg_length);
    case 3
        str = getIndex(3, seg_length);
        stp = getIndex(4, seg_length);
    case 4
        str = getIndex(4, seg_length);
        stp = getIndex(5, seg_length);
    otherwise
        fprintf(2, '');
        seg = [];
        return;
end

seg = trc(str:stp,:);

end
