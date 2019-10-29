function [X, Z, Y] = masterFunction2(IMG, CNTR, par, targetsPre, scls, dom, domSize)
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
% LEN      = 25;
% STP      = 1;
% VIS      = 0;
toRemove = 1;
nCrvs    = numel(IMG);
allCrvs  = 1 : nCrvs;

% Check if first iteration
if nargin < 4
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

if par
    %% Run with parallelization    
    if ~firstItr
        % Avoid overhead and index targetsPre via cell array
        tpre = arrayfun(@(x) targetsPre(:,1:2,x), ...
                allCrvs, 'UniformOutput', 0);
    else
        tpre = cell(1, nCrvs);
    end
    
    [X, Z, Y] = deal(cell(1, nCrvs));
    parfor cIdx = 1 : nCrvs
        img  = IMG{cIdx};
        cntr = CNTR{cIdx};
        
        % Run through the master function
        if firstItr
            [X{cIdx} , Z{cIdx} , Y{cIdx}] = runMasterFunction(img, cntr, ...
                scls, dom, domSize);
        else            
            [X{cIdx} , Z{cIdx} , Y{cIdx}] = runMasterFunction(img, cntr, ...
                scls, dom, domSize, tpre{cIdx});
        end
        
        % Track progress
        fprintf('...%d', cIdx);
        
    end
else
    %% Run with single-thread
    for cIdx = allCrvs
        img  = IMG{cIdx};
        cntr = CNTR{cIdx};
        
        % Run through the master function
        if firstItr
            [X{cIdx} , Z{cIdx} , Y{cIdx}] = runMasterFunction(img, cntr, ...
                scls, dom, domSize);
        else
            [X{cIdx} , Z{cIdx} , Y{cIdx}] = runMasterFunction(img, cntr, ...
                scls, dom, domSize, targetsPre(:, 1:2, cIdx));
        end
        
        % Track progress
        if mod(cIdx, 10)
            fprintf('.');
        else
            fprintf('%d', cIdx);
        end
        
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

function [X , Z , Y] = runMasterFunction(img, cntr, scls, dom, domSize, targetsPre)
%% runMasterFunction: obtain the image patches and frame bundle
%
%
%

%% Constants
LEN = 25;
STP = 1;
VIS = 0;

if nargin < 6
    firstItr = true;
else
    firstItr = false;
end

%%
if firstItr
    % Get ground truth contour and displacement vectors
    Y = prepareTargets(cntr, LEN, STP);
else
    Y = [];
end

if firstItr
    % Get ground truth tangent bundle
    Z = contour2corestructure(cntr, LEN, STP);
else
    % Compute predicted tangent bundle
    crv     = targetsPre;
    Z       = curve2framebundle(crv);
end

% Sample Image from Tangent Bundles
X = sampleCorePatches(img, Z, scls, dom, domSize, VIS);

end


%{
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
%}