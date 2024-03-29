function [ht , nclps , uidxs] = full2clipped_dataset(clps, ht, C, IMGS, toSet, nrts, rlen, npts)
%% full2clipped_dataset: convert contours in Curves to clipped versions
%
% Usage:
%   [ht , nclps , uidxs] = full2clipped_dataset(clps, ht, C, IMGS, ...
%       toSet, nrts, rlen, npts)
%
% Input:
%   clps: clipped versions of contours
%   ht: HypocotylTrainer object
%   C: full dataset of Curve objects to replace contours
%   toSet: set Clipped contours in Curve objects
%   nrts: number of sections to split contours
%   rlen: lengths of each section
%   npts: number of coordinates to interpolate contour (nrts * rlen)
%
% Output:
%   ht: HypocotylTrainer object with contours replaced with clipped versions
%   nclps: total number of clipped contours
%   uidxs: indices of clipped contours within full dataset
%

%%
if nargin < 4; IMGS  = arrayfun(@(c) c.getImage, C, 'UniformOutput', 0)'; end
if nargin < 5; toSet = 1;                                                 end
if nargin < 6; nrts  = 4;                                                 end
if nargin < 7; rlen  = [53 ; 52 ; 53 ; 51];                               end
if nargin < 8; npts  = 210;                                               end

% ---------------------------------------------------------------------------- %
%% Pre-Process clipped contours
% The clipped contours have some duplicate coordinates that I need to remove.
imgs  = arrayfun(@(n) double(n.I), clps, 'UniformOutput', 0)';
cntrs = arrayfun(@(n) n.C(:,1:2), clps, 'UniformOutput', 0);

% Re-interpolate contours to have equal number of coordinates, and set the
% lengths between sections to set values.
cntrs = cellfun(@(x) redoContour(x, nrts, rlen), cntrs, 'UniformOutput', 0)';

% ---------------------------------------------------------------------------- %
% Get indicies from clipped dataset from full dataset
% Subtract off each image from full set by each image from small set [slow!]
chk = cellfun(@(i) cellfun(@(I) I - i, IMGS, 'UniformOutput', 0), ...
    imgs, 'UniformOutput', 0);
chk = cat(2, chk{:});

% Sum all values [and take absolute values]
schk = cellfun(@(x) sum(abs(x), 'all'), chk, 'UniformOutput', 0);
schk = cell2mat(schk);

% ---------------------------------------------------------------------------- %
%% Find matching index and store as Curves
[~ , uidxs] = min(schk);
c           = C(uidxs);
nclps       = numel(c);
if toSet
    % Replace contours from Curves with clipped versions of contours
    d    = arrayfun(@(x) x.Parent, c);
    frms = arrayfun(@(x) x.getFrame, d);
    h    = arrayfun(@(x) x.Parent, d);
    b    = arrayfun(@(x,f) x.getContour(f), h, frms);
    arrayfun(@(x) x.setInterpSize(npts), b);
    
    % Set new Curve traces
    % This sets the new contours in the parent CircuitJB, since a Curve object
    % doesn't contain any contours on it's own.
    d = arrayfun(@(x) x, d, 'UniformOutput', 0);
    cellfun(@(x,y) x.setOutline(y, 'Clip'), d, cntrs, 'UniformOutput', 0);
end

% ---------------------------------------------------------------------------- %
% Store fixed Curves in HypocotylTrainer
ht.Curves = c;
end

function cntr = redoContour(cntr, nroutes, rlen)
%% redoContour: redo contour with proper separation of segments
if nargin < 2; nroutes = 4;                   end
if nargin < 3; rlen    = [53 ; 52 ; 53 ; 51]; end

%% Remove duplicate corners except for the last point
len  = round(size(cntr, 1) / nroutes, -1);
segs = arrayfun(@(x) ((len * x) + 1 : (len * (x + 1)))', ...
    0 : (nroutes - 1), 'UniformOutput', 0)';
crns = cellfun(@(x) x(end), segs(1:end));

cinit = [1 ; crns(1 : nroutes-1) + 1];
cends = crns - 1;

rts = arrayfun(@(i,e,l) interpolateOutline(cntr(i:e,:), l), ...
    cinit, cends, rlen, 'UniformOutput', 0);

% Close contour
cntr = cat(1, rts{:});
if sum(cntr(1,:) ~= cntr(end,:)); cntr = [cntr ; cntr(1,:)]; end
end
