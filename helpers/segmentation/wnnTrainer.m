function [WIN, WOUT, fnms] = wnnTrainer(IMGS, CNTRS, nitrs, nsplt, eIdxs, NPW, NZP, NLAYERS, TRNFN, sav, vis, par)
%% wnnTrainer: training algorithm for displacement window learning method
% This is a description
%
% Usage:
%   [WIN, WOUT, fnms] = wnnTrainer(IMG, CNTR, ...
%       nitrs, nsplt, nfigs, NPW, NZP, NLAYERS, TRNFN, sav, vis, par)
%
% Input:
%   IMGS: cell array of images to be trained
%   CNTRS: cell array of contours to train from images
%   nitrs: total recursive interations to train D-Vectors (default 15)
%   nsplt: size of segments to split displacement windows (default 11)
%   nfigs: number of figures opened to show progress of training (default 4)
%   NPW: principal components for folding displacement windows (default 3)
%   NZP: principal components for sampling core patches (default 25)
%   NLAYERS: number of layers to use with fitnet (default 5)
%   TRNFN: training function fitnet (default 'trainlm')
%   sav: boolean to save output as .mat file (1 saves data , 2 saves figures)
%   vis: boolean to visualize output
%   par: boolean to run with parallelization or with single-thread
%
% Output:
%   WIN: input structure containing images, PC scores, and set indices
%   WOUT: output structure containing models and PCA data
%       net: cell array of trained network models for each iteration
%       evecs: cell array of eigenvectors for each iteration
%       mns: cell array of means for each iteration
%   fnms: cell array of file names for the figures generated
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%% Run the Algorithm!
% Misc setup
figs  = 1 : nfigs;
fnms  = cell(1, nfigs);
ncrvs = numel(IMGS);
sprA  = repmat('=', 1, 80);
sprB  = repmat('-', 1, 80);
% eIdxs = double(sort(Shuffle(ncrvs, 'index', numel(figs))));
midx  = round(nsplt / 2);
stp   = 1;

% Trained Neural Networks and Eigen Vectors for each iteration
[net, evecs, mns] = deal(cell(1, nitrs));

% Set up figures to check progress
if vis
    [~ , fnms] = makeBlankFigures(nfigs, 1);
end

%% Run the algorithm!
tAll = tic;
fprintf('\n%s\nRunning Displacement Window Method!\n%s\n', sprA, sprB);

for itr = 1 : nitrs
    titr = tic;
    fprintf('\n%s\nRunning iteration %d of %d\n%s\n', sprA, itr, nitrs, sprB);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Get Tangent Bundle, Displacement Vectors, and Frame Bundles
    t = tic;
    fprintf('Extracting data from %d Curves', ncrvs);
    
    if itr == 1
        [PTCHS , ZVECS , TRGS] = prepPatchesAndTargets_wvecs( ...
            IMGS, CNTRS, par, nsplt, stp);
    else
        [PTCHS , ZVECS] = prepPatchesAndTargets_wvecs( ...
            IMGS, CNTRS, par, nsplt, stp, wtrgs);
    end
    
    fprintf('...DONE! [%.02f sec]\n', toc(t));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Compute target displacements
    t = tic;
    fprintf('Computing target values for %d segments of %d curves...', ...
        size(TRGS,3), size(TRGS,4));
    
    [WVECS, wsz] = projectTargets(TRGS, ZVECS, 1);
    
    fprintf('DONE! [%.02f sec]\n', toc(t));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Run a fitnet to predict displacement vectors from scaled patches
    t = tic;
    fprintf('Using neural net to train %d targets...', size(PTCHS,1));
    
    % Parallelization doesn't seem to work sometimes
    [wpre , net{itr}, evecs{itr}, mns{itr}] = nn_wvectors( ...
        PTCHS, WVECS, par, NZP, NLAYERS, TRNFN, 0);
    
    fprintf('DONE! [%.02f sec]\n', toc(t));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Smooth predictions with PCA
    tt = tic;
    fprintf('Smoothing %d predictions with %d PCs...', ...
        size(TRGS,1), NPW);
    
    % Smooth X-/Y-Coordinates
    wx   = wpre(:, 1:nsplt);
    wy   = wpre(:, nsplt+1:nsplt*2);
    pwx  = myPCA(wx, NPW);
    pwy  = myPCA(wy, NPW);
    
    % Back-Project and Reshape
    wpre = [pwx.SimData , pwy.SimData];
    wpre = reshape(wpre, wsz);
    wpre = permute(wpre, [3 , 4 , 1 , 2]);
    
    fprintf('DONE! [%.02f sec]...', toc(tt));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Project displacements onto image frame
    t = tic;
    fprintf('Computing target values for %d segments of %d curves...', ...
        size(wpre,3), size(wpre,4));
    
    [wtrgs , tsz , WTRGS] = projectTargets(wpre, ZVECS);
    
    fprintf('DONE! [%.02f sec]\n', toc(t));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Show curves predicted at each iteration
    t = tic;
    if vis
        GT = permute(squeeze(TRGS(midx,:,:,:)), [2 , 1 , 3]);
        for fidx = figs
            idx = eIdxs(fidx);
            fprintf('Showing results from Iteration %d for Contour %d...\n', ...
                itr, idx);
            
            ct  = GT(:,:,idx);
            zs  = ZVECS(:,1:2,idx);
            cp  = wtrgs(:,:,idx);
            p2t = arrayfun(@(x) [cp(x,:) ; zs(x,:) ; ct(x,:)], ...
                1 : size(ct,1), 'UniformOutput', 0);
            
            % Iteratively show predicted d-vectors and tangent bundles
            figclr(fidx);
            myimagesc(IMGS{idx});
            hold on;
            plt(zs, 'r.', 10);
            plt(ct, 'g.', 10);
            plt(cp, 'y.', 10);
            cellfun(@(x) plt(x, 'w-', 1), p2t, 'UniformOutput', 0);
            
            ttl = sprintf('Target vs Predicted\nContour %d | Iteration %d', ...
                idx, itr);
            title(ttl, 'FontSize', 10);
            
            drawnow;
            
            if sav == 2
                fnms{fidx} = sprintf('%s_curve%03d_iteration%02dof%02d', ...
                    tdate, idx, itr, nitrs);
                ndir       = sprintf('displacementwindow_training/curve%03dof%03d', ...
                    idx, ncrvs);
                saveFiguresJB(fidx, fnms(fidx), 0, 'png', ndir);
            end
        end
    end
    
    % Done with the iteration
    fprintf('DONE! [%.02f sec]\n%s\n', toc(t), sprB);
    fprintf('Ran Iteration %d of %d: %.02f sec\n%s\n', ...
        itr, nitrs, toc(titr), sprA);
    
end

%% Store output
nstr = arrayfun(@(w) sprintf('N%d', w), 1 : nitrs, 'UniformOutput', 0)';
net  = cell2struct(net', nstr);

WIN           = struct('IMGS', IMGS, 'CNTRS', CNTRS);
WOUT.Net      = net;
WOUT.EigVecs  = evecs;
WOUT.MeanVals = mns;

fprintf('\n%s\nFull Run of %d Iterations: %.02f sec\n%s\n', ...
    sprA, nitrs, toc(tAll), sprA);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
if sav
    %% Data for predicting validation set
    % Need to save the neural networks, and what else?
    wnm = sprintf('%s_WVecsNN_%dIterations_%dCurves', tdate, nitrs, ncrvs);
    save(wnm, '-v7.3', 'WOUT');
    
end

end

