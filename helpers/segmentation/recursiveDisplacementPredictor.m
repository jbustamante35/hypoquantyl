function [Cntr, Znrms, Simg] = recursiveDisplacementPredictor(imgs, pdx, pdy, pz, pdp, Nz, Nd, z, v, varargin)
%% recursiveDisplacementPredictor: predict displacement vectors
% This function runs the full pipeline for the recursive neural net algorithm
% that returns the contour in the image reference frame from a grayscale image
% of a hypocotyl. It uses an initial neural net that first predicts the Z-Vector
% - or skeleton - of the hypocotyl from the image, and then uses another neural
% net to predict the displacement vector - or D-Vectors - from the skeleton to
% the contour point. It performs this computation recursively by using the
% previously-predicted contour as the input for the frame bundle for fine-tune
% further predictions.
%
% The input can be a single image or a cell array of images. In the case of the
% cell array, this algorithm can be set with parallellization to run on multiple
% CPU cores.
%
% Z-Vector scores from image
% Predict D-Vector scores from Z-Vector Slices
% Recursively use D-Vectors as input for Z-Vector to further predict D-Vectors
%
% Usage:
%   [Cntr, Znrms, Simg] = recursiveDisplacementPredictor(imgs, ...
%       pdx, pdy, pz, pdp, Nz, Nd, z, v, varargin)
%
% Input:
%   imgs: grayscale image or cell array of hypocotyl images
%   pdx: X-Coordinate PCA from contour predictions
%   pdy: Y-Coordinate PCA from contour predictions
%   pz: Z-Vector PCA from segmented contours
%   pdp: Z-Patch PCA from image patches of various scales an domain shape/sizes
%   Nz: neural net model for predicting Z-Vector PC scores from images
%   Nt: neural net model for predicting D-Vectors from Z-Patch scores
%   z: initial Z-Vector to seed the initial predictions (default [])
%   v: boolean for verbosity level (defaults to 0)
%   varargin: misc inputs
%
% Output:
%   Cntr: the contour predicted by this algorithm
%   Znrms: Z-Vector of the predicted contour [note: not from final iteration]
%   Simg: placeholder debugging variable
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Determine inputs
switch nargin
    case 7
        z = [];
        v = 0;
    case 8
        v = 0;
end

% Parse through miscllaneous inputs
if nargin > 8
    args = parseInputs(varargin);
    for fn = fieldnames(args)'
        feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
    end
    
