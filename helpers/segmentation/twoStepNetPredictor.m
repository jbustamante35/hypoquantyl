function [Cntr, Znrms, Simg] = twoStepNetPredictor(img, px, py, pz, pp, psx, psy, Nz, Ns, v)
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
%   psx: X-Coordinate eigenvectors and means for folding the final contour
%   psy: Y-Coordinate eigenvectors and means for folding the final contour
%   v: boolean for verbosity (defaults to 0)
%
% Output:
%   Simg: cell array of segments predicted from the image
%   Znrms: Z-Vector predicted from the image
%   Cntr: the continous contour generated from the segments [not implemented]
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 10
    v = 0;
end

%% Run the pipeline!
Znrms                 = zScrsFromImage(img, Nz, pz);
Zslcs                 = generateZSlices(img, double(Znrms), pp);
[Snrm, Pm, Mid, Simg] = sScrsFromSlices(Zslcs, Ns, px, py);
Cntr                  = contourFromSegments(Snrm, Pm, Mid, psx, psy, 0);

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
pcz = size(pz.EigVecs,2);

if v
    t = tic;
    fprintf('Predicting and unfolding %d Z-Vector PC scores from image...', ...
        pcz);
end

Znrms = predictZvectorFromImage(img, Nz, pz, 1);

if v
    fprintf('DONE! [%.02f sec]\n', toc(t));
end

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
evecs   = pp.EigVecs;
mns     = pp.MeanVals;
pcp     = size(pp.EigVecs,2);
ttlSegs = size(Znrms,1);
allSegs = 1 : ttlSegs;

%%
if v
    t = tic;
    fprintf('Generating and folding Z-Patches to %d PCs...', pcp);
end

% Subtract off midpoints from Z-Vector
tmpz = [Znrms(:,1:2) , ...
    Znrms(:,3:4) - Znrms(:,1:2) , ...
    Znrms(:,5:6) - Znrms(:,1:2)];

%% Generate and vectorize Z-Patches from Z-Slices
Zptch = arrayfun(@(x)  setZPatch(Znrms(x,:), img), ...
    allSegs, 'UniformOutput', 0);
Zscrs = cellfun(@(x)   pcaProject(x(:)', evecs, mns, 'sim2scr'), ...
    Zptch, 'UniformOutput', 0);
Zsubt = arrayfun(@(x)  [tmpz(x,1:2) , tmpz(x,3:4) , tmpz(x,5:6)], ...
    allSegs, 'UniformOutput', 0);
Zslcs = cellfun(@(l,s) [l , s], Zsubt, Zscrs, 'UniformOutput', 0);
Zslcs = cat(1, Zslcs{:});

if v
    fprintf('DONE! [%.02f sec]\n', toc(t));
end

end

function [Snrm , Pms , Mids, Simg] = sScrsFromSlices(Zslcs, Ns, px, py)
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
%   Simg: cell array of segments in the image reference frame [on hold]
%   Simg: cell array of segments in midpoint-normalized frame
%

%% Constants and other misc parameters
ttlSegs = size(Zslcs,1);
allSegs = 1 : ttlSegs;
xvecs   = px.EigVecs;
xmns    = px.MeanVals;
xpcs    = size(xvecs,2);
yvecs   = py.EigVecs;
ymns    = py.MeanVals;
ypcs    = size(yvecs,2);

if v
    t = tic;
    fprintf('Predicting, unfolding, and re-projecting %dX and %dY PC scores from Z-Vector slices...', ...
        xpcs, ypcs);
end

% Predict S-Vector scores from the inputted Z-Vector slice
Sscr = struct2array(structfun(@(x) x(Zslcs')', Ns, 'UniformOutput', 0));
xIdx = 1 : ceil(size(Sscr,2) / 2);
yIdx = xIdx(end) + 1 : size(Sscr,2);
zIdx = 1 : 6;
mIdx = 1 : 2;

%% Unfold and re-project S-Vectors from midpoint-normalized to image frame
scrs = arrayfun(@(s) Sscr(s,:), allSegs, 'UniformOutput', 0);
Mids  = arrayfun(@(m) Zslcs(m, mIdx), allSegs, 'UniformOutput', 0);
Pms   = arrayfun(@(p) reconstructPmat(Zslcs(p, zIdx), 0), ...
    allSegs, 'UniformOutput', 0);
crdX = cellfun(@(x) pcaProject(x(xIdx), xvecs, xmns, 'scr2sim'), ...
    scrs, 'UniformOutput', 0);
crdY = cellfun(@(y) pcaProject(y(yIdx), yvecs, ymns, 'scr2sim'), ...
    scrs, 'UniformOutput', 0);

% Keep output as midpoint-normalized coordinates [to be folded later]
Snrm = cellfun(@(x,y) [x ; y]', crdX, crdY, 'UniformOutput', 0);
Simg = cellfun(@(x,y,p,m) reverseMidpointNorm([x ; y]', p) + m, ...
    crdX, crdY, Pms, Mids, 'UniformOutput', 0);

if v
    fprintf('DONE! [%.02f sec]\n', toc(t));
end

end

function cntr = contourFromSegments(snrm, pm, mid, psx, psy, mPct)
%% constructContourFromSegments: generate a contour from segments
% This function extracts a coordinate from each segment and constructs a
% connected contour. By default, this function takes the middle coordinate of
% each segment, where the mIdx parameter is a percentage of where to take the
% coordinate (middle index defined as mPct = 0.5).
%
% To get the first coordinate of each segment, use mPct = 0. I implemented an
% if-else block to set [mIdx = 1] if [mPct > 0].
%
% Input:
%   snrm: cell array of segments in midpoint-normalized coordinates
%   psx: x-coordinate eigenvectors and means for smoothing of the contour
%   psy: y-coordinate eigenvectors and means for smoothing of the contour
%   mPct: percentage to extract the coordinate from segments (default 0.5)
%
% Output:
%   cntr: fully connected and closed contour
%

%% Set extraction coordinate if none was inputted
if nargin < 6
    mPct = 0.5;
end

if mPct > 0
    mIdx = ceil(mPct * size(snrm{1},1));
else
    mIdx = 1;
end

%%
cnrm = cellfun(@(x) x(mIdx,:), snrm, 'UniformOutput', 0);
cnrm = cat(1, cnrm{:});

%% Smooth contour
xvecs = psx.EigVecs;
xmns  = psx.MeanVals;
yvecs = psy.EigVecs;
ymns  = psy.MeanVals;

%
nx = cnrm(:,1)';
sx = pcaProject(nx, xvecs, xmns, 'sim2scr');
rx = pcaProject(sx, xvecs, xmns, 'scr2sim');

%
ny = cnrm(:,2)';
sy = pcaProject(ny, yvecs, ymns, 'sim2scr');
ry = pcaProject(sy, yvecs, ymns, 'scr2sim');

%
rc = arrayfun(@(s) [rx(s) ; ry(s)]', 1 : length(cnrm), 'UniformOutput', 0);

%% Re-project coordinates back to image reference frame and close the contour
cntr = cellfun(@(c,p,m) reverseMidpointNorm(c, p) + m, ...
    rc, pm, mid, 'UniformOutput', 0);
cntr = cat(1, cntr{:});
cntr = [cntr ; cntr(1,:)];

end

