function [DIN , DOUT , fnms] = dnnTrainer(IMGS, CNTRS, varargin)
%% dnnTrainer: training algorithm for recursive displacement learning method
% This is a description
%
% UPDATE [01-29-2021]
%   PCA folding now occurs BEFORE computing target D-Vectors, rather than after
%   computing them. This reduces the noise in input data that is fed to the
%   neural nets at each recursion.
%
%   The old method had D-Vectors folded AFTER being fed to the neural net, which
%   meant the input to these neural net models were jagged and noisy. The PCA
%   folding at the final recursion remains the same.
%
% Usage:
%   [DIN , DOUT , fnms] = dnnTrainer(IMGS, CNTRS, varargin)
%
% Input:
%   IMGS: cell array of images to be trained
%   CNTRS: cell array of contours to train from images
%   varargin: various inputs for neural net [see below]
%
%   Miscellaneous Inputs
%       nitrs: total recursive interations to train D-Vectors (default 20)
%       nsplt: size to set curve segsments from contours (default 25)
%       cidxs: data indices to show progress of training (default 0)
%       fmth: PCA smoothing method [whole|local|0] (default 'local')
%       toFix: straighten top and bottom sections (default 0)
%       seg_lengths: lengths of four sections (default [53 , 52 , 53 , 51])
%       NPF: PCs for local and whole smoothing (default [10 , 10 , 10])
%       NPD: PCs for sampling core patches (default 5)
%       NLAYERS: number of layers to use with fitnet (default 5)
%       TRNFN: training function fitnet (default 'trainlm')
%       Save: boolean to save output as .mat file (default 0)
%       SaveDir: location to save results (default pwd)
%       Visualize: boolean to visualize output (default 0)
%       Parallel: run with parallelization (1) or with single-thread (0)
%
% Output:
%   DIN:
%       IMGS: cell array of trained images
%       CNTRS: cell array of trained contours
%   DOUT:
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
fnms  = cell(nfigs, 1);

% Trained Neural Networks and Eigen Vectors for each recursion
[net  , evecs , mns]  = deal(cell(1, nitrs));
[scls , doms  , dszs] = setupParams('myShps', myShps, 'zoomLvl', zoomLvl);

% Set up figures to check progress
if Visualize; [~ , fnms] = makeBlankFigures(nfigs, 1); end

