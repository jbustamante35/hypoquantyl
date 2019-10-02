function [Simg, Znrms, Cntr] = hypocotylPredictor(imgs, par, Nz, Ns, px, py, pz, pp)
%% hypocotylPredictor: the two-step neural net to predict hypocotyl contours
% This function runs the full pipeline for the 2-step neural net algorithm that
% returns the x-/y-coordinate segments in the image reference frame from a given
% grayscale image of a hypocotyl. It uses two separate trained neural nets that
% first predicts the Z-Vector - or skeleton - of the hypocotyl from the inputted
% image, and then predicts the shape of the S-Vectors - or segments - that are
% formed from each point along the skeleton.
%
% The input can be a single image or a cell array of images. In the case of the
% cell array, this algorithm can be set with parallellization to run on multiple
% CPU cores.
%
% Z-Vector scores from image
% Generate dataset of Z-Vector Slices + Z-Patch PC Scores
% Iterative S-Vectors scores from Z-Vector Slices
% Predict S-Vector scores from Z-Vector slices
%
% Usage:
%   [Simg, Znrms, Cntr] = hypocotylPredictor(imgs, par, Nz, Ns, px, py, pz, pp)
%
% Input:
%   imgs: grayscale image or cell array of hypocotyl images
%   par: boolean to run single thread (0) or with parallelization (1)
%   Nz: neural net model for predicting Z-Vector PC scores from images
%   Ns: neural net model for predicting S-Vector PC scores from Z-Vector slices
%   px: X-Coordinate eigenvectors and means
%   py: Y-Coordinate eigenvectors and means
%   pz: Z-Vector eigenvectors and means
%   pp: Z-Patch eigenvectors and means
%
% Output:
%   Simg: cell array of segments predicted from the image
%   Znrms: Z-Vector predicted from the image
%   Cntr: the continous contour generated from the segments [not implemented]
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
    %% Load required datasets unless given
    DATADIR = '/home/jbustamante/Dropbox/EdgarSpalding/labdata';
    MFILES  = 'development/HypoQuantyl/datasets/matfiles';
    ROOTDIR = sprintf('%s/%s', DATADIR, MFILES);
    PCADIR  = 'pca';
    SIMDIR  = 'simulations';
    
    %
    [px, py, pz, pp, Nz, Ns] = ...
        loadNetworkDatasets(ROOTDIR, PCADIR, SIMDIR);
    
end

%% Prediction pipeline
tAll = tic;
sptA = repmat('=', 1, 80);
sptB = repmat('-', 1, 80);
if iscell(imgs)
    numCrvs = numel(imgs);
else
    numCrvs = 1;
    I       = imgs;
    clear imgs;
    imgs{1} = I;
end
fprintf('\n\n%s\nRunning 2-Step Neural Net on %d image(s)', sptA, numCrvs);

%
[Znrms , Simg , Cntr] = deal(cell(1, numCrvs));
allCrvs               = 1 : numCrvs;

if par
    %% Run with Parallelization
    % A parellel pool of 6 workers from a total of 12 (24 logical cores) was
    % safest on my remote server, and so I think for general purposes I'll
    % create a pool of (NumCores / 2)
    halfCores = ceil(feature('numcores') / 2);
    currCores = get(parcluster, 'NumWorkers');
    
    if isempty(gcp('nocreate'))
        % If no pool setup, create one
        fprintf('\nSetting up parallel pool with %d Workers...', halfCores);
        p  = parcluster;
        set(p, 'NumWorkers', halfCores);
        parpool(p);
        fprintf('DONE!\n');
        
    elseif halfCores < currCores
        % If current pool has > half cores, delete and setup with half cores
        fprintf('\nDeleting old pool of %d Workers and setting with %d Workers...', ...
            currCores, halfCores);
        delete(gcp);
        p  = parcluster;
        set(p, 'NumWorkers', halfCores);
        parpool(p);
        fprintf('DONE!\n');
        
    else
        % Pool with half cores already set up
        fprintf('\nParallel pool with %d Workers already set up!\n', halfCores);
        
    end
    
    % Run through with parallelization using half cores
    parfor cIdx = allCrvs
        t = tic;
        fprintf('\n%s\nPredicting segments for hypocotyl %d\n', sptB, cIdx);
        
        img                                   = imgs{cIdx};
        [Simg{cIdx}, Znrms{cIdx}, Cntr{cIdx}] = ...
            runPredictor(img, Nz, Ns, px, py, pz, pp);
        
        fprintf('Finished with hypocotyl %d...[%.02f sec]\n%s\n', ...
            cIdx, toc(t), sptB);
        
    end
    
