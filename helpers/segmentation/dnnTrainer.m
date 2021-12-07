function [DIN, DOUT, fnms] = dnnTrainer(IMGS, CNTRS, nitrs, nsplt, cidxs, fmth, toFix, seg_lengths, NPF, NPD, NLAYERS, TRNFN, sav, vis, par)
%% dnnTrainer: training algorithm for recursive displacement learning method
% This is a description
%
% UPDATE [01-29-2021]
%   PCA folding now occurs BEFORE computing target D-Vectors, rather than after
%   computing them. This reduces the noise in input data that is fed to the
%   neural nets at each iteration.
%
%   The old method had D-Vectors folded AFTER being fed to the neural net, which
%   meant the input to these neural net models were jagged and noisy. The PCA
%   folding at the final iteration remains the same.
%
% Usage:
%   [DIN, DOUT, fnms] = dnnTrainer(IMGS, CNTRS, ...
%       nitrs, nsplt, cidxs, fmth, toFix, seg_lengths, ...
%       NPF, NPD, NLAYERS, TRNFN, sav, vis, par)
%
% Input:
%   IMGS: cell array of images to be trained
%   CNTRS: cell array of contours to train from images
%   nitrs: total recursive interations to train D-Vectors
%   nsplt: size to set curve segsments from contours
%   cidxs: data indices to show progress of training
%   fmth: PCA smoothing method [whole|local|0] (default 'local')
%   toFix: straighten top and bottom sections
%   seg_lengths: lengths of sections
%   NPF: principal components to smooth predictions
%   NPD: principal components for sampling core patches (default 5)
%   NLAYERS: number of layers to use with fitnet (default 5)
%   TRNFN: training function fitnet (default 'trainlm')
%   sav: boolean to save output as .mat file
%   vis: boolean to visualize output
%   par: boolean to run with parallelization or with single-thread
%
% Output:
%   DIN:
%       IMGS: cell array of trained images
%       CNTRS: cell array of trained contours
%   DOUT:
%       net: cell array of trained network models for each iteration
%       evecs: cell array of eigenvectors for each iteration
%       mns: cell array of means for each iteration
%   fnms: cell array of file names for the figures generated
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%% Run the Algorithm!
% Misc setup
ncrvs = numel(IMGS);
sprA  = repmat('=', 1, 80);
sprB  = repmat('-', 1, 80);

if ~cidxs
    % Default to following 4 examples
    cidxs = pullRandom(1 : ncrvs, 4, 1);
end

nfigs = numel(cidxs);
fnms  = cell(1, nfigs);

% Trained Neural Networks and Eigen Vectors for each iteration
[net, evecs, mns] = deal(cell(1, nitrs));

% Get parameters for patch scaling and domain shapes and sizes
toRemove           = 1;
zoomLvl            = [0.5 , 1.5];
[scls, doms, dszs] = setupParams('toRemove', toRemove, 'zoomLvl', zoomLvl);

%% Set up figures to check progress
if vis
    [~ , fnms] = makeBlankFigures(nfigs, 1);
end

