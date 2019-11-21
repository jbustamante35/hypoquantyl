function [DIN, DOUT, fnms] = dnnTrainer(IMG, CNTR, nItrs, nFigs, fldPreds, sav, vis, par)
%% dnnTrainer: training algorithm for recursive displacement learning method
% This is a description
%
% Usage:
%    [DIN, DOUT, fnms] = ...
%       dnnTrainer(IMG, CNTR, nItrs, nFigs, fldPreds, sav, vis, par)
%
% Input:
%   IMG: cell array of images to be trained
%   CNTR: cell array of contours to train from images
%   nItrs: total recursive interations to train D-Vectors
%   nFigs: number of figures opened to show progress of training
%   fldPreds: boolean to fold predictions after each iteration
%   sav: boolean to save output as .mat file
%   vis: boolean to visualize output
%   par: boolean to run with parallelization or with single-thread
%
% Output:
%   net: cell array of trained network models for each iteration
%   evecs: cell array of eigenvectors for each iteration
%   mns: cell array of means for each iteration
%   fnms: cell array of file names for the figures generated 
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%% Run the Algorithm!
% Misc setup
allFigs = 1 : nFigs;
fnms    = cell(1, nFigs);
numCrvs = numel(IMG);
sprA    = repmat('=', 1, 80);
sprB    = repmat('-', 1, 80);
eIdxs   = double(sort(Shuffle(numCrvs, 'index', numel(allFigs))));

% Trained Neural Networks and Eigen Vectors for each iteration
[net, evecs, mns] = deal(cell(1, nItrs));

% Principal Components for Scaled Patches and Smoothing Predictions
NPC = 10;

%% Set up figures to check progress
if vis
    for fIdx = allFigs
        set(0, 'CurrentFigure', allFigs(fIdx));
        cla;clf;
        
        idx = eIdxs(fIdx);
        myimagesc(IMG{idx});
        hold all;
        ttl = sprintf('Target vs Predicted\nContour %d', idx);
        title(ttl);
        drawnow;
        
        fnms{fIdx} = sprintf('%s_TargetVsPredicted_%dIterations_Contour%03d', ...
            tdate, nItrs, idx);
    end
else
    fnms = [];
end