else
    %% Run with single-thread
    for cIdx = allCrvs
        t = tic;
        fprintf('\n%s\nPredicting segments for hypocotyl %d\n', sptB, cIdx);
        
        img                                   = imgs{cIdx};
        [Simg{cIdx}, Znrms{cIdx}, Cntr{cIdx}] = ...
            runPredictor(img, Nz, Ns, px, py, pz, pp);
        
        fprintf('Finished with hypocotyl %d...[%.02f sec]\n%s\n', ...
            cIdx, toc(t), sptB);
        
    end
end

% Collapse
fprintf('Finished running 2-step neural net...[%.02f sec]\n%s\n', ...
    toc(tAll), sptA);

end

function [px, py, pz, pp, Nz, Ns] = loadNetworkDatasets(ROOTDIR, PCADIR, SIMDIR)
%% loadNetworkDatasets: load given PCA datasets and neural net models
% Input:
%   DATADIR: root directory of datasets
%   MFILES: directory with .mat files
%   PCADIR: directory with PCA datasets
%   SIMDIR: directory with neural net data
%

t    = tic;
sprt = repmat('-', 1, 80);

fprintf('\n\n%s\nLoading datasets and neural networks from %s:\n', ...
    sprt, ROOTDIR);

% Load PCA data [trim down and move into repository]
PCA  = 'PCA_custom';
pcax = '190709_pcaResults_x210Hypocotyls_3PCs.mat';
pcay = '190709_pcaResults_y210Hypocotyls_3PCs.mat';
pcaz = '190726_pcaResults_z210Hypocotyls_Reduced_10PCs.mat';
pcap = '190913_pcaResults_zp43890ZPatches_5PCs.mat';

px = loadFnc(ROOTDIR, PCADIR, pcax, PCA);
py = loadFnc(ROOTDIR, PCADIR, pcay, PCA);
pz = loadFnc(ROOTDIR, PCADIR, pcaz, PCA);
pp = loadFnc(ROOTDIR, PCADIR, pcap, PCA);

px = px.PCA_custom;
py = py.PCA_custom;
pz = pz.PCA_custom;
pp = pp.PCA_custom;

% Load latest network models [trim down and move into repository]
DOUT   = 'OUT';
cnnout = 'zvectors/190727_ZScoreCNN_210Contours_z10PCs_x3PCs_y3PCs.mat';
snnout = 'svectors/190916_SScoreNN_43890Segment_s6PCs.mat';

co = loadFnc(ROOTDIR, SIMDIR, cnnout, DOUT);
so = loadFnc(ROOTDIR, SIMDIR, snnout, DOUT);

ZNN = co.OUT.DataOut;
SNN = so.OUT.DataOut;

% Extract the networks
Nz = arrayfun(@(x) x.NET, ZNN, 'UniformOutput', 0);
s  = arrayfun(@(x) sprintf('N%d', x), 1:numel(Nz), 'UniformOutput', 0);
Nz = cell2struct(Nz, s, 2);

Ns = arrayfun(@(x) x.Net, SNN, 'UniformOutput', 0);
s  = arrayfun(@(x) sprintf('N%d', x), 1:numel(Ns), 'UniformOutput', 0);
Ns = cell2struct(Ns, s, 2);

fprintf('DONE! [%.02f sec]\n', toc(t));

% Load 'em up!
    function y = loadFnc(rootdir, datadir, fin, vin)
        %% loadFunction: load dataset and variables with output message
        str = sprintf('%s/%s/%s', rootdir, datadir, fin);
        y   = load(str, vin);
        fprintf('Loaded %s\n', fin);
    end

end

function Znrms = zScrsFromImage(img, Nz, pz)
%% zScrsFromImage: Z-Vector scores from image
% This function predicts the Z-Vector PC scores from the inputted image using
% the given neural network model. It then unfolds the PC scores and reshapes the
% Z-Vector into stacked Z-Vector slices.
%
% Input:
%   img: image of the hypocotyl
%   Nz: neural network model for predicting Z-Vector PC scores from images
%   pz: Z-Vector eigenvectors and means
%
% Output:
%   Znrms: predicted Z-Vector slices after unfolding and reshaping
%

t       = tic;
numCrvs = size(pz.InputData,1);
ttlSegs = size(pz.InputData,2) / 4;
pcz     = size(pz.EigVectors,2);

fprintf('Predicting and unfolding %d Z-Vector PC scores from image...', pcz);

% Predict Z-Vector scores from the inputted hypocotyl image
Zscrs = struct2array(structfun(@(x) x.predict(img), Nz, 'UniformOutput', 0));

% Unfold and Reshape Z-Vector from prepped to raw form and add normal vectors
Zprep = pcaProject(Zscrs, pz.EigVectors, pz.MeanVals, 'scr2sim');
Zrevs = zVectorConversion(Zprep, ttlSegs, numCrvs, 'rev');

