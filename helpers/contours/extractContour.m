function [cntr , cout] = extractContour(bw, npts, alt, req, dsz, smth)
%% extractContour: find contour of single image
% This function blah
%
% Usage:
%   [cntr , cout] = extractContour(bw, npts, alt, req)
%
% Input:
%   bw: bw image
%   npts: interpolate size for coordinates
%   alt: use HypoQuantyl's alternative reindexing parameter
%   req: string to output ['' | 'Interp' (default) | 'Normalized'] Outline
%
% Output:
%   cntr: various data from contour at given frame
%   cout: just the outline, not the ContourJB object
%

%% Handle inputs
if nargin < 2; npts = 800;       end
if nargin < 3; alt  = 'default'; end
if nargin < 4; req  = 'Interp';  end
if nargin < 5; dsz  = 0;         end
if nargin < 6; smth = 0;         end

%% Pre-Process binary mask
if dsz
    dsk = fspecial('disk', dsz);
    se  = strel('disk', dsz);
    bw  = imfilter(bw, dsk);
    bw  = imdilate(bw, se);
end

%% Get boundaries of inputted bw image
bndAll    = bwboundaries(bw, 'noholes');
[~ , lrg] = max(cellfun(@numel, bndAll));
bnds      = fliplr(bndAll{lrg});

% Remove any identical points
bnds = unique(bnds, 'rows', 'stable');

%% Output final structure
% Normalization method after reindexing: 'default' subtracts by mean after
% reindexing (for CarrotSweeper), while 'alt' just reindexes (for HypoQuantyl)
cntr = ContourJB('Outline', bnds, 'InterpSize', npts, 'AltInit', alt);

%% Ouput the contour requested individually
cname = sprintf('%sOutline', req);
cout  = cntr.(cname);

if smth; cout = [smooth(cout(:,1), smth) , smooth(cout(:,2), smth)]; end
end
