function [Cntr, Znrms, Simg] = hypocotylPredictor(imgs, par, mth, px, py, pz, pp, Nz, Ns, z)
%% hypocotylPredictor: the two-step neural net to predict hypocotyl contours
%
% Usage:
%   [Cntr, Znrms, Simg] = hypocotylPredictor(imgs, par, mth, px, py, pz, pp, Nz, Ns, z)
%
% Input:
%   imgs: grayscale image or cell array of hypocotyl images
%   par: boolean to run single thread (0) or with parallelization (1)
%   Nz: neural net model for predicting Z-Vector PC scores from images
%   Ns: neural net model for predicting S-Vector PC scores from Z-Vector slices
%   px: X-Coordinate eigenvectors and means
%   py: Y-Coordinate eigenvectors and means
%   pz: Z-Vector eigenvectors and means
%   pp: Z-Patch eigenvectors and means
%
% Output:
%   Cntr: the continous contour generated from the segments [not implemented]
%   Znrms: Z-Vector predicted from the image
%   Simg: cell array of segments predicted from the image

%%
try
    switch mth
        case 1
            %% Old method that predicts S-Vectors from predicted Z-Vectors
            if nargin < 4
                % Load required datasets unless given
                DATADIR = '/home/jbustamante/Dropbox/EdgarSpalding/labdata';
                MFILES  = 'development/HypoQuantyl/datasets/matfiles';
                ROOTDIR = sprintf('%s/%s', DATADIR, MFILES);
                PCADIR  = 'pca';
                SIMDIR  = 'simulations';
                
                %
                [px, py, pz, pp, Nz, Ns] = ...
                    loadNetworkDatasets(ROOTDIR, PCADIR, SIMDIR);
                
            end
            
            %
            [Cntr, Znrms, Simg] = runMethod1(imgs, par, px, py, pz, pp, Nz, Ns);
            
        case 2
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
                SIMDIR  = 'simulations';
                TRNDIR  = 'training';
                
                %
                [px, py, pz, pp, Nz, Ns] = ...
                    loadZVecNetworks(ROOTDIR, PCADIR, SIMDIR, TRNDIR);
                
            end
            
            %
            [Cntr, Znrms, Simg] = runMethod2(imgs, par, px, py, pz, pp, Nz, Ns, z);
            
        otherwise
            fprintf('Method must be [1|2]\n');
            [Simg, Znrms, Cntr] = deal([]);
    end
    
catch e
    fprintf(2, 'Error running hypocotylPredictor with method %d\n%s\n', ...
        mth, e.getReport);
    [Simg, Znrms, Cntr] = deal([]);
end

end

function [Cntr, Znrms, Simg] = runMethod2(imgs, par, ptx, pty, pz, ptp, Nz, Nt, z)
%% runMethod2: predict Z-Vector then recursively predict displacement vector
%
%
%
%
%

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
    currCores = get(parcluster, 'NumWorkers');
    
    if isempty(gcp('nocreate'))
        % If no pool setup, create one
        fprintf('\nSetting up parallel pool with %d Workers...', halfCores);
        p  = parcluster;
        set(p, 'NumWorkers', halfCores);
        parpool(p);
        fprintf('DONE!\n');
        
    elseif halfCores < currCores
        % If current pool has > half cores, delete and setup with half cores
        fprintf('\nDeleting old pool of %d Workers and setting with %d Workers...', ...
            currCores, halfCores);
        delete(gcp);
        p  = parcluster;
        set(p, 'NumWorkers', halfCores);
        parpool(p);
        fprintf('DONE!\n');
        
    else
        % Pool with half cores already set up
        fprintf('\nParallel pool with %d Workers already set up!\n', halfCores);
        
    end
    
    % Run through with parallelization using half cores
    parfor cIdx = allCrvs
        t = tic;
        fprintf('\n%s\nPredicting segments for hypocotyl %d\n', sptB, cIdx);
        
        img                                   = imgs{cIdx};
        [Cntr{cIdx}, Znrms{cIdx}, Simg{cIdx}] = ...
            recursiveDisplacementPredictor(img, ptx, pty, pz, ptp, Nz, Nt, z);
        
        fprintf('Finished with hypocotyl %d...[%.02f sec]\n%s\n', ...
            cIdx, toc(t), sptB);
        
    end
    
