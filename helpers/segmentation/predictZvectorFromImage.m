function Znrms = predictZvectorFromImage(img, Nz, pz)
%% predictZvectorFromImage:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: This assumes that midpoints are added back to the tangents-normals!
% Remove this when I re-do Z-Vector PCA the CNN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

%% Load datasets if none given
if nargin < 2
    [pz, Nz] = loadZVecNetworks;
end

%%
numCrvs = size(pz.InputData,1);
ttlSegs = size(pz.InputData,2) / 4;

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

%% Don't add back midpoints to tangents-normals [10.18.2019]
% Remove this when I re-do Z-Vector PCA the CNN
Znrms(:,3:4) = Znrms(:,3:4) - Znrms(:,1:2);
Znrms(:,5:6) = Znrms(:,5:6) - Znrms(:,1:2);

end