% Force Tangent vector to be unit length [10.01.2019]
tmp          = Zrevs(:,3:4) - Zrevs(:,1:2);
tmpL         = sum(tmp .* tmp, 2) .^ 0.5;
tmp          = bsxfun(@times, tmp, tmpL .^-1);
Zrevs(:,3:4) = Zrevs(:,1:2) + tmp;

%
Znrms = [Zrevs , addNormalVector(Zrevs)];

fprintf('DONE! [%.02f sec]\n', toc(t));

end

function Zslcs = generateZSlices(img, Znrms, pp)
%% generateZSlices: generate dataset of Z-Vector Slices + Z-Patch PC Scores
% This function generates the input needed to run the neural net model for
% predicting S-Vector PC scores from Z-Vector slices and Z-Patches. It takes in
% an image with the set of Z-Vector slices and generates a Z-Patch from each
% Z-Vector slice. It then folds the Z-Patch into it's PC scores and creates the
% Z-Vector slice + Z-Patch PC score needed as input for the neural net model.
%
% Input:
%   img: grayscale image of the hypocotyl
%   Znrms: Z-Vector slices
%   pp: Z-Patch eigenvectors and means
%
% Output:
%   Zslcs: vectorized Z-Vector slices + Z-Patch PC score
%

t       = tic;
pcp     = size(pp.EigVectors,2);
ttlSegs = size(Znrms,1);

fprintf('Generating and folding Z-Patches to %d PCs...', pcp);

Zslcs = zeros(ttlSegs, size(Znrms,2) + size(pp.EigValues,1));
zsize = [22 , 22];
for s = 1 : length(Znrms)
    % Get Z-Patches from Z-Vector slices and fold into PC scores
    %     zptch = setZPatch(double(Znrms(s,:)), img);
    SCL   = 20;
    zptch = setZPatch(double(Znrms(s,:)), img, SCL, '', 'new');
    
    % Resize to 22 x 22 because of the tangent vector scaling issue
    Zptch = imresize(zptch, zsize);
    
    % Fold Z-Patch to PC scores then store full Z-Slice
    Zpscr      = pcaProject(Zptch(:)', pp.EigVectors, pp.MeanVals, 'sim2scr');
    Zslcs(s,:) = [Znrms(s,:) Zpscr];
end

fprintf('DONE! [%.02f sec]\n', toc(t));

end

function Simg = sScrsFromSlices(Zslcs, Ns, px, py)
%% sScrsFromSlices: predict S-Vector scores from Z-Vector slices
% This function predicts the S-Vector PC scores from each Z-Vector slice using
% the neural net model. It then unfolds the PC scores into multiple
% midpoint-normalized segments of x-/y-coordinates and reconstructs a P-Matrix
% from the Z-Vector slices. It then re-projects each segment back into the image
% reference frame as the final operation.
%
% Input:
%   Zslce: Z-Vector reshaped as slices
%   Ns: neural net model to predict S-Vector PC scores from Z-Vector slices
%   px: X-Coordinate eigenvectors and means
%   py: Y-Coordinate eigenvectors and means
%
% Output:
%   Simg: cell array of segments in the image reference frame
%

t       = tic;
pcx     = size(px.EigVectors,2);
pcy     = size(py.EigVectors,2);
ttlSegs = size(Zslcs,1);

fprintf('Predicting, unfolding, and re-projecting %dX and %dY PC scores from Z-Vector slices...', ...
    pcx, pcy);

% Predict S-Vector scores from the inputted Z-Vector slice
Sscr = struct2array(structfun(@(x) x(Zslcs')', Ns, 'UniformOutput', 0));

% Unfold and re-project S-Vectors from midpoint-normalized to image frame
xIdx = 1:3;
yIdx = 4:6;

Simg    = cell(1,ttlSegs);
allSegs = 1 : ttlSegs;
for s = allSegs
    % Reconstruct P-Matrices
    pm  = reconstructPmat(Zslcs(s,1:6));
    mid = Zslcs(s,1:2);
    
    % Unfold
    crdX = pcaProject(Sscr(s, xIdx), px.EigVectors, px.MeanVals, 'scr2sim');
    crdY = pcaProject(Sscr(s, yIdx), py.EigVectors, py.MeanVals, 'scr2sim');
    Snrm = [crdX' , crdY'];
    
    % Re-project to image frame
    Simg{s} = reverseMidpointNorm(Snrm, pm) + mid;
end

fprintf('DONE! [%.02f sec]\n', toc(t));

end

function [simg, znrms, cntr] = runPredictor(img, Nz, Ns, px, py, pz, pp)
%% runPredictor:
%
%
% Input:
%
%
% Output:
%
%

%
znrms = zScrsFromImage(img, Nz, pz);
zslcs = generateZSlices(img, znrms, pp);
simg  = sScrsFromSlices(zslcs, Ns, px, py);

% Generate continous contour from segments [not yet implemented]
cntr = [];

end



