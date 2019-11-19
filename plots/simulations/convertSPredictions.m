function Sn = convertSPredictions(predS, inptZ, req, px, py, pz, fldPreds, ttlSegs, numCrvs, sav)
%% convertSPredictions:
% This
%
% Usage:
%   Sn = convertSPredictions( ...
%       predS, inptZ, req, px, py, pz, ttlSegs, numCrvs, sav)
%
% Input:
%   predS: predicted values from NN output
%   inptZ: Z-Vector slices used as input for the NN
%   req: requested data set can be 'truth', 'sim', or 'predicted'
%   px: output from PCA of X-coordinates
%   py: output from PCA of Y-coordinates
%   pz: output from PCA of Z-vectors
%   fldPreds: smooth predictions using PCA
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
pcf  = 5;

fprintf('%sConverting predictions for %s data\n', str, req);
switch req
    case tru
        Xdat = [px.PCAScores , py.PCAScores];
        Ydat = pz.InputData;
    case sim
        Xdat = [px.PCAScores , py.PCAScores];
        Ydat = pz.SimData;
    case pre
        Xdat = predS;
        Ydat = inptZ;
    otherwise
        % Exit if none chosen (or req incorrectly spelled)
        Sn = [];
        fprintf(2, 'Parameter ''req'' must be [%s|%s|%s]\n', tru, sim, pre);
        fprintf('Done!...[%.02f sec]%s', toc(tAll), str);
        return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extract information about dataset
t = tic;

% sIdxs   = 1 : ttlSegs;
% cIdxs   = 1 : numCrvs;
allData = 1 : (ttlSegs * numCrvs);
% lngSegs = size(px.InputData, 2);
cntrIdx = ceil(lngSegs / 2); % Get the halfway index of each segment
% cntrIdx = 1; % Get just the first point of each predicted segment

msg = sprintf('Extracting information from %s dataset', req);
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Revert output to raw form [if using 'truth' or 'sim']
t = tic;
if ismember(req, {tru , sim})
    zcnv      = zVectorConversion(Ydat, ttlSegs, numCrvs, 'rev');
    mid       = zcnv(:,1:2);
    tng       = zcnv(:,3:4) + mid;
    [~, Ynrm] = addNormalVector(mid, tng, 1);
else
    mid  = Ydat(:,1:2);
    tng  = Ydat(:,3:4) + mid;
    nrm  = Ydat(:,5:6) + mid;
    Ynrm = [mid , tng , nrm];
end

msg = sprintf('Reverting prepped form [%s] to raw form [%s]', ...
    num2str(size(Ydat)), num2str(size(Ynrm)));
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Regenerate Pmat from Z-Vector
t = tic;

Pm = arrayfun(@(x) reconstructPmat(Ynrm(x,:)), allData, 'UniformOutput', 0);

msg = sprintf('Regenerating [%s] P-matrices for %d segments and %d curves', ...
    num2str([size(Pm,1) size(Pm,2)]), ttlSegs, numCrvs);
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%FullData%%%%%%%%%%%%%%%%%%
%% Back-project to midpoint-normalized coordinates
t = tic;

% Split X-/Y-Scores and re-project back to midpoint-normalized coordinates
xIdx = 1 : ceil(size(Xdat,2) / 2);
pX   = Xdat(:,xIdx);
nX   = pcaProject(pX, px.EigVecs, px.MeanVals, 'scr2sim');

yIdx = xIdx(end) + 1 : size(Xdat,2);
pY   = Xdat(:,yIdx);
nY   = pcaProject(pY, py.EigVecs, py.MeanVals, 'scr2sim');

msg = sprintf('Combining midpoint-normalized x-/y-coordinates to single array');
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Convert to image coordinates using processed Z-Vectors
t = tic;

