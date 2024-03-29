function [PTCHS , ZVECS , TRGS] = prepPatchesAndTargets_dvecs(IMG, CNTR, par, nsplt, scls, doms, dszs, trgs)
%% prepPatchesAndTargets_dvecs:
%
%
% Usage:
%   [PTCHS , ZVECS , TRGS] = prepPatchesAndTargets_dvecs( ...
%       IMG, CNTR, par, nsplt, scls, doms, dszs, trgs)
%
% Input:
%   IMG: cell array of grayscale images
%   CNTR: cell array of contours
%   par: run on single-thread (0) or with parallelization (1)
%   nsplt: length to split segments
%   scls: zoom scale vectors for image patches
%   dom: domain vectors defining shape of image patches
%   dszs: domain sizes for image patches
%   trgs: displacement vectors predicted by neural net, in tangent frames
%
% Output:
%   PTCHS: vectorized image patches for multiple scales and multiple domains
%   ZVECS: tangent bundles of the contour
%   TRGS: displacement vectors from the tangent bundle to the contour

if nargin < 3; par   = 0;  end
if nargin < 4; nsplt = 25; end

%% Check if first iteration
% [NOTE] Be sure to not assign Y output if running through multiple iterations
if nargin < 8; firstItr = true; else; firstItr = false; end

%% Get all core patches, tangent bundles, and displacement vectors
ncrvs                  = numel(IMG);
[PTCHS , ZVECS , TRGS] = deal(cell(1, ncrvs));
if par
    %% Run with parallelization
    if firstItr
        % Make empty cell array to begin
        trgs = cell(1, ncrvs);
    else
        % Avoid overhead and index targets in a cell array
        trgs = arrayfun(@(x) trgs(:,1:2,x), 1 : ncrvs, 'UniformOutput', 0);
    end

    parfor cidx = 1 : ncrvs
        img  = IMG{cidx};
        cntr = CNTR{cidx};

        % Run through the master function
        if firstItr
            % Use contour points as D-Vectors in first iteration
            [PTCHS{cidx} , ZVECS{cidx} , TRGS{cidx}] = runMasterFunction( ...
                img, cntr, nsplt, scls, doms, dszs);
        else
            % Compute D-Vectors from tangent bundle from previous iteration
            [PTCHS{cidx} , ZVECS{cidx} , TRGS{cidx}] = runMasterFunction( ...
                img, cntr, nsplt, scls, doms, dszs, trgs{cidx});
        end

        % Track progress
        fprintf('...%d', cidx);
    end
else
    %% Run with single-thread
    for cidx = 1 : ncrvs
        img  = IMG{cidx};
        cntr = CNTR{cidx};

        % Obtain image patches, Z-Vectors, and D-Vectors
        if firstItr
            % Use contour points as D-Vectors in first iteration
            [PTCHS{cidx} , ZVECS{cidx} , TRGS{cidx}] = runMasterFunction( ...
                img, cntr, nsplt, scls, doms, dszs);
        else
            % Compute D-Vectors from tangent bundle from previous iteration
            [PTCHS{cidx} , ZVECS{cidx} , TRGS{cidx}] = runMasterFunction( ...
                img, cntr, nsplt, scls, doms, dszs, trgs(:, 1:2, cidx));
        end

        % Track progress
        if mod(cidx, 10); fprintf('.'); else; fprintf('%d', cidx); end
    end
end

%% Reshape Patches, Displacements, and Tangent Bundles
% Displacement vectors are reshaped correctly on later iterations
if firstItr; TRGS = cat(3, TRGS{:}); end

PTCHS = cat(3, PTCHS{:});
PTCHS = permute(PTCHS, [1 , 3 , 2]);
szX   = size(PTCHS);
PTCHS = reshape(PTCHS, [prod(szX(1:2)) , prod(szX(3))]);
ZVECS = cat(3, ZVECS{:});
end

function [PTCHS , ZVECS , TRGS] = runMasterFunction(img, cntr, nsplt, scls, doms, dszs, trgs)
%% runMasterFunction: obtain the image patches and frame bundle
% Usage:
%   [PTCHS , ZVECS , TRGS] = runMasterFunction(img, cntr, nsplt, ...
%       scls, doms, dszs, trgs)
%
% Input:
%   img:
%   cntr:
%   nsplt:
%   scls:
%   doms:
%   dszs:
%   trgs:
%
% Output:
%   PTCHS:
%   ZVECS:
%   TRGS:

%% Get ground truth contour and displacement vectors
if nargin < 7; firstItr = true; else; firstItr = false; end
if firstItr;   TRGS     = prepareTargets(cntr, nsplt);  else; TRGS = []; end

if firstItr
    % Get ground truth tangent bundle
    ZVECS = contour2corestructure(cntr, nsplt);
else
    % Compute predicted tangent bundle
    trgs  = prepareTargets(trgs, nsplt);
    ZVECS = curve2framebundle(trgs(:,1:2,:));
end

% Sample Image from Tangent Bundles
PTCHS = sampleCorePatches(img, ZVECS, scls, doms, dszs);
end
