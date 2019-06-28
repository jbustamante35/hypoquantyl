function [cntr, cout] = extractContour(bw, max_size, nrm, alt, req)
%% extractContour: find contour of single image
% This function blah
%
% Usage:
%   cntr = extractContour(bw, max_size, alt, nrm, req)
%
% Input:
%   bw: bw image
%   max_size: number of coordinates to normalize boundaries
%   nrm: reindexing method for NormalizedOutline
%   alt: use alternative reindexing parameter to use HypoQuantyl's method
%   req: string to output '', 'Interp', or 'Normalized' Outline
%
% Output:
%   cntr: various data from contour at given frame
%   cout: just the outline, not the ContourJB object
%

%% Get boundaries of inputted bw image
bndAll   = bwboundaries(bw, 'noholes');
[~, lrg] = max(cellfun(@numel, bndAll));
bnds     = bndAll{lrg};

%% Interpolate distances to an equalized number of coordinates
bnds   = [getDim(bnds, 2) , getDim(bnds, 1)]; % Switch y-/x-coordinates to x-/y-coordinates
intrps = interpolateOutline(bnds, max_size);

%% Output final structure
% Normalization method after reindexing: 'default' subtracts by mean after
% reindexing, while 'alt' just reindexes
if nargin < 3
    nrm = 'default';
end

if nargin < 4
    % Use default algorithm [CarrotSweeper] with requested normalization method
    cntr = ContourJB('Outline', bnds, 'InterpOutline', intrps);
    cntr.ReindexCoordinates(nrm);
else
    % Use alternative start coordinate by adding alt parameter [HypoQuantyl]
    cntr = ContourJB('Outline', bnds, 'InterpOutline', intrps, 'AltInit', alt);
    cntr.ReindexCoordinates(nrm);
end

%% Ouput the contour requested individually
if nargin >= 5
    cname = sprintf('%sOutline', req);
    cout  = cntr.(cname);
else
    cout = [];
end

