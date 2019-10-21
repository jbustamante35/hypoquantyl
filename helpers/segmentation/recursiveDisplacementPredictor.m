function Cntr = recursiveDisplacementPredictor(imgs, ptx, pty, pz, pp, Nz, Nt)
%% recursiveDisplacementPredictor: recursive predictions of  displacement vector
% This function runs the full pipeline for the recursive neural net algorithm
% that returns the contour in the image reference frame from a grayscale image
% of a hypocotyl. It uses an initial neural net that first predicts the Z-Vector
% - or skeleton - of the hypocotyl from the image, and then uses another neural
% net to predict the displacement vector - or D-Vectors - from the skeleton to
% the contour point. It performs this computation recursively by using the
% previously-predicted contour as the input for the frame bundle for fine-tune
% further predictions.
%
% The input can be a single image or a cell array of images. In the case of the
% cell array, this algorithm can be set with parallellization to run on multiple
% CPU cores.
%
% Z-Vector scores from image
% Predict D-Vector scores from Z-Vector Slices
% Recursively use D-Vectors as input for Z-Vector to further predict D-Vectors
%
% Usage:
%   cntr = recursiveDisplacementPredictor(img, ptx, pty, pz, pp, Nz, Nt)
%
% Input:
%   imgs: grayscale image or cell array of hypocotyl images
%   par: boolean to run single thread (0) or with parallelization (1)
%   Nz: neural net model for predicting Z-Vector PC scores from images
%   Nt: neural net model for predicting D-Vectors from Z-Patch scores
%   ptx: X-Coordinate PCA from contour predictions
%   pty: Y-Coordinate PCA from contour predictions
%   pz: Z-Vector PCA from segmented contours
%   pp: Z-Patch PCA from image patches of various scales an domain shape/sizes
%
% Output:
%   Cntr: the contour predicted by this algorithm
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Constants and Parameters
% Message string separators and
sprA = repmat('=', 1, 80);
sprB = repmat('-', 1, 80);

% Constants
VIS             = 0;
dom2Omit        = 1;
foldPredictions = 1;
npc             = size(ptx.EigVectors,2);
nItrs           = numel(pp.EigVectors);
allItrs         = 1 : nItrs;

%
[scls, dom, domSize] = setupParams(dom2Omit);

%% Get initial frame bundle and image patches
tCrv = tic;

% Predict initial skeleton for first iteration
t = tic;
fprintf('Getting initial tangent bundle and image patch samples...');
z = predictZvectorFromImage(imgs, Nz, pz);

% Get image patches and differnet scales and domain shapes/sizes
x = sampleCorePatches(imgs, z, scls, dom, domSize, VIS);
fprintf('DONE [%.02f sec]\n', toc(t));

%% Recursively predict vector displacements from frame bundles
for itr = allItrs
    tItr = tic;
    fprintf('\n%s\nPredicting image from Iteration %d...\n', ...
        sprA, itr);
    
    % Fold image patches into PC scores
    t = tic;
    fprintf('%s\nFolding Image Patch into %d PC scores...', ...
        sprB, size(pp.EigVectors{itr}, 2));
    vprj = pcaProject(x, pp.EigVectors{itr}, pp.MeanVals{itr}, 'sim2scr');
    fprintf('DONE [%.02f sec]\n', toc(t));
    
    % Run neural net on PC scores of image patches
    t = tic;
    fprintf('Predicting %d-D vector from Neural Net...', ...
        size(pp.EigVectors{itr}, 1));
    ypre = (Nt.(sprintf('N%d', itr))(vprj'))';
    fprintf('DONE [%.02f sec]\n', toc(t));
    
    % Map and Reshape predictions to image frame
    t = tic;
    fprintf('Reshaping and Mapping back to image frame...');
    tshp = computeTargets(ypre, z, 0);
    fprintf('DONE [%.02f sec]\n', toc(t));
    
    if foldPredictions
        %% Smooth predicted targets using PCA on predicted displacement vectors
        tt = tic;
        fprintf('Smoothing %d predictions with %d PCs...', ...
            size(tshp,1), npc);
        
        % Convert to PC scores, Back-Project, and Reshape for x-/y-coordinates
        tx   = squeeze((tshp(:,1)))';
        preX = pcaProject(tx,   ptx.EigVectors, ptx.MeanVals, 'sim2scr');
        preX = pcaProject(preX, ptx.EigVectors, ptx.MeanVals, 'scr2sim')';
        
        ty   = squeeze((tshp(:,2)))';
        preY = pcaProject(ty,   pty.EigVectors, pty.MeanVals, 'sim2scr');
        preY = pcaProject(preY, pty.EigVectors, pty.MeanVals, 'scr2sim')';
        
        tshp = [preX , preY];
        
        fprintf('DONE [%.02f sec]...', toc(tt));
    end
    
    % Create frame bundle from initial predicted contour
    t = tic;
    fprintf('Computing new frame bundle and sampling new patches...');
    z = curve2framebundle(tshp);
    x = sampleCorePatches(imgs, z, scls, dom, domSize, VIS);
    fprintf('DONE [%.02f sec]\n', toc(t));
    
    %
    fprintf('%s\nFinished iteration %d! [%.02f sec]\n%s\n', ...
        sprB, itr, toc(tItr), sprA);
end

%
Cntr = tshp;

fprintf('\n%s\nDone predicting image from %d iterations! [%.02f sec]\n%s\n', ...
    sprB, nItrs, toc(tCrv), sprB);

end


