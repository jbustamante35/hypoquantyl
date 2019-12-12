function [Cntr, Znrms, Simg] = recursiveDisplacementPredictor(imgs, pdx, pdy, pz, pdp, Nz, Nt, z)
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
%   cntr = recursiveDisplacementPredictor(img, ptx, pty, pz, pp, Nz, Nt, z)
%
% Input:
%   imgs: grayscale image or cell array of hypocotyl images
%   pdx: X-Coordinate PCA from contour predictions
%   pdy: Y-Coordinate PCA from contour predictions
%   pz: Z-Vector PCA from segmented contours
%   pdp: Z-Patch PCA from image patches of various scales an domain shape/sizes
%   Nz: neural net model for predicting Z-Vector PC scores from images
%   Nt: neural net model for predicting D-Vectors from Z-Patch scores
%   z: initial Z-Vector to seed the initial predictions
%
% Output:
%   Cntr: the contour predicted by this algorithm
%   Znrms: Z-Vector of the predicted contour
%   Simg: placeholder debugging variable
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Constants and Parameters
% Message string separators
sprA = repmat('=', 1, 80);
sprB = repmat('-', 1, 80);

% Constants
LEN             = 25;
STP             = 1;
VIS             = false;
dom2Omit        = 1;
foldPredictions = false;
lastFrmFold     = true;
npc             = size(pdx.EigVecs,2);
nItrs           = numel(pdp.EigVecs);
allItrs         = 1 : nItrs;

%
[scls, dom, domSize] = setupParams(dom2Omit);

%% Get initial frame bundle and image patches
tCrv = tic;
fprintf('Getting initial tangent bundle and image patch samples...');

% Predict skeleton if input is empty
t = tic;
if isempty(z)
    tt = tic;
    fprintf('Predicting Tangent Bundle from Image...');
    z  = predictZvectorFromImage(imgs, Nz, pz, 0);
    fprintf('DONE [%.02f sec]\n', toc(tt));
end

% Get image patches and differnet scales and domain shapes/sizes
x = sampleCorePatches(imgs, z, scls, dom, domSize, VIS);
fprintf('DONE [%.02f sec]\n', toc(t));

%% Recursively predict vector displacements from frame bundles
Simg = cell(1, nItrs); % Placeholder debugging variable

for itr = allItrs
    tItr = tic;
    fprintf('\n%s\nPredicting image from Iteration %d...\n', ...
        sprA, itr);
    
    %% Predict vector displacements from image patches
    % Fold image patches into PC scores
    t = tic;
    fprintf('%s\nFolding Image Patch into %d PC scores...', ...
        sprB, size(pdp.EigVecs{itr}, 2));
    vprj = pcaProject(x, pdp.EigVecs{itr}, pdp.MeanVals{itr}, 'sim2scr');
    fprintf('DONE [%.02f sec]\n', toc(t));
    
    % Run neural net on PC scores of image patches
    t = tic;
    fprintf('Predicting %d-D vector from Neural Net...', ...
        size(pdp.EigVecs{itr}, 1));
    netstr = sprintf('N%d', itr);
    ypre   = (Nt.(netstr)(vprj'))';
    fprintf('DONE [%.02f sec]\n', toc(t));
    
    %% Map and Reshape predictions to image frame
    t = tic;
    fprintf('Reshaping and Mapping back to image frame...');
    tshp = computeTargets(ypre, z, false);
    fprintf('DONE [%.02f sec]\n', toc(t));
    
    if foldPredictions
        %% Smooth predicted targets using PCA on predicted displacement vectors
        tt = tic;
        fprintf('Smoothing %d predictions with %d PCs...', ...
            size(tshp,1), npc);
        
        % Convert to PC scores, Back-Project, and Reshape for x-/y-coordinates
        tx   = squeeze((tshp(:,1)))';
        preX = pcaProject(tx,   pdx.EigVecs, pdx.MeanVals, 'sim2scr');
        preX = pcaProject(preX, pdx.EigVecs, pdx.MeanVals, 'scr2sim')';
        
        ty   = squeeze((tshp(:,2)))';
        preY = pcaProject(ty,   pdy.EigVecs, pdy.MeanVals, 'sim2scr');
        preY = pcaProject(preY, pdy.EigVecs, pdy.MeanVals, 'scr2sim')';
        
        tshp = [preX , preY];
        
        fprintf('DONE [%.02f sec]...\n', toc(tt));
    else
        %% Don't smooth predictions and only take x-/y-coordinates
        tshp = tshp(:,1:2);
    end
    
    %% Create frame bundle from initial predicted contour
    t = tic;
    fprintf('Computing new frame bundle and sampling new patches...');
    z = curve2framebundle(tshp);
    x = sampleCorePatches(imgs, z, scls, dom, domSize, VIS);
    fprintf('DONE [%.02f sec]\n', toc(t));        
    
    %% Fold at the last iteration
    if itr == nItrs && lastFrmFold
        tt = tic;
        fprintf('Smoothing final iteration with %d PCs...', npc);
        
        % Convert to PC scores, Back-Project, and Reshape for x-/y-coordinates
        tx   = squeeze((tshp(:,1)))';
        preX = pcaProject(tx,   pdx.EigVecs, pdx.MeanVals, 'sim2scr');
        preX = pcaProject(preX, pdx.EigVecs, pdx.MeanVals, 'scr2sim')';
        
        ty   = squeeze((tshp(:,2)))';
        preY = pcaProject(ty,   pdy.EigVecs, pdy.MeanVals, 'sim2scr');
        preY = pcaProject(preY, pdy.EigVecs, pdy.MeanVals, 'scr2sim')';
        
        tshp = [preX , preY];
        
        fprintf('DONE [%.02f sec]...\n', toc(tt));
    end
    
    % Store each iteration's contour and close it
    Simg{itr} = [tshp ; tshp(1,:)];
    
    fprintf('%s\nFinished iteration %d! [%.02f sec]\n%s\n', ...
        sprB, itr, toc(tItr), sprA);
end

% Predicted contour is the final iteration
Cntr  = Simg{itr};
Znrms = contour2corestructure(Cntr, LEN, STP); % Get skeleton of prediction

fprintf('\n%s\nDone predicting image from %d iterations! [%.02f sec]\n%s\n', ...
    sprB, nItrs, toc(tCrv), sprB);

end