else
    LEN             = 25;
    STP             = 1;
    DVIS            = false; % Visualize image patches (you don't want this)
    toRemove        = 1;
    % zoomLvl         = [0.5 , 1.5];
    zoomLvl         = [];
    foldPredictions = 1; % PCA folding at each iteration
    lastFrmFold     = 1; % PCA folding at final interation
end

%% Constants and Parameters
% Message string separators
sprA    = repmat('=', 1, 80);
sprB    = repmat('-', 1, 80);
npc     = size(pdx.EigVecs,2);
nItrs   = numel(pdp.EigVecs);
allItrs = 1 : nItrs;

% Domains
[scls, dom, domSize] = setupParams('toRemove', toRemove, 'zoomLvl', zoomLvl);

%% Get initial frame bundle and image patches
switch v
    case 1
        % Condense each iteration
        fprintf('|0');
    case 2
        % Each iteration
        t    = tic;
        tCrv = tic;
        fprintf('Getting initial tangent bundle and image patch samples...');
end

% Predict skeleton if input is empty
if isempty(z)
    switch v
        case 1
            % Condense each iteration
            fprintf('-');
        case 2
            % Each iteration
            fprintf('Predicting Tangent Bundle from Image...');
    end
    
    z = predictZvectorFromImage(imgs, Nz, pz, rot, split2stitch, addMid, uLen);
    
    % Initial Z-Vector prediction from image
    Znrms.initial = z;
    
    switch v
        case 1
            % Condense each iteration
            fprintf('.');
        case 2
            % Each iteration
            fprintf('DONE [%.02f sec]...', toc(tt));
    end
end

% Get image patches and differnet scales and domain shapes/sizes
x = sampleCorePatches(imgs, z, scls, dom, domSize, DVIS);

switch v
    case 1
        % Condense each iteration
        fprintf('o');
    case 2
        % Each iteration
        fprintf('DONE [%.02f sec]\n', toc(t));
end

%% Recursively predict vector displacements from frame bundles
Simg = cell(1, nItrs); % Placeholder debugging variable

for itr = allItrs
    % ------------------------------------------------------------------------ %
    switch v
        case 1
            % Condense each iteration
            fprintf('|%d', itr);
        case 2
            % Each iteration
            tItr = tic;
            fprintf('\n%s\nPredicting image from Iteration %d...\n', ...
                sprA, itr);
    end
    
    % ------------------------------------------------------------------------ %
    %% Predict vector displacements from image patches
    % Fold image patches into PC scores
    switch v
        case 1
            % Condense each iteration
            fprintf('-');
        case 2
            % Each iteration
            t = tic;
            fprintf('%s\nFolding Image Patch into %d PC scores...', ...
                sprB, size(pdp.EigVecs{itr}, 2));
    end
    
    vprj = pcaProject(x, pdp.EigVecs{itr}, pdp.MeanVals{itr}, 'sim2scr');
    
    switch v
        case 1
            % Condense each iteration
            fprintf('.');
        case 2
            % Each iteration
            fprintf('DONE [%.02f sec]\n', toc(t));
    end
    
    % ------------------------------------------------------------------------ %
    %% Run neural net on PC scores of image patches
    switch v
        case 1
            % Condense each iteration
            fprintf('-');
        case 2
            % Each iteration
            t = tic;
            fprintf('Predicting %d-D vector from Neural Net...', ...
                size(pdp.EigVecs{itr}, 1));
    end
    
    netstr = sprintf('N%d', itr);
    ypre   = (Nd.(netstr)(vprj'))';
    
    switch v
        case 1
            % Condense each iteration
            fprintf('.');
        case 2
            % Each iteration
            fprintf('DONE [%.02f sec]\n', toc(t));
    end
    
    % ------------------------------------------------------------------------ %
    %% Map and Reshape predictions to image frame
    switch v
        case 1
            % Condense each iteration
            fprintf('-');
        case 2
            % Each iteration
            t = tic;
            fprintf('Reshaping and Mapping back to image frame...');
    end
    
    tshp = computeTargets(ypre, z, false);
    
    switch v
        case 1
            % Condense each iteration
            fprintf('.');
        case 2
            % Each iteration
            fprintf('DONE [%.02f sec]\n', toc(t));
    end
    
    % ------------------------------------------------------------------------ %
    %% Smooth predicted targets using PCA on predicted displacement vectors
    if foldPredictions
        switch v
            case 1
                % Condense each iteration
                fprintf('-');
            case 2
                % Each iteration
                tt = tic;
                fprintf('Smoothing %d predictions with %d PCs...', ...
                    size(tshp,1), npc);
        end
        
        % Convert to PC scores, Back-Project, and Reshape for x-/y-coordinates
        tshp = pcaSmooth(tshp, pdx, pdy);
        
        switch v
            case 1
                % Condense each iteration
                fprintf('.');
            case 2
                % Each iteration
                fprintf('DONE [%.02f sec]...\n', toc(tt));
        end
    else
        %% Don't smooth predictions and only take x-/y-coordinates
        tshp = tshp(:,1:2);
    end
    
    % ------------------------------------------------------------------------ %
    %% Create frame bundle from initial predicted contour
    switch v
        case 1
            % Condense each iteration
            fprintf('-');
        case 2
            % Each iteration
            t = tic;
            fprintf('Computing new frame bundle and sampling new patches...');
    end
    
    z = curve2framebundle(tshp); % normalizes length along curve
    %     z = contour2corestructure(tshp);
    x = sampleCorePatches(imgs, z, scls, dom, domSize, DVIS);
    
    switch v
        case 1
            % Condense each iteration
            fprintf('.');
        case 2
            % Each iteration
            fprintf('DONE [%.02f sec]\n', toc(t));
    end
    
    % ------------------------------------------------------------------------ %
    %% Fold at the last iteration
    if itr == nItrs && lastFrmFold
        switch v
            case 1
                % Condense each iteration
                fprintf('-');
            case 2
                % Each iteration
                tt = tic;
                fprintf('Smoothing final iteration with %d PCs...', npc);
        end
        
        % Convert to PC scores, Back-Project, and Reshape for x-/y-coordinates
        tshp = pcaSmooth(tshp, pdx, pdy);
        
        switch v
            case 1
                % Condense each iteration
                fprintf('.');
            case 2
                % Each iteration
                fprintf('DONE [%.02f sec]...\n', toc(tt));
        end
    end
    
    % Store each iteration's contour and close it
    Simg{itr} = [tshp ; tshp(1,:)];
    
    switch v
        case 1
            % Condense each iteration           
            fprintf('o');
        case 2
            % Each iteration
            fprintf('%s\nFinished iteration %d! [%.02f sec]\n%s\n', ...
                sprB, itr, toc(tItr), sprA);
    end
end

% ---------------------------------------------------------------------------- %
%% Predicted contour is the final iteration
Cntr        = Simg{itr};
Znrms.final = contour2corestructure(Cntr, LEN, STP); % Get Z-Vector of prediction

switch v
    case 1
        % Condense each iteration
        fprintf('|\n');
    case 2
        % Each iteration
        fprintf('\n%s\nDone predicting image from %d iterations! [%.02f sec]\n%s\n', ...
            sprB, nItrs, toc(tCrv), sprB);
end

end

function tshp = pcaSmooth(tshp, pdx, pdy)
%% Use PCA to smooth
% Convert to PC scores, Back-Project, and Reshape for x-/y-coordinates
tx   = squeeze((tshp(:,1)))';
preX = pcaProject(tx,   pdx.EigVecs, pdx.MeanVals, 'sim2scr');
preX = pcaProject(preX, pdx.EigVecs, pdx.MeanVals, 'scr2sim')';

ty   = squeeze((tshp(:,2)))';
preY = pcaProject(ty,   pdy.EigVecs, pdy.MeanVals, 'sim2scr');
preY = pcaProject(preY, pdy.EigVecs, pdy.MeanVals, 'scr2sim')';

tshp = [preX , preY];

end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
% Need descriptions for all these parameters
% pcaX, pcaY, dim2chg, mns, eigs, scrs, pc2chg, upFn, dwnFn, stp, f

p = inputParser;
p.addParameter('LEN', 25);
p.addParameter('STP', 1);
p.addParameter('DVIS', false);
p.addParameter('toRemove', 1);
p.addParameter('zoomLvl', []);
p.addParameter('foldPredictions', 1);
p.addParameter('lastFrmFold', 1);
p.addParameter('rot', 0);
p.addParameter('split2stitch', 0);
p.addParameter('addMid', 0);
p.addParameter('uLen', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
