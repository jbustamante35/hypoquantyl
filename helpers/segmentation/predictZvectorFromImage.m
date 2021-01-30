function Znrms = predictZvectorFromImage(img, Nz, pz, addMid, uLen)
%% predictZvectorFromImage:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: This assumes that midpoints are added back to the tangents-normals!
% Remove this when I re-do Z-Vector PCA the CNN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function predicts the Z-Vector PC scores from the inputted image using
% the given neural network model. It then unfolds the PC scores and reshapes the
% Z-Vector into stacked Z-Vector slices.
%
% Usage:
%   Znrms = predictZvectorFromImage(img, Nz, pz, addMid, uLen)
%
% Input:
%   img: image of the hypocotyl
%   Nz: neural network model for predicting Z-Vector PC scores from images
%   pz: Z-Vector eigenvectors and means
%   addMid: boolean to add back midpoint to Z-Vector's tangent-normal
%   uLen: force tangent and normal to be unit length
%
% Output:
%   Znrms: predicted Z-Vector slices after unfolding and reshaping
%

%% Load datasets if none given
switch nargin
    case 1
        [pz , Nz] = loadZVecNetworks;
        addMid    = 0;
        uLen      = 1;
    case 3
        addMid = 0;
        uLen   = 1;
end

%%
numCrvs = size(pz.InputData,1);
ttlSegs = size(pz.InputData,2) / 4;

% Predict Z-Vector scores from the inputted hypocotyl image
Zscrs = struct2array(structfun(@(x) x.predict(img), Nz, 'UniformOutput', 0));

% Unfold and Reshape Z-Vector from prepped to raw form and add normal vectors
Zprep = pcaProject(Zscrs, pz.EigVecs, pz.MeanVals, 'scr2sim');
Zrevs = zVectorConversion(Zprep, ttlSegs, numCrvs, 'rev');

% Force Tangent vector to be unit length                [10.01.2019]
% Don't add back midpoints to tangents-normals          [10.18.2019]
% Determine if Tangent should be subtracted by midpoint [11.06.2019]
[~, Znrms] = addNormalVector(Zrevs(:,1:2), Zrevs(:,3:4), addMid, uLen);

end
