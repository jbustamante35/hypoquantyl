function Sn = convertSPredictions(predS, inptZ, req, px, py, pz, ttlSegs, numCrvs, sav)
%% convertSPredictions:
% This
%
% Usage:
%   Sn = convertSPredictions(predS, inptZ, req, px, py, pz, ttlSegs, numCrvs, sav)
%
% Input:
%   predS: predicted values from NN output
%   inptZ: Z-Vector slices used as input for the NN
%   req: requested data set can be 'truth', 'sim', or 'predicted'
%   px: output from PCA of X-coordinates
%   py: output from PCA of Y-coordinates
%   pz: output from PCA of Z-vectors
%   ttlSegs: number of segments per Curve
%   numCrvs: number of Curves in the dataset
%   sav: boolean to save output in a .mat file
%
% Output:
%   Sn: structure containing processed S-Vector data
%

%% Get full Z-Vector data set
tAll = tic;
str  = sprintf('\n%s\n', repmat('-', 1, 80));
tru  = 'truth';
sim  = 'sim';
pre  = 'predicted';

fprintf('%sConverting predictions for %s data\n', str, req);
switch req
    case tru
        Xdat = [px.PCAscores , py.PCAscores];
        Ydat = pz.InputData;
        dat  = 'InputData';
    case sim
        Xdat = [px.PCAscores , py.PCAscores];
        Ydat = pz.SimData;
        dat  = 'SimData';
    case pre
        Xdat = predS;
        Ydat = inptZ;
        dat  = 'SimData';
    otherwise
        % Exit if none chosen (or req incorrectly spelled)
        Sn = [];
        fprintf(2, 'Parameter ''req'' must be [truth|sim|predicted]\n');
        fprintf('Done!...[%.02f sec]%s', toc(tAll), str);
        return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extract information about dataset
t = tic;

sIdxs   = 1 : ttlSegs;
cIdxs   = 1 : numCrvs;
allSegs = 1 : (ttlSegs * numCrvs);
lngSegs = size(px.InputData, 2);
halfIdx = ceil(lngSegs / 2);

msg = sprintf('Extracting information from %s dataset', req);
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Revert output to raw form [if using 'truth' or 'sim']
t = tic;
if ismember(req, {tru , sim})
    [~, Ynrm]   = addNormalVector(zVectorConversion(...
        Ydat, ttlSegs, numCrvs, 'rev'));
else
    Ynrm = Ydat;
end

msg = sprintf('Reverting prepped form [%s] to raw form [%s]', ...
    num2str(size(Ydat)), num2str(size(Ynrm)));
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Regenerate Pmat from Z-Vector
t = tic;

Pm = arrayfun(@(x) reconstructPmat(Ynrm(x,:)), allSegs, 'UniformOutput', 0);

msg = sprintf('Regenerating [%s] P-matrices for %d segments and %d curves', ...
    num2str([size(Pm,1) size(Pm,2)]), ttlSegs, numCrvs);
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%FullData%%%%%%%%%%%%%%%%%%
%% Back-project to midpoint-normalized coordinates
t = tic;

% Split X-/Y-Scores and re-project back to midpoint-normalized coordinates
eX = px.EigVectors;
mX = px.MeanVals;
pX = Xdat(:,1:3);
nX = pX * eX' + mX;

eY = py.EigVectors;
mY = py.MeanVals;
pY = Xdat(:,4:6);
nY = pY * eY' + mY;

msg = sprintf('Combining midpoint-normalized x-/y-coordinates to single array');
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Convert to image coordinates using processed Z-Vectors
t = tic;

U    = Ynrm(:,1:2);
nrmS = arrayfun(@(x) [nX(x,:) ; nY(x,:)]', allSegs, 'UniformOutput', 0);
cnvS = arrayfun(@(x) reverseMidpointNorm(nrmS{x}, Pm{x}) + U(x,:), ...
    allSegs, 'UniformOutput', 0);

% Get Half-Indices for each segment
midS = cellfun(@(x) x(halfIdx,:), cnvS, 'UniformOutput', 0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define Z-Vector Slices from S-Vector
[~,~,~,~,~,Z] = ...
    cellfun(@(x) midpointNorm(x), cnvS, 'UniformOutput', 0);

msg = sprintf('Extracting Z-Vectors from converted segments');
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%% Convert to multiD arrays
Pm   = cat(3, Pm{:});
nrmS = cat(3, nrmS{:});
cnvS = cat(3, cnvS{:});
midS = cat(1, midS{:});
Z    = cat(1, Z{:});

msg = sprintf('Converting to coordinates in image reference frame');
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Store output in structure
t = tic;

Sn = struct('Scores', Xdat, 'ExpandSegs', nrmS, 'RevertData', cnvS, ...
    'Pmat', Pm, 'HalfData', midS, 'ZVectors', Z);

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
    save(fn, '-v7.3', 'Sn');
    fprintf('...');
end

fprintf('Done!...[%.02f sec]%s', toc(tAll), str);

end
