function [ht , nclps , uidxs] = full2clipped(clps, ht, C, IMGS, nrts, rlen, npts)
%% full2clipped: convert contours in Curves to clipped versions
%
%
% Usage:
%   ht = full2clipped(ht, c, clps)
%
% Input:
%   ht: HypocotylTrainer object
%   c: full dataset of Curve objects to replace contours
%   clps: clipped versions of contours
%
% Output:
%   ht: HypocotylTrainer object with contours replaced with clipped versions
%   nclps: total number of clipped contours
%   uidxs: indices of clipped contours within full dataset
%

%%
switch nargin
    case 3
        IMGS  = arrayfun(@(c) c.getImage, C, 'UniformOutput', 0)';
        nrts  = 4;                   % Number of anchor points
        rlen  = {53 ; 52 ; 53 ; 52}; % Length between each anchor point
        npts  = 210;                 % Interpolation size
    case 4
        nrts  = 4;                   % Number of anchor points
        rlen  = {53 ; 52 ; 53 ; 52}; % Length between each anchor point
        npts  = 210;                 % Interpolation size
    otherwise
        fprintf(2, 'Error with %d inputs\n', nargin);
        [ht , nclps , uidxs] = deal([]);
        return;
end

%%
for n = 1 : numel(clps)
    clps(n).plot = [];
end

% ---------------------------------------------------------------------------- %
% Pre-Process clipped contours
% The clipped contours have some duplicate coordinates that I need to remove.
imgs  = arrayfun(@(n) double(n.I), clps, 'UniformOutput', 0)';
cntrs = arrayfun(@(n) unique(n.C(:,1:2), 'rows', 'stable'), ...
    clps, 'UniformOutput', 0)';

% Re-interpolate contours to have equal number of coordinates, and set the
% lengths between sections to set values.
cntrs = cellfun(@(x) redoContour(x, nrts, rlen), cntrs, 'UniformOutput', 0);

% ---------------------------------------------------------------------------- %
% Get indicies from clipped dataset from full dataset
% Subtract off all 500 from full set by all 171 from small set
chk = cellfun(@(i) cellfun(@(I) I - i, IMGS, 'UniformOutput', 0), ...
    imgs, 'UniformOutput', 0);
chk = cat(2, chk{:});

% Sum all values [and take absolute values]
schk = cellfun(@(x) sum(abs(x), 'all'), chk, 'UniformOutput', 0);
schk = cell2mat(schk);

% Get minimum of each row to find matching index
[~ , uidxs] = min(schk);

% ---------------------------------------------------------------------------- %
% Replace contours from Curves with clipped versions of contours
c    = C(uidxs);
d    = arrayfun(@(x) x.Parent, c);
frms = arrayfun(@(x) x.getFrame, d);
h    = arrayfun(@(x) x.Parent, d);
b    = arrayfun(@(x,f) x.getContour(f), h, frms);
arrayfun(@(x) x.setInterpSize(npts), b);

% ---------------------------------------------------------------------------- %
% Set new Curve traces
% This sets the new contours in the parent CircuitJB, since a Curve object
% doesn't contain any contours on it's own.
d = arrayfun(@(x) x, d, 'UniformOutput', 0);
cellfun(@(x,y) x.setFullOutline(y, 0), d, cntrs, 'UniformOutput', 0);
cellfun(@(x,y) x.setProperty('InterpOutline', y), d, cntrs, 'UniformOutput', 0);

% ---------------------------------------------------------------------------- %
% Store fixed Curves in HypocotylTrainer
nclps     = numel(c);
ht.Curves = c;
ht.SplitDataset;


end


function cntr = redoContour(cntr, nroutes, rlen)
%% Redo contour with proper separation of segments
switch nargin
    case 1
        nroutes = 4;
        rlen    = {53 ; 52 ; 53 ; 52};
    case 2
        rlen  = {53 ; 52 ; 53 ; 52};
end

%%
len = round(size(cntr, 1) / nroutes);
segs = arrayfun(@(x) ((len * x) + 1 : (len * (x + 1)))', ...
    0 : (nroutes - 1), 'UniformOutput', 0)';

rts = cellfun(@(x,r) interpolateOutline(cntr(x,:), r), ...
    segs, rlen, 'UniformOutput', 0);

cntr = cat(1, rts{:});

end

