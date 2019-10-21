function [X, Z, Y] = masterFunction2(IMG, CNTR, targetsPre, scls, dom, domSize)
%%
%
%
% Usage:
%   [X, Y, Z] = masterFunction2(IMG, CNTR, targetsPre, Y, scls, dom, domSize)
%
% Input:
%   IMG: cell array of grayscale images
%   CNTR: cell array of contours
%   targetsPre: displacement vectors predicted by neural net, in tangent frames
%   Y: 
%   
%
% Output:
%   X: vectorize image patches for multiple scales and multiple domains
%   Y: displacement vectors from the tangent bundle to the contour
%   Z: tangent bundles of the contour
%

%% Constants and Parameter setup
LEN      = 25;
STP      = 1;
VIS      = 0;
toRemove = 1;
nCrvs    = numel(IMG);
allCrvs  = 1 : nCrvs;

% Check if first iteration
if nargin < 3
    firstItr = true;
    Y        = cell(1, nCrvs);
else
    % [NOTE]
    % Be sure to not assign Y output if running through multiple iterations
    firstItr = false;
    Y        = [];
end

% Get parameters for patch scaling and domain shapes and sizes
if nargin < 5
    [scls, dom, domSize] = setupParams(toRemove);
end

%% Get all core patches, tangent bundles, and displacement vectors
[X , Z] = deal(cell(1, nCrvs));
for cIdx = allCrvs
    img = IMG{cIdx};
    
    if firstItr
        % Get ground truth contour and displacement vectors
        cntr    = CNTR{cIdx};        
        Y{cIdx} = prepareTargets(cntr, LEN, STP);        
    end
    
    if firstItr
        % Get ground truth tangent bundle
        Z{cIdx} = contour2corestructure(cntr, LEN, STP);
    else
        % Compute predicted tangent bundle
        crv     = targetsPre(:, 1:2, cIdx);
        Z{cIdx} = curve2framebundle(crv);
    end
    
    % Sample Image from Tangent Bundles
    X{cIdx} = sampleCorePatches(img, Z{cIdx}, scls, dom, domSize, VIS);
    %         [X{cIdx} , zd] = setZPatch(Z{cIdx}, img, scls, s, 3, sqr);
    
    % Track progress
    if mod(cIdx, 10)
        fprintf('.');
    else
        fprintf('%d', cIdx);
    end
end

%% Reshape Patches, Displacements, and Tangent Bundles
if firstItr
    % Displacement vectors are reshaped correctly on later iterations
    Y = cat(3, Y{:});
end

X = cat(3, X{:});
X = permute(X, [1 , 3 , 2]);

szX = size(X);
X   = reshape(X, [prod(szX(1:2)) , prod(szX(3))]);
Z   = cat(3, Z{:});

end

