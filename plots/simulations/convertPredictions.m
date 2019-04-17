function Zn = convertPredictions(predZ, req, px, py, pz, sav)
%% convertPredictions:
% This
%
% Usage:
%
%
% Input:
%
%
% Output:
%
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
ttlSegs = size(predZ, 2) / 6;
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
    'ConvertData', ci, 'Pmat', Pm, 'HalfData', hi);

%% Revert output back to rasterized form
% Xrev = zVectorConversion(Xdat, ttlSegs, numCrvs, 'rev');
% Xn   = extractIndices(idx, ttlSegs, Xrev)';
%
% % Regenerate Pmat from Z-Vector
% Pm = arrayfun(@(x) reconstructPmat(Xn(x,:)), 1:length(Xn), 'UniformOutput', 0);
% Pm = cat(3, Pm{:});
%
% % Extract each segment's midpoint-normaized x-/y-coordinates
% nxi = extractIndices(idx, ttlSegs, px.(dat))';
% nyi = extractIndices(idx, ttlSegs, py.(dat))';
%
% % Combine x-/y-coordinates into single cell array
% sIdxs = 1 : ttlSegs;
% xi    = arrayfun(@(x) nxi(x,:), sIdxs, 'UniformOutput', 0);
% yi    = arrayfun(@(x) nyi(x,:), sIdxs, 'UniformOutput', 0);
% ni    = arrayfun(@(x) [xi{x}' yi{x}'], sIdxs, 'UniformOutput', 0);
%
% % Convert to image coordinates using processed Z-Vectors
% cp = arrayfun(@(x) reverseMidpointNorm(ni{x}, Pm(:,:,x)) + Xn(x,1:2), ...
%     sIdxs, 'UniformOutput', 0);
%
% % Get half coordinates of segments [minimize amount of data to plot]
% halfIdx = ceil(size(nxi,2) / 2);
% hp   = cellfun(@(x) x(halfIdx,:), cp, 'UniformOutput', 0);
% hp   = cat(1, hp{:});
%
% % Store output in structure
% Zn = struct('FullData', Xdat, 'RevertData', Xrev, 'Pmat', Pm, 'HalfData', hp, ...
%     'M', Xn(:,1:2), 'T', Xn(:,3:4), 'N', Xn(:,5:6));

%% Save data
if sav
    pcx = length(px.EigValues);
    pcy = length(py.EigValues);
    pcz = length(pz.EigValues);
    fn = sprintf('%s_ConvertedZvector_x%d_y%d_z%d', tdate('s'), pcx, pcy, pcz);
    save(fn, '-v7.3', 'Zn');
end

end