else
    %% Run with single-thread
    for cIdx = allCrvs
        t = tic;
        fprintf('\n%s\nPredicting contour for hypocotyl %d\n', sptB, cIdx);
        
        img                                   = imgs{cIdx};
        [Cntr{cIdx}, Znrms{cIdx}, Simg{cIdx}] = ...
            recursiveDisplacementPredictor(img, ptx, pty, pz, ptp, Nz, Nt, z);
        
        fprintf('Finished with hypocotyl %d...[%.02f sec]\n%s\n', ...
            cIdx, toc(t), sptB);
        
    end
end

%
fprintf('Finished running recursive displacement predictor...[%.02f sec]\n%s\n', ...
    toc(tAll), sptA);

end

function [Cntr, Znrms, Simg] = runMethod1(imgs, par, px, py, pz, pp, Nz, Ns)
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
%   [Cntr, Znrms, Simg] = hypocotylPredictor(imgs, par, Nz, Ns, px, py, pz, pp)
%
% Input:
%   imgs: grayscale image or cell array of hypocotyl images
%   par: boolean to run single thread (0) or with parallelization (1)
%   Nz: neural net model for predicting Z-Vector PC scores from images
%   Ns: neural net model for predicting S-Vector PC scores from Z-Vector slices
%   px: X-Coordinate eigenvectors and means
%   py: Y-Coordinate eigenvectors and means
%   pz: Z-Vector eigenvectors and means
%   pp: Z-Patch eigenvectors and means
%
% Output:
%   Simg: cell array of segments predicted from the image
%   Znrms: Z-Vector predicted from the image
%   Cntr: the continous contour generated from the segments [not implemented]
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    currCores = get(parcluster, 'NumWorkers');
    
    if isempty(gcp('nocreate'))
        % If no pool setup, create one
        fprintf('\nSetting up parallel pool with %d Workers...', halfCores);
        p  = parcluster;
        set(p, 'NumWorkers', halfCores);
        parpool(p);
        fprintf('DONE!\n');
        
    elseif halfCores < currCores
        % If current pool has > half cores, delete and setup with half cores
        fprintf('\nDeleting old pool of %d Workers and setting with %d Workers...', ...
            currCores, halfCores);
        delete(gcp);
        p  = parcluster;
        set(p, 'NumWorkers', halfCores);
        parpool(p);
        fprintf('DONE!\n');
        
    else
        % Pool with half cores already set up
        fprintf('\nParallel pool with %d Workers already set up!\n', halfCores);
        
    end
    
    % Run through with parallelization using half cores
    parfor cIdx = allCrvs
        t = tic;
        fprintf('\n%s\nPredicting segments for hypocotyl %d\n', sptB, cIdx);
        
        img                                   = imgs{cIdx};
        [Cntr{cIdx}, Znrms{cIdx}, Simg{cIdx}] = ...
            twoStepNetPredictor(img, px, py, pz, pp, Nz, Ns);
        
        fprintf('Finished with hypocotyl %d...[%.02f sec]\n%s\n', ...
            cIdx, toc(t), sptB);
        
    end
    
else
    %% Run with single-thread
    for cIdx = allCrvs
        t = tic;
        fprintf('\n%s\nPredicting segments for hypocotyl %d\n', sptB, cIdx);
        
        img                                   = imgs{cIdx};
        [Cntr{cIdx}, Znrms{cIdx}, Simg{cIdx}] = ...
            twoStepNetPredictor(img, px, py, pz, pp, Nz, Ns);
        
        fprintf('Finished with hypocotyl %d...[%.02f sec]\n%s\n', ...
            cIdx, toc(t), sptB);
        
    end
end

% Collapse
fprintf('Finished running 2-step neural net...[%.02f sec]\n%s\n', ...
    toc(tAll), sptA);

end

