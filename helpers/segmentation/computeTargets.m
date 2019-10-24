function [targets, szY] = computeTargets(Y, Z, toShape, par)
%% computeTargets: compute vector displacements from tangent and frame bundles
%
%
% Usage:
%   targets = computeTargets(Y, Z)
%
% Input:
%   Y: middle-indices of each segment of a split contour
%   Z: tangent bundle containing midpoints-tangents-normals
%   toShape: reshape to vectorized size
%
% Output:
%   targets: displacement vectors to serve as target values for a neural net
%

%%
if nargin < 4
    par = false;
end

nCrvs   = size(Y,3);
allCrvs = 1 : nCrvs;

%%
if par
    %% Run with parallization
    Y       = arrayfun(@(y) Y(:,:,y), allCrvs, 'UniformOutput', 0);
    Z       = arrayfun(@(z) Z(:,:,z), allCrvs, 'UniformOutput', 0);
    targets = cell(1, nCrvs);
    parfor tr = allCrvs
        tmpAff          = tb2affine(Z{tr}, [1 , 1], toShape);
        targets{tr} = ...
            applyAffineSequence(tmpAff, permute(Y{tr}, [2 1]))';
    end
    
    targets = cat(3, targets{:});
    
else
    %% Run with single-thread
    targets = zeros(size(Y));
    for tr = allCrvs
        tmpAff          = tb2affine(Z(:,:,tr), [1 , 1], toShape);
        targets(:,:,tr) = ...
            applyAffineSequence(tmpAff, permute(Y(:,:,tr), [2 1]))';
    end
end

%% Reshape to specific size
if toShape
    targets = permute(targets, [1 , 3 , 2]);
    szY     = size(targets);
    targets = reshape(targets, [prod(szY(1:2)) , prod(szY(3))]);
else
    szY = size(targets);
end

end


