function [Bcrd , Barr , Bcat] = filterSkeletonSegments(SKLS, par, LENGTHTHRESH, INTERPLENGTH)
%% filterSkeletonSegments: extract and filter segments from skeletons
% Compile a vectorized patch dataset from interpolated segments of the
% skeletonized structure. Use the probabilities of the patches to determine how
% probable a segment is along the skeleton.
%
% 1) Determine threshold to set for segment patches
%   a) Perhaps 2 Standard Deviations of all segment lengths?
%
% 2) Filter out all segments below threshold and interpolate to normalzed
%   a) Set interpolation size to median of all segment lengths
%
% 3) Get segment patches of filtered interpolated segments
%
% 4) Vectorize patches and run PCA
%
% Usage:
%    [Bcrd , Barr , Bcat] = ...
%       filterSkeletonSegments(SKLS, par, LENGTHTHRESH, INTERPLENGTH)
%
% Input:
%   SKLS: object array of Skeleton objects
%   par: boolean to use parallelization
%   LENGTHTHRESH: size of segment to set threshold [defaults to 3rd histbin]
%   INTERPLENGTH: length to interpolate segment [defaults to 3/4 of longest]
%
% Output:
%   Bcrd: vectorized, interpolated, filtered skeleton segments [arranged X-Y]
%   Barr: cell array of each Skeletons interpolated filtered segments
%   Bcat: vectorized image patches from Bcrd coordinates
%

%% Determine threshold to set for segment patches
B     = arrayfun(@(x) x.getBone, SKLS, 'UniformOutput', 0);
bLens = cellfun(@(x) cell2mat(arrayfun(@(y) size(y.Coordinates,1), ...
    x, 'UniformOutput', 0)), B, 'UniformOutput', 0);
bLAll = cat(2, bLens{:});

% Set threshold to minumum length
bmed      = median(bLAll);
hthr      = 3; % Set threshold to length at 3rd histogram bin
[~,hbins] = histcounts(bLAll, 'Normalization', 'count');
hmin      = round(hbins(hthr));

%% Filter out all segments below threshold, then interpolate coordinates
% Set interpolation size to 3/4 of longest segment length
if nargin < 3
    LENGTHTHRESH = hmin;
    INTERPLENGTH = round(mean([bmed , max(bLAll)]));
end

bflt = cellfun(@(X) cell2mat(arrayfun(@(y) y > LENGTHTHRESH, ...
    X, 'UniformOutput', 0)), bLens, 'UniformOutput', 0);
Barr = cellfun(@(b,i) b(i), B, bflt, 'UniformOutput', 0);

% Interpolate and vectorize skeleton segments
bcrds = cellfun(@(x) arrayfun(@(y) ...
    interpolateOutline(y.Coordinates, INTERPLENGTH), x, 'UniformOutput', 0), ...
    Barr, 'UniformOutput', 0);
bcrds = cat(2, bcrds{:});
bcrds = cellfun(@(x) x(:), bcrds, 'UniformOutput', 0);
Bcrd  = cat(2, bcrds{:});

%% Get segment patches of filtered and interpolated segments
% Vectorize patches
if nargin < 2
    par = 0;
end

bVect = @(x) x(:)';
if par
    Bint = cell(1, numel(Barr));
    parfor i = 1 : numel(Bint)
        barr    = Barr{i};
        Bint{i} = arrayfun(@(x) bVect(x.SampleSegment(INTERPLENGTH)), ...
            barr, 'UniformOutput', 0);
    end
else
    Bint = cellfun(@(x) arrayfun(@(y) bVect(y.SampleSegment(INTERPLENGTH)), ...
        x, 'UniformOutput', 0), Barr, 'UniformOutput', 0);
end

Bcat = cellfun(@(x) cat(1, x{:}), Bint, 'UniformOutput', 0);
Bcat = cat(1, Bcat{:});

% Concatenate all segments
% bAll = cat(2, B{:});
% bFlt = cat(2, Bflt{:});
% segs = bAll(bFlt);

end
