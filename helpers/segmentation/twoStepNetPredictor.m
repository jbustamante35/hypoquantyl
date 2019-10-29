function [Cntr, Znrms, Simg] = twoStepNetPredictor(img, px, py, pz, pp, Nz, Ns)
%% twoStepNetPredictor: the two-step neural net to predict hypocotyl contours
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
%   [Cntr, Znrms, Simg] = twoStepNetPredictor(img, px, py, pz, pp, Nz, Ns)
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

%% Run the pipeline! 
Znrms = zScrsFromImage(img, Nz, pz);
zslcs = generateZSlices(img, Znrms, pp);
Simg  = sScrsFromSlices(zslcs, Ns, px, py);

% Generate continous contour from segments [not yet implemented]
Cntr = [];

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

%%
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

%%
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
    zptch = setZPatch(double(Znrms(s,:)), img, SCL, [], 2);
    
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

%%
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