U    = Ynrm(:,1:2);
nrmS = arrayfun(@(x) [nX(x,:) ; nY(x,:)]', allData, 'UniformOutput', 0);
% cnvS = arrayfun(@(x) reverseMidpointNorm(nrmS{x}, Pm{x}) + U(x,:), ...
%     allData, 'UniformOutput', 0);

% Get Half-Indices for each segment and fold them using PCA
% midS = cellfun(@(x) x(cntrIdx,:), cnvS, 'UniformOutput', 0);
midS = cellfun(@(x) x(cntrIdx,:), nrmS, 'UniformOutput', 0);

if fldPreds
    %% Smooth predicted S-Vector using PCA
    % Use midpoint-normalized coordinates
    tt = tic;
    fprintf('Smoothing %d predictions with %d PCs...', ...
        numel(midS), pcf);
    
    rawS = cat(1, midS{:});
    
    % Run PCA on X-Coordinates
    sx  = reshape(rawS(:,1), [ttlSegs numCrvs])';
    xnm = sprintf('FoldSVectorX');
    psx = pcaAnalysis(sx, pcf, sav, xnm, 0);
    
    % Run PCA on Y-Coordinates
    sy  = reshape(rawS(:,2), [ttlSegs numCrvs])';
    ynm = sprintf('FoldSVectorY');
    psy = pcaAnalysis(sy, pcf, sav, ynm, 0);
    
    % Back-Project and reshape
    midX = reshape(psx.SimData', [1 , ttlSegs * numCrvs])';
    midY = reshape(psy.SimData', [1 , ttlSegs * numCrvs])';
    midS = [midX , midY];   
    
    fprintf('DONE! [%.02f sec]...', toc(tt));
    
else
    [rawS , midS] = deal(cat(1, midS{:}));
end

%% Convert coordinates in the image reference frame and concatenate to arrays
rawS = arrayfun(@(x) reverseMidpointNorm(rawS(x,:), Pm{x}) + U(x,:), ...
    allData, 'UniformOutput', 0);
midS = arrayfun(@(x) reverseMidpointNorm(midS(x,:), Pm{x}) + U(x,:), ...
    allData, 'UniformOutput', 0);

rawS = cat(1, rawS{:});
midS = cat(1, midS{:});

% Close the contours
rawS = closeContour(rawS, ttlSegs, numCrvs);
midS = closeContour(midS, ttlSegs, numCrvs);

msg = sprintf('Converting to coordinates in image reference frame');
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Store output in structure
t = tic;

% Sn = struct('SScores', Xdat, 'ExpandSegs', nrmS, 'RevertData', cnvS, ...
%     'Pmat', Pm, 'HalfData', midS, 'ZVectors', Z);

Sn = struct('RawContour', rawS, 'Contour', midS, 'ZVectors', Ynrm);

msg = sprintf('Storing data into structure [Save = %d]', sav);
fprintf('%s...[%.02f sec]...', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save data
if sav
    pcx = length(px.EigVals);
    pcy = length(py.EigVals);
    pcz = length(pz.EigVals);
    fn = sprintf('%s_ConvertedSvector_%dCurves_%dSegments_x%d_y%d_z%d_%s', ...
        tdate('s'), numCrvs, ttlSegs, pcx, pcy, pcz, req);
    save(fn, '-v7.3', 'Sn');
    fprintf('...');
end

fprintf('Done!...[%.02f sec]%s', toc(tAll), str);

end

function cout = closeContour(cin, ttlSegs, numCrvs)
%% closeContour: close contour and interpolate back to original size
sx = reshape(cin(:,1), [ttlSegs numCrvs]);
sx = [sx ; sx(1,:)];

sy = reshape(cin(:,2), [ttlSegs numCrvs]);
sy = [sy ; sy(1,:)];

ss = arrayfun(@(x) interpolateOutline( ...
    [sx(:,x) , sy(:,x)], ttlSegs), 1 : numCrvs, 'UniformOutput', 0);

cout = cat(1, ss{:});

end