%% Run the algorithm!
tAll = tic;
for itr = 1 : nitrs
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Get Tangent Bundle, Displacement Vectors, and Frame Bundles
    tItr = tic;
    fprintf('\n%s\nRunning recursion %d of %d\n%s\n', sprA, itr, nitrs, sprB);

    t = tic;
    fprintf('Extracting data from %d Curves', ncrvs);
    if itr == 1
        %% Build initial image patches, Z-Vectors, and targets
        [PTCHS , ZVECS , TRGS] = prepPatchesAndTargets_dvecs( ...
            IMGS, CNTRS, Parallel, nsplt, scls, doms, dszs);

        % Build PC space for PCA smoothing
        [pdx , pdy] = deal([]);
        switch fmth
            case 'whole'
                %% PCA smoothing on collection of displacement vectors
                fprintf(['\nBuilding %d-dim PC space ' ...
                    'for whole smoothing...'], NPF(1));
                [~ , pdx , pdy] = wholeSmoothing(TRGS, NPF(1));
            case 'local'
                %% Local PCA smoothing on windows of displacement vectors
                fprintf(['\nBuilding %d-%d-%d-dim PC space ' ...
                    'for local smoothing...'], NPF);
                [~ , pdx , pdy] = wholeSmoothing(TRGS, NPF(1:2));
                [~ , pdw]       = localSmoothing(TRGS, nsplt, NPF(3));
            otherwise
                fprintf(2, 'No smoothing method selected [%s]...', fmth);
        end
    else
        %% Generate patches and Z-Vectors from previous recursion's predictions
        [PTCHS , ZVECS] = prepPatchesAndTargets_dvecs( ...
            IMGS, CNTRS, Parallel, nsplt, scls, doms, dszs, trgpre);
    end

    fprintf('...DONE! [%.02f sec]\n', toc(t));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Compute target displacements
    % Project contour points into displacement vector space
    t = tic;
    fprintf('Computing target values for %d segments of %d curves...', ...
        size(TRGS,1), size(TRGS,3));

    [DVECS , dsz] = computeTargets(TRGS, ZVECS, 1, Parallel);

    fprintf('DONE! [%.02f sec]\n', toc(t));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Run a fitnet to predict displacement vectors from scaled patches
    t = tic;
    fprintf('Using neural net to train %d targets...', size(PTCHS,1));

    [dpre , net{itr} , evecs{itr} , mns{itr}] = nn_dvectors( ...
        PTCHS, DVECS, dsz, Parallel, NPD, NLAYERS, TRNFN);

    fprintf('DONE! [%.02f sec]\n', toc(t));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Project displacements onto image frame
    t = tic;
    fprintf('Computing target values for %d segments of %d curves...', ...
        size(dpre,1), size(dpre,3));

    trgpre = computeTargets(dpre, ZVECS, 0, Parallel);

    switch fmth
        case 'whole'
            %% Re-fold after making predictions using the same eigenvectors
            % Back-up predicted targets for debugging
            fprintf('Smoothing whole prediction with %d PCs...', NPF(1));
            trgpre = wholeSmoothing(trgpre, [pdx , pdy]);
        case 'local'
            %% Local PCA smoothing on windows of displacement vectors
            fprintf('Local smoothing predictions with %d-%d-%d PCs...', NPF);
            trgpre = wholeSmoothing(trgpre, [pdx , pdy]);
            trgpre = localSmoothing(trgpre, nsplt, pdw);
        otherwise
            fprintf(2, 'No smoothing method selected [%s]...', fmth);
    end

    if toFix
        % Straighten top and bottom segments
        fprintf('Straightening top and bottom segments...');
        tmp        = arrayfun(@(x) straightenSegment(trgpre(:,1:2,x), ...
            seg_lengths, 1), 1 : ncrvs, 'UniformOutput', 0)';
        tmp        = cat(3, tmp{:});
        tmp(:,3,:) = 1;
        trgpre     = tmp;
    end

    fprintf('DONE! [%.02f sec]\n', toc(t));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Show iterative curves predicted
    t = tic;
    if Visualize
        if itr == 1; dv = DVECS(:,1:2); CM = cell(1, nitrs); end
        isz     = size(IMGS{1});
        CM{itr} = arrayfun(@(x) computeMatthewsCorellation( ...
            TRGS(:,1:2,x), trgpre(:,1:2,x), isz), (1 : ncrvs)');
        Z       = arrayfun(@(x) contour2corestructure( ...
            TRGS(:,1:2,x), nsplt), (1 : ncrvs)', 'UniformOutput', 0);
        Z       = cat(3, Z{:});
        DSHP    = arrayfun(@(x) computeTargets(trgpre(:,:,x), Z(:,:,x), ...
            1, Parallel), (1 : ncrvs)', 'UniformOutput', 0);
        DSHP    = cat(1, DSHP{:});
        DSHP    = DSHP(:,1:2);

        for fidx = 1 : numel(cidxs)
            idx = cidxs(fidx);
            fprintf(['Showing results from recursion %d ' ...
                'for Contour %d...\n'], itr, idx);

            ct = TRGS(:,1:2,idx);
            cp = trgpre(:,1:2,idx);
            cm = CM{itr}(idx);

            if itr == 1
                zm = ZVECS(:, 1 : 2, idx);
            else
                zm = Z(:, 1 : 2, idx);
            end

            cz = arrayfun(@(x) [zm(x,:) ; cp(x,:)], ...
                (1 : size(cp,1))', 'UniformOutput', 0);

            % Iteratively show predicted d-vectors and tangent bundles
            figclr(fidx);
            subplot(121);
            myimagesc(IMGS{idx});
            hold on;
            plt(zm, 'y-', 2);
            plt(ct, 'b-', 2);
            plt(cp, 'g-', 2);
            hold off;

            ttl = sprintf(['Target vs Predicted\nContour %d of %d | ' ...
                'MCC %.03f | Recursion %d of %d'], ...
                idx, ncrvs, cm, itr, nitrs);
            lgn = {'Z-Vector' , 'Ground Truth' , 'Predicted'};
            legend(lgn, 'FontSize', 10, 'Location', 'southeast');
            title(ttl);

            subplot(122);
            myimagesc(IMGS{idx});
            hold on;
            plt(zm, 'y.-', [10 , 1]);
            plt(cp, 'g.-', [10 , 1]);
            cellfun(@(x) plt(x, 'b-', 1), cz);
            hold off;

            ttl = sprintf(['Target vs Predicted\nContour %d of %d | ' ...
                'MCC %.03f | Recursion %d of %d'], ...
                idx, ncrvs, cm, itr, nitrs);
            lgn = {'Z-Vector' , 'Predicted' , 'Displacement'};
            legend(lgn, 'FontSize', 10, 'Location', 'southeast');
            title(ttl);

            drawnow;
            fnms{fidx} = sprintf('%s_curve%03d_recursion%02dof%02d', ...
                tdate, idx, itr, nitrs);
        end

        % Show D-Vector distribution
        figclr(nfigs);
        plt(dv, 'k.', 1);
        hold on;
        plt(DSHP, 'b.', 1);
        plt([0 , 0], 'g.', 20);
        xlabel('x-component', 'FontWeight', 'b');
        ylabel('y-component', 'FontWeight', 'b');
        ttl = sprintf(['D-Vector FitNet Results\n[%d Curves | %d Vectors | ' ...
            'Recursion %d of %d]'], ncrvs, size(DVECS,1), itr, nitrs);
        title(ttl, 'FontSize', 10);
        fnms{nfigs} = sprintf('%s_distribution_recursion%02dof%02d', ...
            tdate, itr, nitrs);

        % Save at each recursion
        if Save == 2
            ndir = sprintf('%s/dvector/recursions/%s', SaveDir, tdate);
            if itr == nitrs
                cm  = cat(2, CM{:})';
                ucm = mean(cm,2);

                figclr(nfigs+1);
                hold on;
                h = arrayfun(@(x) plt(cm(:,x), '-', 1), 1 : size(cm,2));
                arrayfun(@(x) set(x, 'Color', [x.Color(1:3) , 0.15]), h);
                arrayfun(@(x) set(x, 'MarkerEdgeColor', ...
                    [x.MarkerFaceColor(1:2) , 0.15]), h);
                plt(ucm, 'k.-', [20 , 3]);

                xticks(0 : 1 : nitrs);
                xlim([1 , nitrs]);

                xlabel('Recursion #', 'FontSize', 10, 'FontWeight', 'b');
                ylabel('MMC', 'FontSize', 10, 'FontWeight', 'b');
                ttl = sprintf(['D-Vector Accuracy\n' ...
                    '%d Curves through %d Recursions'], ncrvs, nitrs);
                title(ttl, 'FontSize', 10);

                drawnow;
                fnms{nfigs+1} = sprintf('%s_mcc_%02dcurves_%02drecursions', ...
                    tdate, numel(cidxs), nitrs);
                saveFiguresJB(1 : nfigs+1, fnms(1 : nfigs+1), ndir);
            else
                saveFiguresJB(1 : nfigs, fnms(1 : nfigs), ndir);
            end
        end
    end

    % Done with the recursion
    fprintf('DONE! [%.02f sec]\n%s\n', toc(t), sprB);
    fprintf('Ran recursion %d of %d: %.02f sec\n%s\n', ...
        itr, nitrs, toc(tItr), sprA);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Store output
DIN           = struct('IMGS', IMGS, 'CNTRS', CNTRS);
DOUT.Net      = net;
DOUT.EigVecs  = evecs;
DOUT.MeanVals = mns;

fprintf('\n%s\nFull Run of %d Recursions: %.02f sec\n%s\n', ...
    sprA, nitrs, toc(tAll), sprA);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PCA to fold final recursion of predictions
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

if Save
    %% Data for predicting validation set
    % Need to save the neural networks, eigenvectors, means, folding PCA
    DV  = struct('Net', net, 'EigVecs', evecs, 'MeanVals', mns, 'pdf', pdf);

    pdir = sprintf('%s/dvector', SaveDir);
    if ~isfolder(pdir); mkdir(pdir); pause(0.5); end
    dnm = sprintf('%s/%s_DVecsNN_%02dRecursions_%ssmoothing_%03dCurves', ...
        pdir, tdate, nitrs, fmth, ncrvs);
    save(dnm, '-v7.3', 'DV');
end
end

function args = parseInputs(varargin)
%% Parse input parameters

p = inputParser;
p.addOptional('nitrs', 20);
p.addOptional('nsplt', 25);
p.addOptional('myShps', [2 , 3 , 4]);
p.addOptional('zoomLvl', [0.5 , 1.5]);
p.addOptional('cidxs', 0);
p.addOptional('fmth', 'local');
p.addOptional('toFix', 0);
p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);
p.addOptional('NPF', [10 , 10 , 10]);
p.addOptional('NPD', 5);
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
