function [Cntr, Znrms, Simg] = hypocotylPredictor(imgs, par, mth, px, py, pz, pp, Nz, Ns, zseed, psx, psy, v)
%% hypocotylPredictor: the two-step neural net to predict hypocotyl contours
% [ Describe how this works here ]
%
% [ Describe the 'svec' method ]
%
% [ Describe the 'dvec' method ]
%
% Note that the Ns input that contains the neural net model for predicting
% S-Vector PC scores when using the 'svec' method should be replaced by Nt, the
% neural net model for predicting D-Vector PC scores when the 'dvec' method is
% used. This allows more flexibility when selecting the different methods.
%
% Usage:
%   [Cntr, Znrms, Simg] = hypocotylPredictor(...
%       imgs, par, mth, px, py, pz, pp, Nz, Ns, z, psx, psy, v)
%
% Input:
%   imgs: grayscale image or cell array of hypocotyl images
%   par: boolean to run single thread (0) or with parallelization (1)
%   mth: predict with S-Vectors ('snn') or D-Vectors ('dnn')
%   Nz: neural net model for predicting Z-Vector PC scores from images
%   Ns: neural net model for predicting PC scores from Z-Vector slices [Ns = Nd]
%   px: X-Coordinate eigenvectors and means
%   py: Y-Coordinate eigenvectors and means
%   pz: Z-Vector eigenvectors and means
%   pp: Z-Patch eigenvectors and means
%   z: seed prediction with ground-truth Z-Vector (for D-Vector method)
%   v: booleon for verbosity (defaults to 0)
%
% Output:
%   Cntr: the continous contour generated from the segments
%   Znrms: Z-Vector predicted from the image
%   Simg: cell array of segments [svec] or iterative contours [dvec]

if nargin < 13
    v = 0;
end

try
    %% Select Algorithm
    switch mth
        case 'svec'
            %% Old method that predicts S-Vectors from predicted Z-Vectors
            if nargin < 4
                % Load required datasets unless given
                DATADIR = '/home/jbustamante/Dropbox/EdgarSpalding/labdata';
                MFILES  = 'development/HypoQuantyl/datasets/matfiles';
                ROOTDIR = sprintf('%s/%s', DATADIR, MFILES);
                PCADIR  = 'pca';
                NETOUT  = 'netout';
                
                % Load PCA data and neural net models
                [px, py, pz, pp, psx, psy, Nz, Ns] = ...
                    loadSVecNetworks(ROOTDIR, PCADIR, NETOUT);
                
            end
            
            % Run S-Vector Method
            [Cntr, Znrms, Simg] = ...
                runMethod1(imgs, par, px, py, pz, pp, psx, psy, Nz, Ns, v);
            
        case 'dvec'
            %% New method to recursively predict vector displacements from Z-Vector
            % You can replace method1 parameters with method2 parameters:
            %   Nt  --> Ns [NN for D-Vectors --> NN for S-Vectors]
            %   ptx --> px [PCA to fold X-Coordinates --> PCA for X-Coordinates]
            %   pty --> py [PCA to fold Y-Coordinates --> PCA for Y-Coordinates]
            %   ptp --> pp [PCA for scaled patches --> PCA for image patches]
            
            if nargin < 4
                % Load required datasets unless given
                DATADIR = '/home/jbustamante/Dropbox/EdgarSpalding/labdata';
                MFILES  = 'development/HypoQuantyl/datasets/matfiles';
                ROOTDIR = sprintf('%s/%s', DATADIR, MFILES);
                PCADIR  = 'pca';
                NETOUT  = 'netoutputs';
                
                % Load PCA data and neural net models
                % Note that Ns is actually Nd here
                [px, py, pz, pp, Nz, Ns] = ...
                    loadDVecNetworks(ROOTDIR, PCADIR, NETOUT);
                
            end
            
            % Run D-Vector Method
            % Note that Ns is actually Nd here
            [Cntr, Znrms, Simg] = ...
                runMethod2(imgs, par, px, py, pz, pp, Nz, Ns, zseed, v);
            
        otherwise
            fprintf('Method must be [''svec''|''dvec'']\n');
            [Simg, Znrms, Cntr] = deal([]);
    end
    
catch e
    fprintf(2, 'Error running hypocotylPredictor with method %d\n%s\n', ...
        mth, e.getReport);
    [Simg, Znrms, Cntr] = deal([]);
end

end

