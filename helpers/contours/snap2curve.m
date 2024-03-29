function [snp , idx , dst] = snap2curve(ref, trg, mth, rot)
%% snap2curve: snap coordinates to closest point along curve
% This function takes [m x n] coordinate positions, finds the index along [p x n] coordinate matrix,
% and returns an [m x n] matrix, where coordinates are replaced by nearest coordinates in crds.
%
% Usage:
%   [snp , idx , dst] = snap2curve(ref, trg, mth, rot)
%
% Input:
%   pts: [m x n] matrix of coordinates near curve
%   crd: [p x n] matrix of coordinates on curve to search along
%   mth: method to search for nearest neighbor [dsearch|delaunay|affs|ext]
%   rot: rotation matrix [for 'ext' method]
%
% Output:
%   snp: [m x n] curve corresponding to nearest point from pts on curve
%   idx: indices of the target for snap points
%

%% Find indices corresponding to nearest distance from coordinates in pts
if nargin < 3; mth = 'dsearch'; end
if nargin < 4; rot = 0;         end

%% Implement search for neareset neighbor
dst = [];
switch mth
    case 'dsearch'
        %% Implement search without triangulation (fastest)
        [idx , dst] = dsearchn(trg, ref);
        snp         = trg(idx, :);

    case 'delaunay'
        %% Implement delaunay triangulation
        dc  = delaunayTriangulation(trg);
        idx = dc.nearestNeighbor(ref);
        snp = trg(idx,:);

    case 'affs'
        %% Get affine matrices along reference curve
        [~ , ~ , affs] = getVectorField(ref);

        % Compute normalized distance from reference to target points
        nrefs  = size(ref,1);
        dsts   = cell(nrefs, 1);
        getDst = @(c)  sum(c .^ 2, 2) .^ 0.5;
        for n = 1 : nrefs
            % Distance along tangents and normals in each reference frame
            vdst = arrayfun(@(x) (squeeze(affs(n,:,:)) * [trg(x,:) , 1]')', ...
                1 : size(trg,1), 'UniformOutput', 0);
            vdst = cat(1, vdst{:});

            % If normal vector is negative, set distance to infinity
            vdst(vdst(:,2) < 0, 2) = inf;

            % Compute length of vector
            dsts{n} = getDst(vdst(:,1:2));
        end

        % Snap to point on target with shortest distance from each source point
        [~ , idx] = cellfun(@min, dsts);
        snp       = trg(idx,:);

    case 'ext'
        %% Temporarily extend curve then run with affine method
        % Extension of midline bifurcates with a 45-angle between them
        % Compute measurements at reference curve
        [~ , ~ , v] = measureAtC(ref, trg);

        % Extend end of midline to nearest contour along tip angle and snap
        esz = round(size(trg,1) / 2);
        scl = 100;
        ext = extendCurve(trg, ref, v.tx, scl, esz, rot);

        % Define point of extension
        if rot; ept = 3 * esz; else; ept = esz; end

        % Re-snap points on extended curve to end of original curve
        [snp , idx]   = snap2curve(ref, ext, 'affs');
        exidx         = sum(ismember(snp, ext(end - ept + 1: end, :)), 2) == 2;
        snp(exidx, 1) = trg(end, 1);
        snp(exidx, 2) = trg(end, 2);
        idx(exidx)    = size(trg,1);

    otherwise
        fprintf(2, 'Error with method %s [dsearch|delaunay|affs|ext]\n', mth);
        [snp , idx , dst] = deal([]);
        return;
end
end
