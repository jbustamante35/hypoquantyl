function Zn = convertPredictions(predZ, req, px, py, pz, sav)
%% convertPredictions:
% This
%
% Usage:
%   Zn = convertPredictions(predZ, req, px, py, pz, sav)
%
% Input:
%   predZ: predicted values from CNN output
%   req: requested data set can be 'truth', 'sim', or 'predicted'
%   px: output from PCA of X-coordinates
%   py: output from PCA of Y-coordinates
%   pz: output from PCA of Z-vectors
%   sav: boolean to save output in a .mat file
%
% Output:
%   Zin: structure containing processed Z-Vector data
%

%% Get full Z-Vector data set
switch req
    case 'truth'
        Xdat = pz.InputData;
        dat  = 'InputData';
    case 'sim'
        Xdat = pz.SimData;
        dat  = 'SimData';
    case 'predicted'
        Xdat = predZ;
        dat  = 'SimData';
    otherwise
        % Default to ground truth
        Xdat = pz.InputData;
        dat  = 'InputData';
end

%% Extract set-up data
NUMCOLS = 6;
ttlSegs = size(predZ, 2) / NUMCOLS;
numCrvs = size(predZ, 1);
sIdxs   = 1 : ttlSegs;
cIdxs   = 1 : numCrvs;
lngSegs = size(px.(dat),2);
halfIdx = ceil(lngSegs / 2);

%% Revert output back to rasterized form
Xrev = zVectorConversion(Xdat, ttlSegs, numCrvs, 'rev');
Xns  = arrayfun(@(x) extractIndices(x, ttlSegs, Xrev)', ...
    cIdxs, 'UniformOutput', 0);

%% Regenerate Pmat from Z-Vector
Pms_cell = cellfun(@(x) arrayfun(@(y) reconstructPmat(x(y,:)), ...
    1:length(x), 'UniformOutput', 0), ...
    Xns, 'UniformOutput', 0);

Pm = zeros(3, 3, ttlSegs, numCrvs);
for p = 1:numel(Pms_cell)
    Pms = Pms_cell{p};
    Pm(:,:,:,p) = cat(3, Pms{:});
end

%% Extract each segment's midpoint-normalized x-/y-coordinates
nxis = arrayfun(@(x) extractIndices(x, ttlSegs, px.(dat))', ...
    cIdxs, 'UniformOutput', 0);
nyis = arrayfun(@(x) extractIndices(x, ttlSegs, py.(dat))', ...
    cIdxs, 'UniformOutput', 0);

%% Combine midpoint-normalized x-/y-coordinates into single cell array
xis = cellfun(@(x) arrayfun(@(y) x(y,:)', sIdxs, 'UniformOutput', 0), ...
    nxis, 'UniformOutput', 0);
yis = cellfun(@(x) arrayfun(@(y) x(y,:)', sIdxs, 'UniformOutput', 0), ...
    nyis, 'UniformOutput', 0);
nis = cellfun(@(xi,yi) cellfun(@(x,y) [x y], xi, yi, 'UniformOutput', 0), ...
    xis, yis, 'UniformOutput', 0);

%% Convert to image coordinates using processed Z-Vectors
[ci , ni] = deal(zeros(lngSegs, 2, ttlSegs, numCrvs));
hi        = zeros(1, 2, ttlSegs, numCrvs);
for c = cIdxs
    Ni = nis{c};
    mp = Xns{c};
    for s = sIdxs
        pm          = Pm(:,:,s,c);
        ci(:,:,s,c) = reverseMidpointNorm(Ni{s}, pm) + mp(s,1:2);
        ni(:,:,s,c) = Ni{s};
        
        % Get half coordinates of segments [minimize amount of data to plot]
        hi(:,:,s,c) = ci(halfIdx,:,s,c);
    end
end

%% Store output in structure
Zn = struct('FullData', Xdat, 'RevertData', Xrev, 'NormalData', ni, ...
    'ConvertData', ci, 'Pmat', Pm, 'HalfData', squeeze(hi));

%% Save data
if sav
    pcx = length(px.EigValues);
    pcy = length(py.EigValues);
    pcz = length(pz.EigValues);
    fn = sprintf('%s_ConvertedZvector_%dCurves_%dSegments_x%d_y%d_z%d_%s', ...
        tdate('s'), numCrvs, ttlSegs, pcx, pcy, pcz, req);
    save(fn, '-v7.3', 'Zn');
end

end