%% Run the algorithm!
tAll = tic;
for itr = 1 : nitrs
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Get Tangent Bundle, Displacement Vectors, and Frame Bundles
    tItr = tic;
    fprintf('\n%s\nRunning iteration %d of %d\n%s\n', sprA, itr, nitrs, sprB);
    
    t = tic;
    fprintf('Extracting data from %d Curves', ncrvs);
    
    if itr == 1
        %% Build initial image patches, Z-Vectors, and targets
        [PTCHS , ZVECS , TRGS] = prepPatchesAndTargets_dvecs( ...
            IMGS, CNTRS, par, nsplt, scls, doms, dszs);
        
        % Build PC space for PCA smoothing
        [pdx , pdy] = deal([]);
        switch fmth
            case 'whole'
                %% PCA smoothing on collection of displacement vectors
                fprintf('\nBuilding %d-dim PC space for whole contour...', NPF);
                [~ , pdx , pdy] = wholeSmoothing(TRGS, NPF);
                
            case 'local'
                %% Local PCA smoothing on windows of displacement vectors
                fprintf('\nBuilding %d-dim PC space for local smoothing...', NPF);
                [~ , pdx , pdy] = wholeSmoothing(TRGS, NPF);
                [~ , pdw]       = localSmoothing(TRGS, nsplt, NPF);
                
            otherwise
                fprintf(2, 'No smoothing method selected [%s]...', fmth);
        end
        
    else
        %% Generate patches and Z-Vectors from previous iteration's predictions
        [PTCHS , ZVECS] = prepPatchesAndTargets_dvecs( ...
            IMGS, CNTRS, par, nsplt, scls, doms, dszs, trgpre);
    end
    
    fprintf('...DONE! [%.02f sec]\n', toc(t));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Compute target displacements
    % Project contour points into displacement vector space
    t = tic;
    fprintf('Computing target values for %d segments of %d curves...', ...
        size(TRGS,1), size(TRGS,3));
    
    [DVECS, dsz] = computeTargets(TRGS, ZVECS, 1, toFix, seg_lengths, par);
    
    fprintf('DONE! [%.02f sec]\n', toc(t));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Run a fitnet to predict displacement vectors from scaled patches
    t = tic;
    fprintf('Using neural net to train %d targets...', size(PTCHS,1));
    
    [dpre , net{itr}, evecs{itr}, mns{itr}] = nn_dvectors( ...
        PTCHS, DVECS, dsz, par, NPD, NLAYERS, TRNFN);
    
    fprintf('DONE! [%.02f sec]\n', toc(t));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Project displacements onto image frame
    t = tic;
    fprintf('Computing target values for %d segments of %d curves...', ...
        size(dpre,1), size(dpre,3));
    
    trgpre = computeTargets(dpre, ZVECS, 0, toFix, seg_lengths, par);
    
    switch fmth
        case 'whole'
            %% Re-fold after making predictions using the same eigenvectors
            % Back-up predicted targets for debugging
            fprintf('Smoothing whole prediction with %d PCs...', NPF);
            trgpre = wholeSmoothing(trgpre, [pdx , pdy]);
            
        case 'local'
            %% Local PCA smoothing on windows of displacement vectors
            fprintf('Local smoothing predictions with %d PCs...', NPF);
            trgpre = wholeSmoothing(trgpre, [pdx , pdy]);
            trgpre = localSmoothing(trgpre, nsplt, pdw);
            
        otherwise
            fprintf(2, 'No smoothing method selected [%s]...', fmth);
    end
    
    fprintf('DONE! [%.02f sec]\n', toc(t));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Show iterative curves predicted
    t = tic;
    if vis
        for fidx = 1 : nfigs
            idx = cidxs(fidx);
            fprintf('Showing results from Iteration %d for Contour %d...\n', ...
                itr, idx);
            
            ct  = TRGS(:,1:2,idx);
            zs  = ZVECS(:,1:2,idx);
            cp  = trgpre(:,1:2,idx);
            
            % Iteratively show predicted d-vectors and tangent bundles
            figclr(fidx);
            myimagesc(IMGS{idx});
            hold on;
            plt(zs, 'mo', 3);
            plt(ct, 'g-', 2);
            plt(cp, 'y--', 2);
            
            ttl = sprintf('Target vs Predicted\nContour %d of %d | Iteration %d of %d', ...
                idx, ncrvs, itr, nitrs);
            lgn = {'Z-Vector' , 'Ground Truth' , 'Predicted'};
            legend(lgn, 'FontSize', 10, 'Location', 'southeast');
            title(ttl);
            
            drawnow;
            
            % Save at each iteration
            if sav == 2
                fnms{fidx} = sprintf('%s_curve%03d_iteration%02dof%02d', ...
                    tdate, idx, itr, nitrs);
                ndir       = sprintf('displacementvector_%smethod_training/curve%03dof%03d', ...
                    fmth, idx, ncrvs);
                saveFiguresJB(fidx, fnms(fidx), ndir);
            end
            
        end
    end
    
    % Done with the iteration
    fprintf('DONE! [%.02f sec]\n%s\n', toc(t), sprB);
    fprintf('Ran Iteration %d of %d: %.02f sec\n%s\n', ...
        itr, nitrs, toc(tItr), sprA);
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Store output
DIN           = struct('IMGS', IMGS, 'CNTRS', CNTRS);
DOUT.Net      = net;
DOUT.EigVecs  = evecs;
DOUT.MeanVals = mns;

fprintf('\n%s\nFull Run of %d Iterations: %.02f sec\n%s\n', ...
    sprA, nitrs, toc(tAll), sprA);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PCA to fold final iteration of predictions
switch fmth
    case 'whole'
        %% Whole contour smoothing
        pdx.setName('FoldDVectorX', 1);
        pdy.setName('FoldDVectorY', 1);
        pdf = struct('pdx', pdx, 'pdy', pdy);
        
    case 'local'
        %% Local window smoothing
        pdx.setName('FoldDVectorX', 1);
        pdy.setName('FoldDVectorY', 1);
        pdw.setName('FoldDVectorW', 1);
        
        pdf = struct('pdx', pdx, 'pdy', pdy, 'pdw', pdw);
        
    otherwise
        pdf = [];
end

DOUT.pdf = pdf;

if sav
    %% Data for predicting validation set
    % Need to save the neural networks, and what else?
    TN  = struct('Net', net, 'EigVecs', evecs, 'MeanVals', mns, 'pdf', pdf);
    dnm = sprintf('%s_DVecsNN_%dIterations_%ssmoothing_%dCurves', ...
        tdate, nitrs, fmth, ncrvs);
    save(dnm, '-v7.3', 'TN');
end

end
