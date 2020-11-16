function [Cntr, Znrms, Simg] = recursiveDisplacementPredictor(imgs, pdx, pdy, pz, pdp, Nz, Nd, z, v)
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
%   [Cntr, Znrms, Simg] = ...
%       recursiveDisplacementPredictor(imgs, pdx, pdy, pz, pdp, Nz, Nd, z, v)
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
%   v: boolean for verbosity level (defaults to 0)
%
% Output:
%   Cntr: the contour predicted by this algorithm
%   Znrms: Z-Vector of the predicted contour
%   Simg: placeholder debugging variable
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 10
    v = 0;
end

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
if v
    t    = tic;
    tCrv = tic;
    fprintf('Getting initial tangent bundle and image patch samples...');
end

% Predict skeleton if input is empty
if isempty(z)
    if v
        tt = tic;
        fprintf('Predicting Tangent Bundle from Image...');
    end
    
    z = predictZvectorFromImage(imgs, Nz, pz);
    
    if v
        fprintf('DONE [%.02f sec]\n', toc(tt));
    end
end

% Get image patches and differnet scales and domain shapes/sizes
x = sampleCorePatches(imgs, z, scls, dom, domSize, VIS);

if v
    fprintf('DONE [%.02f sec]\n', toc(t));
end

%% Recursively predict vector displacements from frame bundles
Simg = cell(1, nItrs); % Placeholder debugging variable

for itr = allItrs
    if v
        tItr = tic;
        fprintf('\n%s\nPredicting image from Iteration %d...\n', ...
            sprA, itr);
    end
    
    %% Predict vector displacements from image patches
    % Fold image patches into PC scores
    if v
        t = tic;
        fprintf('%s\nFolding Image Patch into %d PC scores...', ...
            sprB, size(pdp.EigVecs{itr}, 2));
    end
    
    vprj = pcaProject(x, pdp.EigVecs{itr}, pdp.MeanVals{itr}, 'sim2scr');
    
    if v
        fprintf('DONE [%.02f sec]\n', toc(t));
    end
    
    % Run neural net on PC scores of image patches
    if v
        t = tic;
        fprintf('Predicting %d-D vector from Neural Net...', ...
            size(pdp.EigVecs{itr}, 1));
    end
    
    netstr = sprintf('N%d', itr);
    ypre   = (Nd.(netstr)(vprj'))';
    
    if v
        fprintf('DONE [%.02f sec]\n', toc(t));
    end
    
    %% Map and Reshape predictions to image frame
    if v
        t = tic;
        fprintf('Reshaping and Mapping back to image frame...');
    end
    
    tshp = computeTargets(ypre, z, false);
    
    if v
        fprintf('DONE [%.02f sec]\n', toc(t));
    end
    
    %% Smooth predicted targets using PCA on predicted displacement vectors
    if foldPredictions
        if v
            tt = tic;
            fprintf('Smoothing %d predictions with %d PCs...', ...
                size(tshp,1), npc);
        end
        
        % Convert to PC scores, Back-Project, and Reshape for x-/y-coordinates
        tx   = squeeze((tshp(:,1)))';
        preX = pcaProject(tx,   pdx.EigVecs, pdx.MeanVals, 'sim2scr');
        preX = pcaProject(preX, pdx.EigVecs, pdx.MeanVals, 'scr2sim')';
        
        ty   = squeeze((tshp(:,2)))';
        preY = pcaProject(ty,   pdy.EigVecs, pdy.MeanVals, 'sim2scr');
        preY = pcaProject(preY, pdy.EigVecs, pdy.MeanVals, 'scr2sim')';
        
        tshp = [preX , preY];
        
        if v
            fprintf('DONE [%.02f sec]...\n', toc(tt));
        end
    else
        %% Don't smooth predictions and only take x-/y-coordinates
        tshp = tshp(:,1:2);
    end
    
    %% Create frame bundle from initial predicted contour
    if v
        t = tic;
        fprintf('Computing new frame bundle and sampling new patches...');
    end
    
    z = curve2framebundle(tshp);
    x = sampleCorePatches(imgs, z, scls, dom, domSize, VIS);
    
    if v
        fprintf('DONE [%.02f sec]\n', toc(t));
    end
    
    %% Fold at the last iteration
    if itr == nItrs && lastFrmFold
        if v
            tt = tic;
            fprintf('Smoothing final iteration with %d PCs...', npc);
        end
        
        % Convert to PC scores, Back-Project, and Reshape for x-/y-coordinates
        tx   = squeeze((tshp(:,1)))';
        preX = pcaProject(tx,   pdx.EigVecs, pdx.MeanVals, 'sim2scr');
        preX = pcaProject(preX, pdx.EigVecs, pdx.MeanVals, 'scr2sim')';
        
        ty   = squeeze((tshp(:,2)))';
        preY = pcaProject(ty,   pdy.EigVecs, pdy.MeanVals, 'sim2scr');
        preY = pcaProject(preY, pdy.EigVecs, pdy.MeanVals, 'scr2sim')';
        
        tshp = [preX , preY];
        
        if v
            fprintf('DONE [%.02f sec]...\n', toc(tt));
        end
    end
    
    % Store each iteration's contour and close it
    Simg{itr} = [tshp ; tshp(1,:)];
    
    if v
        fprintf('%s\nFinished iteration %d! [%.02f sec]\n%s\n', ...
            sprB, itr, toc(tItr), sprA);
    end
end

% Predicted contour is the final iteration
Cntr  = Simg{itr};
Znrms = contour2corestructure(Cntr, LEN, STP); % Get skeleton of prediction

if v
    fprintf('\n%s\nDone predicting image from %d iterations! [%.02f sec]\n%s\n', ...
        sprB, nItrs, toc(tCrv), sprB);
end

end


