function [PTCHS , ZVECS , WTRGS] = prepPatchesAndTargets_wvecs(IMG, CNTR, par, nsplt, scls, doms, dszs, wtrgs)
%% prepPatchesAndTargets_wvecs: sample images, split contours into displacement windows
%
%
% Usage:
%   [PTCHS , ZVECS , WTRGS] = prepPatchesAndTargets_wvecs( ...
%           IMG, CNTR, par, nsplt, wtrgs, scls, doms, dsz)
%
% Input:
%   IMG: cell array of grayscale images
%   CNTR: cell array of contours
%   par: run on single-thread (0) or with parallelization (1)
%   nsplt: length to split segments
%   wtrgs: displacement windows predicted by neural net, in tangent frames
%   scls: zoom scales for image patches
%   dom: domain vectors defining shape of image patches
%   dsz: domain sizes for image patches
%   wtrgs:
%
% Output:
%   PTCHS: vectorized image patches for multiple scales and multiple domains
%   ZVECS: tangent bundles of the contour
%   WTRGS: displacement windows from the tangent bundle to the contour

if nargin < 3; par   = 0;  end
if nargin < 4; nsplt = 25; end

%% Constants and Parameter setup
ncrvs   = numel(IMG);
allCrvs = 1 : ncrvs;

% Check if first iteration
if nargin < 8
    firstItr = true;
    WTRGS    = cell(1, ncrvs);
else
    % [NOTE] Do not assign Y output if running through multiple recursions
    firstItr = false;
    WTRGS    = [];
end

%% Get all core patches, tangent bundles, and displacement vectors
[PTCHS , ZVECS] = deal(cell(1, ncrvs));
if par
    %% Run with parallelization
    if ~firstItr
        % Avoid overhead and index targets in a cell array
        tpre = arrayfun(@(x) wtrgs(:,1:2,x), allCrvs, 'UniformOutput', 0);
    else
        tpre = cell(1, ncrvs);
    end

    [PTCHS , ZVECS , WTRGS] = deal(cell(1, ncrvs));
    parfor cidx = allCrvs
        img  = IMG{cidx};
        cntr = CNTR{cidx};

        % Run through the master function
        if firstItr
            % Use contour points as D-Vectors in first iteration
            [PTCHS{cidx} , ZVECS{cidx} , WTRGS{cidx}] = ...
                runMasterFunction_wvecs(img, cntr, nsplt, ...
                scls, doms, dszs);
        else
            % Compute D-Vectors from tangent bundle from previous iteration
            [PTCHS{cidx} , ZVECS{cidx} , WTRGS{cidx}] = ...
                runMasterFunction_wvecs(img, cntr, nsplt, ...
                scls, doms, dszs, tpre{cidx});
        end

        % Track progress
        fprintf('...%d', cidx);
    end
else
    %% Run with single-thread
    for cidx = allCrvs
        img  = IMG{cidx};
        cntr = CNTR{cidx};

        % Obtain image patches, Z-Vectors, and D-Vectors
        if firstItr
            % Use contour points as D-Vectors in first iteration
            [PTCHS{cidx} , ZVECS{cidx} , WTRGS{cidx}] = ...
                runMasterFunction_wvecs(img, cntr, nsplt, ...
                scls, doms, dszs);
        else
            % Compute D-Vectors from tangent bundle from previous iteration
            [PTCHS{cidx} , ZVECS{cidx} , WTRGS{cidx}] = ...
                runMasterFunction_wvecs(img, cntr, nsplt, ...
                scls, doms, dszs, wtrgs(:, 1:2, cidx));
        end

        % Track progress
        if mod(cidx, 10); fprintf('.'); else; fprintf('%d', cidx); end
    end
end

%% Reshape Patches, Displacement Windows, and Tangent Bundles
if firstItr
    % Displacement vectors are reshaped correctly on later iterations
    wdims = ndims(WTRGS{1}) + 1;
    WTRGS = cat(wdims, WTRGS{:});
end

PTCHS = cat(1, PTCHS{:});
ZVECS = cat(3, ZVECS{:});
end

function [PTCHS , ZVECS , WTRGS] = runMasterFunction_wvecs(img, cntr, nsplt, scls, doms, dsz, wtrgs)
%% runMasterFunction_wvecs: obtain the image patches and frame bundle
%
%
% Usage:
%   [PTCHS , ZVECS , WTRGS] = runMasterFunction_wvecs( ...
%       img, cntr, scls, doms, dsz, wtrgs)
%
% Input:
%   img:
%   cntr:
%   scls:
%   doms:
%   dsz:
%   wtrgs:
%
% Output:
%   PTCHS:
%   ZVECS:
%   WTRGS:

%% Constants
if nargin < 8; firstItr = true; else; firstItr = false; end

%%
if firstItr
    % Get ground truth contour and displacement windows
    midx  = round(nsplt / 2);
    WTRGS = split2Segments(cntr, nsplt, 1, 1, midx);
else
    WTRGS = [];
end

if firstItr
    % Get ground truth tangent bundle
    ZVECS = contour2corestructure(cntr, nsplt, 1, midx);
else
    % Compute predicted tangent bundle from targets
    ZVECS = curve2framebundle(wtrgs); % normalizes length of curve
end

% Sample Image from Tangent Bundles
PTCHS = sampleCorePatches(img, ZVECS, scls, doms, dsz);
end
