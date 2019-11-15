function Znrms = predictZvectorFromImage(img, Nz, pz, addMid)
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
%   addMid: boolean to add back midpoint to Z-Vector's tangent-normal
%
% Output:
%   Znrms: predicted Z-Vector slices after unfolding and reshaping
%

%% Load datasets if none given
if nargin < 3
    [~, ~, pz, ~, Nz, ~] = loadZVecNetworks;
    addMid               = false;
end

%%
numCrvs = size(pz.InputData,1);
ttlSegs = size(pz.InputData,2) / 4;

% Predict Z-Vector scores from the inputted hypocotyl image
Zscrs = struct2array(structfun(@(x) x.predict(img), Nz, 'UniformOutput', 0));

% Unfold and Reshape Z-Vector from prepped to raw form and add normal vectors
Zprep = pcaProject(Zscrs, pz.EigVecs, pz.MeanVals, 'scr2sim');
Zrevs = zVectorConversion(Zprep, ttlSegs, numCrvs, 'rev');

% Force Tangent vector to be unit length [10.01.2019]
% and determine if Tangent should be subtracted by midpoint [11.06.2019]
if all(Zrevs(1,3:4) - Zrevs(1,1:2) < 0)
    tmptng = Zrevs(:,3:4);
else
    tmptng = Zrevs(:,3:4) - Zrevs(:,1:2);
end
tmpL         = sum(tmptng .* tmptng, 2) .^ 0.5;
tmptng       = bsxfun(@times, tmptng, tmpL .^-1);
Zrevs(:,3:4) = Zrevs(:,1:2) + tmptng;

%
Znrms  = [Zrevs , addNormalVector(Zrevs(:,1:2), Zrevs(:,3:4), addMid)];

%% Don't add back midpoints to tangents-normals [10.18.2019]
% Remove this when I re-do Z-Vector PCA for the ZNN
if ~addMid
    Znrms(:,3:4) = Znrms(:,3:4) - Znrms(:,1:2);
    Znrms(:,5:6) = Znrms(:,5:6) - Znrms(:,1:2);
end

end

