function [Znrms , Zscrs] = predictZvectorFromImage(img, Nz, pz, alt_return, bvec, rot, split2stitch, addMid, uLen)
%% predictZvectorFromImage:
% This function predicts the Z-Vector PC scores from the inputted image using
% the given neural network model. It then unfolds the PC scores and reshapes the
% Z-Vector into stacked Z-Vector slices.
%
% Usage:
%   [Znrms , Zscrs] = predictZvectorFromImage(img, Nz, pz, alt_return, ...
%       bvec, rot, split2stitch, addMid, uLen)
%
% Input:
%   img: image of the hypocotyl
%   Nz: neural network model for predicting Z-Vector PC scores from images
%   pz: Z-Vector eigenvectors and means
%   alt_return: 1 to return PC scores instead of vector (default 0)
%   split2stitch: Z-Vector PC scores are split by midpoints-tangents/rotations
%   bvec: displacement to midpoint of base section
%   rot: replace tangent-normal vectors with rotation vector (default 0)
%   addMid: add back midpoint to Z-Vector's tangent-normal (default 0)
%   uLen: force tangent and normal to be unit length (default 1)
%
% Output:
%   Znrms: predicted Z-Vector slices after unfolding and reshaping
%   Zscrs: predicted Z-Vector in PC spaces
%

%% Load datasets if none given
if nargin < 2; [pz , Nz]    = loadZVecNetworks; end
if nargin < 4; alt_return   = 0               ; end
if nargin < 5; bvec         = 0               ; end
if nargin < 6; rot          = 0               ; end
if nargin < 7; split2stitch = 0               ; end
if nargin < 8; addMid       = 0               ; end
if nargin < 9; uLen         = 1               ; end

%%
if split2stitch
    % Determine vector type, size of dataset, and number of segments
    flds  = fieldnames(pz);
    vtyp  = flds{end};
    ncrvs = size(pz.mids.InputData,1);
    nsegs = size(pz.mids.InputData,2) / 2;

    % Predict Z-Vector scores from the inputted hypocotyl image
    Zscrs = struct2array(structfun(@(x) x.predict(img), Nz, 'UniformOutput', 0));
    mscrs = Zscrs(1 : pz.mids.NumberOfPCs);
    vscrs = Zscrs((pz.mids.NumberOfPCs + 1) : end);

    % Unfold and Reshape Z-Vector from prepped to raw form and add normal vectors
    mprep = pcaProject(mscrs, pz.mids.EigVecs, pz.mids.MeanVals, 'scr2sim');
    vprep = pcaProject(vscrs, pz.(vtyp).EigVecs, pz.(vtyp).MeanVals, 'scr2sim');
    mrevs = zVectorConversion(mprep, nsegs, ncrvs, 'rev');
    vrevs = zVectorConversion(vprep, nsegs, ncrvs, 'rev');

    % Convert back from Z-Score normalization
    if pz.mids.ZScoreNormalize
        mmu   = pz.mids.getZScoreNorm('Mu');
        msig  = pz.mids.getZScoreNorm('Sigma');
        vmu   = pz.(vtyp).getZScoreNorm('Mu');
        vsig  = pz.(vtyp).getZScoreNorm('Sigma');
        mrevs = (mrevs.* msig) + mmu;
        vrevs = (vrevs.* vsig) + vmu;
    end

    Zrevs = [mrevs , vrevs];

else
    % Determine size of dataset and number of segments
    if iscell(img)
        ncrvs = numel(img);
    else
        ncrvs = 1;
    end

    if rot
        nsegs = size(pz.InputData,2) / 3;
    else
        nsegs = size(pz.InputData,2) / 4;
    end

    % Predict Z-Vector scores from the inputted hypocotyl image
    Zscrs = struct2array(structfun(@(x) x.predict(img), Nz, 'UniformOutput', 0));

    % Unfold and Reshape Z-Vector from prepped to raw form and add normal vectors
    Zprep = pcaProject(Zscrs, pz.EigVecs, pz.MeanVals, 'scr2sim');
    Zrevs = zVectorConversion(Zprep, nsegs, ncrvs, 'rev');

end

%% Determine if final Z-Vector should be in rotations or tangent-normals
if rot
    % Prediction should already be in rotations
    Znrms = zVectorConversion(Zrevs, nsegs, ncrvs, 'rot');
else
    % Add normal vector
    [~ , Znrms] = addNormalVector(Zrevs(:,1:2), Zrevs(:,3:4), addMid, uLen);
end

%% [TODO] Add B-Vector


%% Convert outputs to double
if ~strcmpi(Znrms, 'double')
    Znrms = double(Znrms);
end

if ~strcmpi(Zscrs, 'double')
    Zscrs = double(Zscrs);
end

% Return Z-Vector PC scores instead of vector
if alt_return
    Znrms = Zscrs;
end

end
