function [PTCHS , ZVECS , TRGS] = masterFunction2(IMG, CNTR, par, trgs, scls, doms, dsz)
%% masterFunction2:
%
%
% Usage:
%   [PTCHS , ZVECS , TRGS] = masterFunction2( ...
%           IMG, CNTR, par, trgs, scls, doms, domSizes)
%
% Input:
%   IMG: cell array of grayscale images
%   CNTR: cell array of contours
%   par:
%   trgs: displacement vectors predicted by neural net, in tangent frames
%   scls:
%   dom:
%   dsz:
%
% Output:
%   PTCHS: vectorized image patches for multiple scales and multiple domains
%   ZVECS: tangent bundles of the contour
%   TRGS: displacement vectors from the tangent bundle to the contour
%

%% Constants and Parameter setup
% LEN      = 25;
% STP      = 1;
% VIS      = 0;
toRemove = 1;
zoomLvl  = [0.5 , 1.5];
nCrvs    = numel(IMG);
allCrvs  = 1 : nCrvs;

% Check if first iteration
if nargin < 4
    firstItr = true;
    TRGS        = cell(1, nCrvs);
else
    % [NOTE]
    % Be sure to not assign Y output if running through multiple iterations
    firstItr = false;
    TRGS        = [];
end

% Get parameters for patch scaling and domain shapes and sizes
if nargin < 5
    [scls, doms, dsz] = setupParams('toRemove', toRemove, 'zoomLvl', zoomLvl);
end

%% Get all core patches, tangent bundles, and displacement vectors
[PTCHS , ZVECS] = deal(cell(1, nCrvs));

if par
    %% Run with parallelization
    if ~firstItr
        % Avoid overhead and index targets in a cell array
        tpre = arrayfun(@(x) trgs(:,1:2,x), allCrvs, 'UniformOutput', 0);
    else
        tpre = cell(1, nCrvs);
    end
    
    [PTCHS, ZVECS, TRGS] = deal(cell(1, nCrvs));
    parfor cIdx = 1 : nCrvs
        img  = IMG{cIdx};
        cntr = CNTR{cIdx};
        
        % Run through the master function
        if firstItr
            % Use contour points as D-Vectors in first iteration
            [PTCHS{cIdx} , ZVECS{cIdx} , TRGS{cIdx}] = runMasterFunction( ...
                img, cntr, scls, doms, dsz);
        else
            % Compute D-Vectors from tangent bundle from previous iteration
            [PTCHS{cIdx} , ZVECS{cIdx} , TRGS{cIdx}] = runMasterFunction( ...
                img, cntr, scls, doms, dsz, tpre{cIdx});
        end
        
        % Track progress
        fprintf('...%d', cIdx);
        
    end
else
    %% Run with single-thread
    for cIdx = allCrvs
        img  = IMG{cIdx};
        cntr = CNTR{cIdx};
        
        % Obtain image patches, Z-Vectors, and D-Vectors
        if firstItr
            % Use contour points as D-Vectors in first iteration
            [PTCHS{cIdx} , ZVECS{cIdx} , TRGS{cIdx}] = runMasterFunction( ...
                img, cntr, scls, doms, dsz);
        else
            % Compute D-Vectors from tangent bundle from previous iteration
            [PTCHS{cIdx} , ZVECS{cIdx} , TRGS{cIdx}] = runMasterFunction( ...
                img, cntr, scls, doms, dsz, trgs(:, 1:2, cIdx));
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
    TRGS = cat(3, TRGS{:});
end

PTCHS = cat(3, PTCHS{:});
PTCHS = permute(PTCHS, [1 , 3 , 2]);

szX = size(PTCHS);
PTCHS   = reshape(PTCHS, [prod(szX(1:2)) , prod(szX(3))]);
ZVECS   = cat(3, ZVECS{:});

end

function [PTCHS , ZVECS , TRGS] = runMasterFunction(img, cntr, scls, doms, dsz, trgs, LEN, STP, VIS)
%% runMasterFunction: obtain the image patches and frame bundle
%
%
% Usage:
%   [PTCHS , ZVECS , TRGS] = runMasterFunction( ...
%       img, cntr, scls, doms, dsz, trgs, LEN, STP, VIS)
%
% Input:
%   img:
%   cntr:
%   scls:
%   doms:
%   dsz:
%   trgs:
%   LEN:
%   STP:
%   VIS:
%
% Output:
%   PTCHS:
%   ZVECS:
%   TRGS:
%

%% Constants
if nargin < 7
    LEN = 25;
    STP = 1;
    VIS = 0;
end

if nargin < 6
    firstItr = true;
else
    firstItr = false;
end

%%
if firstItr
    % Get ground truth contour and displacement vectors
    TRGS = prepareTargets(cntr, LEN, STP);
else
    TRGS = [];
end

if firstItr
    % Get ground truth tangent bundle
    ZVECS = contour2corestructure(cntr, LEN, STP);
else
    % Compute predicted tangent bundle
    crv   = trgs;
    ZVECS = curve2framebundle(crv); % normalizes length of curve
    %     ZVECS = contour2corestructure(crv, LEN, STP);
end

% Sample Image from Tangent Bundles
PTCHS = sampleCorePatches(img, ZVECS, scls, doms, dsz, VIS);

end
