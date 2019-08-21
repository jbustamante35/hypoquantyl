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
tAll = tic;
str  = sprintf('\n%s\n', repmat('-', 1, 80));
fprintf('%sConverting predictions for %s data\n', str, req);

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
        % Exit if none chosen (or req incorrectly spelled)
        Zn = [];
        fprintf(2, 'Parameter ''req'' must be [truth|sim|predicted]\n');
        fprintf('Done!...[%.02f sec]%s', toc(tAll), str);
        return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extract information about dataset
t = tic;

NUMCOLS = 6;
ttlSegs = size(predZ, 2) / NUMCOLS;
numCrvs = size(predZ, 1);
sIdxs   = 1 : ttlSegs;
cIdxs   = 1 : numCrvs;
lngSegs = size(px.(dat),2);
halfIdx = ceil(lngSegs / 2);

msg = sprintf('Extracting information from %s dataset', req);
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Revert output back to raw form
t = tic;

Xrev       = zVectorConversion(Xdat, ttlSegs, numCrvs, 'rev');
[Xid, Xnd] = arrayfun(@(x) extractIndices(x, ttlSegs, Xrev), ...
    cIdxs, 'UniformOutput', 0);
Xns        = cellfun(@(x) x', Xnd, 'UniformOutput', 0);

msg = sprintf('Reverting prepped form [%s] to raw form [%s]', ...
    num2str(size(Xrev)), num2str(size(Xns{1})));
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Regenerate Pmat from Z-Vector
t = tic;

Pms_cell = cellfun(@(x) arrayfun(@(y) reconstructPmat(x(y,:)), ...
    sIdxs, 'UniformOutput', 0), ...
    Xns, 'UniformOutput', 0);

Pm = zeros(3, 3, ttlSegs, numCrvs);
for p = 1:numel(Pms_cell)
    Pms         = Pms_cell{p};
    Pm(:,:,:,p) = cat(3, Pms{:});
end

msg = sprintf('Regenerating [%s] P-matrices for %d segments and %d curves', ...
    num2str([size(Pm,1) size(Pm,2)]), ttlSegs, numCrvs);
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Combine midpoint-normalized x-/y-coordinates into single cell array
t = tic;

%
nxis = cellfun(@(x) px.(dat)(x,:), Xid, 'UniformOutput', 0);
nyis = cellfun(@(x) py.(dat)(x,:), Xid, 'UniformOutput', 0);

%
xis = cellfun(@(x) arrayfun(@(y) x(y,:)', sIdxs, 'UniformOutput', 0), ...
    nxis, 'UniformOutput', 0);
yis = cellfun(@(x) arrayfun(@(y) x(y,:)', sIdxs, 'UniformOutput', 0), ...
    nyis, 'UniformOutput', 0);

%
nis = cellfun(@(xi,yi) cellfun(@(x,y) [x y], xi, yi, 'UniformOutput', 0), ...
    xis, yis, 'UniformOutput', 0);

msg = sprintf('Combining midpoint-normalized x-/y-coordinates to single array');
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Convert to image coordinates using processed Z-Vectors
t = tic;

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

msg = sprintf('Converting to coordinates in image reference frame');
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Store output in structure
t = tic;

Zn = struct('FullData', Xdat, 'RevertData', Xrev, 'NormalData', ni, ...
    'ConvertData', ci, 'Pmat', Pm, 'HalfData', squeeze(hi));

msg = sprintf('Storing data into structure [Save = %d]', sav);
fprintf('%s...[%.02f sec]...', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save data
if sav
    pcx = length(px.EigValues);
    pcy = length(py.EigValues);
    pcz = length(pz.EigValues);
    fn = sprintf('%s_ConvertedZvector_%dCurves_%dSegments_x%d_y%d_z%d_%s', ...
        tdate('s'), numCrvs, ttlSegs, pcx, pcy, pcz, req);
    save(fn, '-v7.3', 'Zn');
    fprintf('...');
end

fprintf('Done!...[%.02f sec]%s', toc(tAll), str);

end