function [Cntr, Znrms, Simg] = runMethod2(imgs, par, pdx, pdy, pz, pdp, Nz, Nd, z, v)
%% runMethod2: predict Z-Vector then recursively predict displacement vector
%
%
% Usage:
%   [Cntr, Znrms, Simg] = runMethod2(imgs, par, pdx, pdy, pz, pdp, Nz, Nd, z, v)
%
% Input:
%   imgs: grayscale image or cell array of hypocotyl images
%   par: boolean to run single thread (0) or with parallelization (1)
%   pdx: X-Coordinate PCA from contour predictions
%   pdy: Y-Coordinate PCA from contour predictions
%   pz: Z-Vector PCA from segmented contours
%   pdp: Z-Patch PCA from image patches of various scales an domain shape/sizes
%   Nz: neural net model for predicting Z-Vector PC scores from images
%   Nd: neural net model for predicting D-Vectors from Z-Patch scores
%   z: initial Z-Vector to seed the initial predictions
%   v: boolean for verbosity level (0 or 1)
%
% Output:
%   Cntr: the contour predicted by this algorithm
%   Znrms: Z-Vector of the predicted contour
%   Simg: all iterations of predictions from Nd neural net model

%% Constants and Parameters
% Message string separators and
sptA = repmat('=', 1, 80);
sptB = repmat('-', 1, 80);

if iscell(imgs)
    numCrvs = numel(imgs);
else
    numCrvs = 1;
    I       = imgs;
    clear imgs;
    imgs{1} = I;
end

%%
tAll = tic;
fprintf('\n%s\nRunning Recursive Displacement Predictor on %d images...\n%s\n', ...
    sptA, numCrvs, sptB);

[Cntr, Znrms, Simg] = deal(cell(1, numCrvs));
allCrvs             = 1 : numCrvs;

if par
    %% Run with Parallelization
    % A parellel pool of 6 workers from a total of 12 (24 logical cores) was
    % safest on my remote server, and so I think for general purposes I'll
    % create a pool of (NumCores / 2)
    halfCores = ceil(feature('numcores') / 2);
    setupParpool(halfCores, 0);
    
    %% Run through with parallelization using half cores
    % Convert PCA object to struct because parfor loops do weird and unexpected
    % nonsense that I don't understand
    neigs = 0; % input of 0 defaults to all eigenvectors
    pdx   = struct('InputData', pdx.InputData, 'EigVecs', pdx.EigVecs(neigs), 'MeanVals', pdx.MeanVals);
    pdy   = struct('InputData', pdy.InputData, 'EigVecs', pdy.EigVecs(neigs), 'MeanVals', pdy.MeanVals);
    pz    = struct('InputData', pz.InputData,  'EigVecs', pz.EigVecs,         'MeanVals', pz.MeanVals);
    
    parfor cIdx = allCrvs
        if v
            t = tic;
            fprintf('\n%s\nPredicting segments for hypocotyl %d\n', sptB, cIdx);
        end
        
        img                                   = imgs{cIdx};
        [Cntr{cIdx}, Znrms{cIdx}, Simg{cIdx}] = recursiveDisplacementPredictor(...
            img, pdx, pdy, pz, pdp, Nz, Nd, z, v);
        
        if v
            fprintf('Finished with hypocotyl %d...[%.02f sec]\n%s\n', ...
                cIdx, toc(t), sptB);
        end
        
    end
    
else
    %% Run with single-thread
    for cIdx = allCrvs
        if v
            t = tic;
            fprintf('\n%s\nPredicting contour for hypocotyl %d\n', sptB, cIdx);
        end
        
        img                                   = imgs{cIdx};
        [Cntr{cIdx}, Znrms{cIdx}, Simg{cIdx}] = recursiveDisplacementPredictor(...
            img, pdx, pdy, pz, pdp, Nz, Nd, z, v);
        
        if v
            fprintf('Finished with hypocotyl %d...[%.02f sec]\n%s\n', ...
                cIdx, toc(t), sptB);
        end
        
    end
end

%
fprintf('Finished running recursive displacement predictor...[%.02f sec]\n%s\n', ...
    toc(tAll), sptA);

end

