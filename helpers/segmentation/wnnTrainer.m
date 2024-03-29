function [WIN , WOUT , fnms] = wnnTrainer(IMGS, CNTRS, varargin)
%% wnnTrainer: training algorithm for displacement window learning method
% This is a description
%
% Usage:
%   [WIN , WOUT , fnms] = wnnTrainer(IMG, CNTR, varargin)
%
% Input:
%   IMGS: cell array of images to be trained
%   CNTRS: cell array of contours to train from images
%   varargin: various inputs for neural net [see below]
%
%       nitrs: total recursions to train D-Vectors (default 15)
%       nsplt: size of segments to split displacement windows (default 11)
%       nfigs: number of figures opened to show progress of training (default 4)
%       NPW: principal components for folding displacement windows (default 3)
%       NZP: principal components for sampling core patches (default 25)
%       NLAYERS: number of layers to use with fitnet (default 5)
%       TRNFN: training function fitnet (default 'trainlm')
%       Save: save output as .mat file (1 saves data , 2 saves figures)
%       Visualize: boolean to visualize output
%       Parallel: run on single-thread (0) or with parallelization (1)
%
% Output:
%   WIN: input structure containing images, PC scores, and set indices
%   WOUT: output structure containing models and PCA data
%       net: cell array of trained network models for each recursion
%       evecs: cell array of eigenvectors for each recursion
%       mns: cell array of means for each recursion
%   fnms: cell array of file names for the figures generated
%
% Author Julian Bustamante <jbustamante@wisc.edu>

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Misc setup
[~ , sprA , sprB] = jprintf(' ', 0, 0, 80);
ncrvs             = numel(IMGS);
if ~cidxs; cidxs  = pullRandom(1 : ncrvs, 4, 1); end %#ok<NODEF>

nfigs = numel(cidxs) + 1;
fnms  = cell(1, nfigs);
midx  = round(nsplt / 2);

% Trained Neural Networks and Eigen Vectors for each recursion
[net  , evecs , mns]  = deal(cell(1, nitrs));
[scls , doms  , dszs] = setupParams('myShps', myShps, 'zoomLvl', zoomLvl);

% Set up figures to check progress
if Visualize; [~ , fnms] = makeBlankFigures(nfigs, 1); end

%% Run the algorithm!
tAll = tic;
fprintf('\n%s\nRunning Displacement Window Method!\n%s\n', sprA, sprB);

for itr = 1 : nitrs
    titr = tic;
    fprintf('\n%s\nRunning recursion %d of %d\n%s\n', sprA, itr, nitrs, sprB);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Get Tangent Bundle, Displacement Vectors, and Frame Bundles
    t = tic;
    fprintf('Extracting data from %d Curves', ncrvs);

    if itr == 1
        [PTCHS , ZVECS , TRGS] = prepPatchesAndTargets_wvecs( ...
            IMGS, CNTRS, Parallel, nsplt, scls, doms, dszs);
    else
        [PTCHS , ZVECS] = prepPatchesAndTargets_wvecs( ...
            IMGS, CNTRS, Parallel, nsplt, scls, doms, dszs, wtrgs);
    end

    fprintf('...DONE! [%.02f sec]\n', toc(t));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Compute target displacements
    t = tic;
    fprintf('Computing target values for %d segments of %d curves...', ...
        size(TRGS,3), size(TRGS,4));

    [WVECS , wsz] = projectTargets(TRGS, ZVECS, 1);

    fprintf('DONE! [%.02f sec]\n', toc(t));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Run a fitnet to predict displacement vectors from scaled patches
    t = tic;
    fprintf('Using neural net to train %d targets...', size(PTCHS,1));

    % Parallelization doesn't seem to work sometimes
    [wpre , net{itr}, evecs{itr}, mns{itr}] = nn_wvectors( ...
        PTCHS , WVECS , Parallel, NZP, NLAYERS, TRNFN, 0);

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
    %% Show curves predicted at each recursion
    t = tic;
    if Visualize
        GT = permute(squeeze(TRGS(midx,:,:,:)), [2 , 1 , 3]);
        for fidx = 1 : numel(cidxs)
            idx = cidxs(fidx);
            fprintf('Showing results from Recursion %d for Contour %d...\n', ...
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

            ttl = sprintf('Target vs Predicted\nContour %d | Recursion %d', ...
                idx, itr);
            title(ttl, 'FontSize', 10);

            drawnow;
            fnms{fidx} = sprintf('%s_curve%03d_recursion%02dof%02d', ...
                tdate, idx, itr, nitrs);
        end

        if Save == 2
            ndir = sprintf('%s/wvector/recursions/%s', SaveDir, tdate);
            saveFiguresJB(1 : nfigs, fnms(1 : nfigs), ndir);
        end
    end

    % Done with the recursion
    fprintf('DONE! [%.02f sec]\n%s\n', toc(t), sprB);
    fprintf('Ran Recursion %d of %d: %.02f sec\n%s\n', ...
        itr, nitrs, toc(titr), sprA);
end

%% Store output
nstr = arrayfun(@(w) sprintf('N%d', w), 1 : nitrs, 'UniformOutput', 0)';
net  = cell2struct(net', nstr);

WIN           = struct('IMGS', IMGS, 'CNTRS', CNTRS);
WOUT.Net      = net;
WOUT.EigVecs  = evecs;
WOUT.MeanVals = mns;

fprintf('\n%s\nFull Run of %d Recursions: %.02f sec\n%s\n', ...
    sprA, nitrs, toc(tAll), sprA);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if Save
    %% Data for predicting validation set
    pdir = sprintf('%s/wvector', SaveDir);
    if ~isfolder(pdir); mkdir(pdir); pause(0.5); end
    wnm = sprintf('%s/%s_WVecsNN_%02dRecursions_%03dCurves', ...
        pdir, tdate, nitrs, ncrvs);
    save(wnm, '-v7.3', 'WOUT');
end
end

function args = parseInputs(varargin)
%% Parse input parameters
% nitrs, nsplt, cidxs, NPW, NZP, NLAYERS, TRNFN, Save, Visualize, Parallel)

p = inputParser;
p.addOptional('nitrs', 20);
p.addOptional('nsplt', 25);
p.addOptional('myShps', [2 , 3 , 4]);
p.addOptional('zoomLvl', [0.5 , 1.5]);
p.addOptional('cidxs', 0);
p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);
p.addOptional('NPW', [10 , 10 , 10]);
p.addOptional('NZP', 5);
p.addOptional('NLAYERS', 5);
p.addOptional('TRNFN', 'trainlm');
p.addOptional('Save', 0);
p.addOptional('SaveDir', pwd);
p.addOptional('Visualize', 0);
p.addOptional('Parallel', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