%% Run the algorithm!
tAll = tic;
for itr = 1 : nItrs
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Get Tangent Bundle, Displacement Vectors, and Frame Bundles
    tItr = tic;
    fprintf('\n%s\nRunning iteration %d of %d\n%s\n', sprA, itr, nItrs, sprB);
    
    t = tic;
    fprintf('Extracting data from %d Curves', numCrvs);
    
    if itr == 1
        [X, Z, Y] = masterFunction2(IMG, CNTR, par);
        
    else
        [X, Z] = masterFunction2(IMG, CNTR, par, targetsPre);
    end
    
    fprintf('...DONE! [%.02f sec]\n', toc(t));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Compute target displacements
    t = tic;
    fprintf('Computing target values for %d segments of %d curves...', ...
        size(Y,1), size(Y,3));
    
    [targets, szY] = computeTargets(Y, Z, 1, par);
    
    fprintf('DONE! [%.02f sec]\n', toc(t));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Run a fitnet to predict displacement vectors from scaled patches
    t = tic;
    fprintf('Using neural net to train %d targets...', size(X,1));
    
    % Parallelization doesn't seem to work sometimes
    [Ypre , net{itr}, evecs{itr}, mns{itr}] = nn_dvectors(X, targets, szY, 0);
    
    fprintf('DONE! [%.02f sec]\n', toc(t));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Project displacements onto image frame
    t = tic;
    fprintf('Computing target values for %d segments of %d curves...', ...
        size(Ypre,1), size(Ypre,3));
    
    targetsPre = computeTargets(Ypre, Z, 0, par);
    
    if fldPreds
        %% Smooth predicted targets using PCA on predicted displacement vectors
        tt = tic;
        fprintf('Smoothing %d predictions with %d PCs...', ...
            size(targetsPre,1), NPC);
        
        % Run PCA on X-Coordinates
        tx  = squeeze((targetsPre(:,1,:)))';
        ptx = myPCA(tx, NPC);
        
        % Run PCA on Y-Coordinates
        ty  = squeeze((targetsPre(:,2,:)))';
        pty = myPCA(ty, NPC);
        
        % Back-Project and reshape
        preX       = reshape(ptx.SimData', [size(targetsPre,1) , 1 , numCrvs]);
        preY       = reshape(pty.SimData', [size(targetsPre,1) , 1 , numCrvs]);
        targetsPre = [preX , preY , ones(size(preX))];
        
        fprintf('DONE! [%.02f sec]...', toc(tt));
        
    end
    
    fprintf('DONE! [%.02f sec]\n', toc(t));
    
    %% Show iterative curves predicted
    t = tic;
    if vis
        for fIdx = allFigs
            set(0, 'CurrentFigure', allFigs(fIdx));
            fprintf('Showing results from Iteration %d for Contour %d...\n', ...
                itr, eIdxs(fIdx));
            % Iteratively show predicted d-vectors and tangent bundles
            idx = eIdxs(fIdx);
            imagesc(IMG{idx});
            colormap gray;
            axis image;
            axis off;
            hold on;
            
            % Show ground truth contour/displacement vector
            toplot = [Y(:,1:2,idx) ; Y(1,1:2,idx)];
            plt(toplot, 'g--', 2);
            
            % Show predicted displacement vector
            toplot = [targetsPre(:,1:2,idx) ; targetsPre(1,1:2,idx)];
            plt(toplot, 'y-', 2);
            
            % Show tangent bundle with tangents and normals pointing in direction
            toplot = [Z(:,:,idx) ; Z(1,:,idx)];
            qmag = 10;
            plt(toplot(:,1:2), 'm-', 2);
            quiver(toplot(:,1), toplot(:,2), toplot(:,3)*qmag, toplot(:,4)*qmag, ...
                'Color', 'r');
            quiver(toplot(:,1), toplot(:,2), toplot(:,5)*qmag, toplot(:,6)*qmag, ...
                'Color', 'b');
            hold off;
            
            ttl = sprintf('Target vs Predicted\nContour %d | Iteration %d', ...
                idx, itr);
            title(ttl);
            
            drawnow;
        end
    end
    % Done with the iteration
    fprintf('DONE! [%.02f sec]\n%s\n', toc(t), sprB);
    fprintf('Ran Iteration %d of %d: %.02f sec\n%s\n', ...
        itr, nItrs, toc(tItr), sprA);
    
end

% Store output
DIN  = struct('IMGS', IMG, 'CNTRS', CNTR);
DOUT = struct('Net', net, 'EigVecs', evecs, 'MeanVals', mns);

fprintf('\n%s\nFull Run of %d Iterations: %.02f sec\n%s\n', ...
    sprA, nItrs, toc(tAll), sprA);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
if sav
    %% Data for predicting validation set
    % Need to save the neural networks, and what else?
    TN  = struct('Net', net, 'EigVecs', evecs, 'MeanVals', mns);
    dnm = sprintf('%s_HQTrainedData_%dIterations_%dCurves', ...
        tdate, nItrs, numCrvs);
    save(dnm, '-v7.3', 'TN');
    
    %% PCA to fold predictions
    tx  = squeeze((targetsPre(:,1,:)))';
    xnm = sprintf('FoldDVectorX');
    pcaAnalysis(tx, NPC, sav, xnm, 0);
    
    % Run PCA on Y-Coordinates
    ty  = squeeze((targetsPre(:,2,:)))';
    ynm = sprintf('FoldDVectorY');
    pcaAnalysis(ty, NPC, sav, ynm, 0);
end
end


