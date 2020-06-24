function [ZIN, ZOUT , DIN, DOUT , SIN, SOUT] = hypoquantylTrainer(ex, sav, fIdxs, par)
%% hypoquantylTrainer: run contours through full set of training
% Combine training of Z-Vectors from images, D-Vectors, and S-Vectors from
% Z-Vector scores and slices in one neat pipeline.
%
% Usage:
%    [ZIN, ZOUT , DIN, DOUT , SIN, SOUT] = ...
%           hypoquantylTrainer(ex, sav, fIdxs, par)
%
% Input:
%    ex: Experiment object to extract data from
%    sav: boolean to save output as .mat file
%    fIdxs: figure indices to show D-Vector neural net iterations
%    par: boolean to run on a single-thread (0) or with parallelization (1)
%
% Output:
%    OUT:
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%
%% Extract data and setup figures and constants
% Misc
sprA = repmat('-', 1, 80);
sprB = repmat('=', 1, 80);

% Check if input is Experiment class or Curve array
ex_class = class(ex);
switch ex_class
    case 'Experiment'
        exname = ex.ExperimentName;

        % Contours
        D = ex.combineContours;
        C = arrayfun(@(x) x.Curves, D, 'UniformOutput', 0);
        C = cat(1, C{:});

    case 'Curve'
        C      = ex;
        exname = C(1).Parent.ExperimentName;
    otherwise
        fprintf(2, 'Class of input %s not recognized [Experiment|Curve]\n', ...
            ex_class);
        return;
end

% Timer
tAll = tic;
fprintf('\n%s\nRunning %s through HypoQuantyl Trainer [Save = %s | Figures = %s]\n%s\n', ...
    sprB, exname, num2str(sav), num2str(fIdxs), sprA);

% Figure indices
t = tic;
fprintf('Setting up figures and extracting contours...');
if ~isempty(fIdxs)
    vis   = true;
    nFigs = numel(fIdxs);
else
    vis   = false;
    nFigs = [];
end

% Information about the dataset
ttlSegs = C(1).NumberOfSegments;
numCrvs = numel(C);

fprintf('Found %d contours of %d segments each...', numCrvs, ttlSegs);
fprintf('DONE! [%.02f sec]\n', toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Train Neural Net for Z-Vectors
t = tic;
fprintf('Running contours through PCA...');

% Increase number of PCs because this is getting frustrating
[px, py, pz, pp] = hypoquantylPCA(C, sav);

fprintf('DONE! [%.02f sec]\n%s\n', toc(t), sprA);

%% Get Images and Z-Vector PC Scores
pcz = pz.NumberOfPCs;

t = tic;
fprintf('Prepping Images and Contours for training %d Z-Vector PC scores...', ...
    pz.NumberOfPCs);

% Get images and Z-Vector PC scores
IMGS  = arrayfun(@(x) double(x.getImage), C, 'UniformOutput', 0);
ZMGS  = cat(4, IMGS{:});
ZSCRS = pz.PCAScores;

% Save inputs for the Z-Vector CNN
ZIN = struct('IMGS', ZMGS, 'ZSCRS', ZSCRS);
znm = sprintf('%s_ZScoreCNN_Inputs_%dCurves_z%dPCs', tdate, numCrvs, pcz);
save(znm, '-v7.3', 'ZIN');

fprintf('DONE! [%.02f sec]\n', toc(t));

%% Run convolution neural net to train Z-Vector PC Scores and Images
t = tic;
fprintf('Training Z-Vectors from Images...');

[ZIN, ZOUT] = znnTrainer(ZMGS, ZSCRS, sav, par);

fprintf('DONE! [%.02f sec]\n%s\n', toc(t), sprA);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Train the D-Vectors
t = tic;
fprintf('Prepping Images and Contours for recursive training of D-Vectors...');

% Save inputs for the D-Vector NN
CNTRS = arrayfun(@(x) x.getTrace, C, 'UniformOutput', 0);

% Save inputs for the D-Vector recursive NN
DIN = struct('IMGS', IMGS, 'CNTRS', CNTRS);
dnm = sprintf('%s_DVectorNN_Inputs_%dHypocotyls', tdate, numCrvs);
save(dnm, '-v7.3', 'DIN');

% Split the dataset
trnIdx = ZOUT.SplitSets.trnIdx;
IMG    = IMGS(trnIdx);
CNTR   = CNTRS(trnIdx);

fprintf('DONE! [%.02f sec]\n', toc(t));

%% Run neural net to train D-Vectors
nItrs    = 15;
fldPreds = true;

t = tic;
fprintf('Training D-Vectors through %d recursive iterations [Folding = %s]...', ...
    nItrs, num2str(fldPreds));

[DIN, DOUT, fnms] = ...
    dnnTrainer(IMG, CNTR, nItrs, nFigs, fldPreds, sav, vis, par);

%% Save figures
for fig = fIdxs
    tt = tic;
    fprintf('Saving %d figures after recursive D-Vector training...', nFigs);

    savefig(fIdxs(fig), fnms{fig});
    saveas(fIdxs(fig), fnms{fig}, 'tiffn');

    fprintf('DONE! [%.02f sec]\n', toc(tt));
end

fprintf('DONE! [%.02f sec]\n%s\n', toc(t), sprA);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Train the S-Vectors
t = tic;
fprintf('Prepping Z-Vector slices and S-Vector scores for training S-Vectors...');

% Combine PC scores for X-/Y-Coordinates
SSCR = [px.PCAScores , py.PCAScores];

% Re-shape Z-Vectors to Z-Slices
ZSLC = zVectorConversion(pz.InputData, ttlSegs, numCrvs, 'rev');
ZSLC = [ZSLC , addNormalVector(ZSLC)];

% Add Z-Patch PC scores to Z-Slice
ZSLC = [ZSLC , pp.PCAScores];

% Save inputs for the S-Vector NN
SIN = struct('SSCRS', SSCR, 'ZSLCS', ZSLC);
sin = sprintf('%s_SScoreNN_Inputs_%dHypocotyls', tdate, numCrvs);
save(sin, '-v7.3', 'SIN');

fprintf('DONE! [%.02f sec]\n', toc(t));

%% Run Neural net to train S-Vector PC Scores from Z-Vector slices
NLAYERS = 5;

t = tic;
fprintf('Training S-Vectors using %d-layer neural net...', NLAYERS);

%
[SIN, SOUT] = snnTrainer(SSCR, ZSLC, NLAYERS, sav, par);

fprintf('DONE! [%.02f sec]\n%s\n', toc(t), sprA);

%% Done with pipeline
fprintf('Finished training %d contours! [%.02f sec]\n%s\n', ...
    numel(trnIdx), toc(tAll), sprB);

end