function [Cntr, Znrms, Simg] = runMethod1(imgs, par, px, py, pz, pp, psx, psy, Nz, Ns, v)
%% runMethod1: the two-step neural net to predict hypocotyl contours
% This function runs the full pipeline for the 2-step neural net algorithm that
% returns the x-/y-coordinate segments in the image reference frame from a given
% grayscale image of a hypocotyl. It uses two separate trained neural nets that
% first predicts the Z-Vector - or skeleton - of the hypocotyl from the inputted
% image, and then predicts the shape of the S-Vectors - or segments - that are
% formed from each point along the skeleton.
%
% The input can be a single image or a cell array of images. In the case of the
% cell array, this algorithm can be set with parallellization to run on multiple
% CPU cores.
%
% Z-Vector scores from image
% Generate dataset of Z-Vector Slices + Z-Patch PC Scores
% Iterative S-Vectors scores from Z-Vector Slices
% Predict S-Vector scores from Z-Vector slices
%
% Usage:
%   [Cntr, Znrms, Simg] = ...
%       runMethod1(imgs, par, px, py, pz, pp, psx, psy, Nz, Ns, v)
%
% Input:
%   imgs: grayscale image or cell array of hypocotyl images
%   par: boolean to run single thread (0) or with parallelization (1)
%   px: X-Coordinate eigenvectors and means
%   py: Y-Coordinate eigenvectors and means
%   pz: Z-Vector eigenvectors and means
%   pp: Z-Patch eigenvectors and means
%   psx: X-Coordinate eigenvectors and means for folding the final contour
%   psy: Y-Coordinate eigenvectors and means for folding the final contour
%   Nz: neural net model for predicting Z-Vector PC scores from images
%   Ns: neural net model for predicting S-Vector PC scores from Z-Vector slices
%   v: boolean for verbosity level (0 or 1)
%
% Output:
%   Cntr: the continous contour generated from the half-index of each segment
%   Znrms: Z-Vector predicted from the image [after predicting the contour]
%   Simg: cell array of segments predicted from the image
%

%% Prediction pipeline
tAll = tic;
sptA = repmat('=', 1, 80);
sptB = repmat('-', 1, 80);
if iscell(imgs)
    numCrvs = numel(imgs);
else
    numCrvs = 1;
    I       = imgs;
    clear imgs;
    imgs{1} = I;
end
fprintf('\n\n%s\nRunning 2-Step Neural Net on %d image(s)', sptA, numCrvs);

%%
[Cntr, Znrms, Simg] = deal(cell(1, numCrvs));
allCrvs             = 1 : numCrvs;

if par
    %% Run with Parallelization
    % A parellel pool of 6 workers from a total of 12 (24 logical cores) was
    % safest on my remote server, and so I think for general purposes I'll
    % create a pool of (NumCores / 2)
    halfCores = ceil(feature('numcores') / 2);
    setupParpool(halfCores, 0);
    
    % Run through with parallelization using half cores
    % Convert PCA object to struct because parfor loops do weird and unexpected
    % nonsense that I don't understand
    px   = struct('InputData', px.InputData,  'EigVecs', px.EigVecs,  'MeanVals', px.MeanVals);
    py   = struct('InputData', py.InputData,  'EigVecs', py.EigVecs,  'MeanVals', py.MeanVals);
    pz   = struct('InputData', pz.InputData,  'EigVecs', pz.EigVecs,  'MeanVals', pz.MeanVals);
    pp   = struct('InputData', pp.InputData,  'EigVecs', pp.EigVecs,  'MeanVals', pp.MeanVals);
    psx  = struct('InputData', psx.InputData, 'EigVecs', psx.EigVecs, 'MeanVals', psx.MeanVals);
    psy  = struct('InputData', psy.InputData, 'EigVecs', psy.EigVecs, 'MeanVals', psy.MeanVals);
    
    parfor cIdx = allCrvs
        if v
            t = tic;
            fprintf('\n%s\nPredicting segments for hypocotyl %d\n', sptB, cIdx);
        end
        
        img                                   = imgs{cIdx};
        [Cntr{cIdx}, Znrms{cIdx}, Simg{cIdx}] = ...
            twoStepNetPredictor(img, px, py, pz, pp, psx, psy, Nz, Ns, v);
        
        if v
            fprintf('Finished with hypocotyl %d...[%.02f sec]\n%s\n', ...
                cIdx, toc(t), sptB);
        end
        
    end
    
else
    %% Run with single-thread
    for cIdx = allCrvs
        if v
            t = tic;
            fprintf('\n%s\nPredicting segments for hypocotyl %d\n', sptB, cIdx);
        end
        
        img                                   = imgs{cIdx};
        [Cntr{cIdx}, Znrms{cIdx}, Simg{cIdx}] = ...
            twoStepNetPredictor(img, px, py, pz, pp, psx, psy, Nz, Ns, v);
        
        if v
            fprintf('Finished with hypocotyl %d...[%.02f sec]\n%s\n', ...
                cIdx, toc(t), sptB);
        end
        
    end
end

% Collapse
fprintf('Finished running 2-step neural net...[%.02f sec]\n%s\n', ...
    toc(tAll), sptA);

end

