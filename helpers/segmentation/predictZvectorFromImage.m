function Znrms = predictZvectorFromImage(img, Nz, pz, rot, addMid, uLen)
%% predictZvectorFromImage:
% This function predicts the Z-Vector PC scores from the inputted image using
% the given neural network model. It then unfolds the PC scores and reshapes the
% Z-Vector into stacked Z-Vector slices.
%
% Usage:
%   Znrms = predictZvectorFromImage(img, Nz, pz, rot, addMid, uLen)
%
% Input:
%   img: image of the hypocotyl
%   Nz: neural network model for predicting Z-Vector PC scores from images
%   pz: Z-Vector eigenvectors and means
%   rot: replace tangent-normal vectors with rotation vector (default 0)
%   addMid: add back midpoint to Z-Vector's tangent-normal (default 0)
%   uLen: force tangent and normal to be unit length (default 1)
%
% Output:
%   Znrms: predicted Z-Vector slices after unfolding and reshaping
%

%% Load datasets if none given
switch nargin
    case 1
        [pz , Nz] = loadZVecNetworks;
        rot       = 0;
        addMid    = 0;
        uLen      = 1;        
    case 3
        rot    = 0;
        addMid = 0;
        uLen   = 1;        
end

%%
% Determine size of dataset and number of segments
numCrvs = size(pz.InputData,1);

if rot
    ttlSegs = size(pz.InputData,2) / 3;
else
    ttlSegs = size(pz.InputData,2) / 4;
end

% Predict Z-Vector scores from the inputted hypocotyl image
Zscrs = struct2array(structfun(@(x) x.predict(img), Nz, 'UniformOutput', 0));

% Unfold and Reshape Z-Vector from prepped to raw form and add normal vectors
Zprep = pcaProject(Zscrs, pz.EigVecs, pz.MeanVals, 'scr2sim');

Zrevs = zVectorConversion(Zprep, ttlSegs, numCrvs, 'rev');

if rot
    Znrms = zVectorConversion(Zrevs, ttlSegs, numCrvs, 'rot');
else
    % Force Tangent vector to be unit length                [10.01.2019]
    % Don't add back midpoints to tangents-normals          [10.18.2019]
    % Determine if Tangent should be subtracted by midpoint [11.06.2019]
    [~, Znrms] = addNormalVector(Zrevs(:,1:2), Zrevs(:,3:4), addMid, uLen);
end
end
