function [ZIN, ZOUT , DIN, DOUT , SIN, SOUT] = hypoquantylTrainer(varargin)
%% hypoquantylTrainer: run contours through full set of training
% Combine training of Z-Vectors from images, D-Vectors, and S-Vectors from
% Z-Vector scores and slices in one neat pipeline.
%
% Usage:
%    [ZIN, ZOUT , DIN, DOUT , SIN, SOUT] = ...
%           hypoquantylTrainer(ex, sav, figs, par)
%
% Input:
%    ex: Experiment object to extract data from
%    sav: boolean to save output as .mat file
%    figs: figure indices to show D-Vector neural net iterations
%    par: boolean to run on a single-thread (0) or with parallelization (1)
%
% Output:
%    ZIN: image and contours inputted to train Z-Vectors
%    ZOUT: training index, predictions, and network models for Z-Vectors
%    DIN: Z-Vectors and contours inputted to train D-Vectors
%    DOUT: training index, vectors, and network models for D-Vectors
%    SIN: x-/y-coordinates inputted to train S-Vectors
%    SOUT: training index, predictions, and network models for S-Vectors
%
% Author Julian Bustamante <jbustamante@wisc.edu>

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Extract data and setup figures and constants
[~ , sprA , sprB] = jprintf('', 0, 0);

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
    sprA, exname, num2str(sav), num2str(figs), sprB);

% Figure indices
t = tic;
n = fprintf('Prep figures, Extract contours');
if ~isempty(figs)
    vis   = true;
    nfigs = numel(figs);
else
    vis   = false;
    nfigs = [];
end

% Information about the dataset
ttlSegs = C(1).NumberOfSegments;
numCrvs = numel(C);

n(2) = fprintf(' [%d contours , %d segments]', numCrvs, ttlSegs);
jprintf(' ', toc(t), 1, 80 - sum(n));

%% Split images and contours into training, validation, testing sets
% Validation and Testing sets shouldn't be seen by any training algorithms
t = tic;
n = fprintf('Splitting into training,validation,testing sets');

SPLTS = splitDataset(1 : numCrvs, trnPct, valPct, tstPct);
T     = C(SPLTS.trnIdx);
ntrn  = numel(T);
Timgs = arrayfun(@(x) double(x.getImage), T, 'UniformOutput', 0);
Tcntr = arrayfun(@(x) x.getTrace, T, 'UniformOutput', 0);

jprintf(' ', toc(t), 1, 80 - n);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Train Neural Net for Z-Vectors
% And re-do PCA on all data to get ground truth scores
[px, py, pz, pp] = hypoquantylPCA(T, sav, npx, npy, npz, nzp);
[ax, ay, az, ap] = hypoquantylPCA(C, sav, npx, npy, npz, nzp);

%% Run convolution neural net to train Z-Vector PC Scores and Images
% Get images and Z-Vector PC scores
Zimgs = cat(4, Timgs{:});
Zscrs = pz.PCAScores;

% Get validation data
V     = C(SPLTS.valIdx);
Vimgs = arrayfun(@(x) double(x.getImage), V, 'UniformOutput', 0);
Vimgs = cat(4, Vimgs{:});
Vscrs = az.PCAScores(SPLTS.valIdx);

[ZIN, ZOUT] = znnTrainer(Zimgs, Zscrs, SPLTS, 'Vimgs', Vimgs, 'Vscrs', Vscrs, ...
    'Save', sav, 'Parallel', par);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Train the D-Vectors
nitrs     = 15;
foldpreds = 1;

t = tic;
n = fprintf('Training D-Vectors through %d recursive iterations [Folding = %s]', ...
    nitrs, num2str(foldpreds));

[DIN, DOUT, fnms] = dnnTrainer( Timgs, Tcntr, nitrs, nfigs, ...
    foldpreds, npf, npc, dlayers, trnfn, sav, vis, par);

jprintf(' ', toc(t), 1, 80 - n);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Train the S-Vectors
t = tic;
n = fprintf('Prepping Z-Vector slices and S-Vector scores to train S-Vectors');

% Combine PC scores for X-/Y-Coordinates
SSCR = [px.PCAScores , py.PCAScores];

% Re-shape Z-Vectors to Z-Slices
ZSLC = zVectorConversion(pz.InputData, ttlSegs, ntrn, 'rev');
ZSLC = [ZSLC , addNormalVector(ZSLC)];

% Add Z-Patch PC scores to Z-Slice
ZSLC = [ZSLC , pp.PCAScores];

jprintf(' ', toc(t), 1, 80 - n);

%% Run Neural net to train S-Vector PC Scores from Z-Vector slices
t = tic;
n = fprintf('Training S-Vectors using %d-layer neural net', slayers);

[SIN, SOUT] = snnTrainer(SSCR, ZSLC, slayers, splts, sav, par);

jprintf(' ', toc(t), 1, 80 - n);

%% Done with pipeline
% Save figures
if sav
    tt = tic;
    n  = fprintf('Saving %d figures after D-Vector training', nfigs);
    
    saveFiguresJB(figs, fnms);
    
    jprintf(' ', toc(tt), 1, 80 - n);
    
    % Save Net Inputs
    t = tic;
    n = fprintf('Saving Net Inputs');
    
    znm = sprintf('%s_ZScoreCNN_Inputs_%dCurves_z%dPCs', tdate, numCrvs, pcz);
    dnm = sprintf('%s_DVectorNN_Inputs_%dHypocotyls', tdate, numCrvs);
    snm = sprintf('%s_SScoreNN_Inputs_%dHypocotyls', tdate, numCrvs);
    save(znm, '-v7.3', 'ZIN');
    save(dnm, '-v7.3', 'DIN');
    save(snm, '-v7.3', 'SIN');
    
    jprintf(' ', toc(t), 1, 80 - n);
end

fprintf('%s\nFinished training %d contours! [%.02f sec]\n%s\n', ...
    sprA, numel(trnIdx), toc(tAll), sprB);

end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
% Need descriptions for all these parameters
% pcaX, pcaY, dim2chg, mns, eigs, scrs, pc2chg, upFn, dwnFn, stp, f

p = inputParser;
p.addOptional('ex', Experiment); % Experiment containing Curves
p.addOptional('npx', 6);         % PCs for x-coordinates of S-Vectors
p.addOptional('npy', 6);         % PCs for y-coordinates of S-Vectors
p.addOptional('npz', 20);        % PCs for Z-Vectors
p.addOptional('nzp', 10);        % PCs for patches of Z-Vector slices
p.addOptional('npf', 10);        % PCs for folding D-Vectors
p.addOptional('npc', 10);        % PCs for sampling core patches (D-Vectors)
p.addOptional('dlayers', 5);    % Fitnet layers for D-Vectors
p.addOptional('slayers', 5);    % Fitnet layers for S-Vectors
p.addOptional('trnfn', 'trnlm'); % Training algorithm for D-Vector fitnet
p.addOptional('trnPct', 0.8);    % Percentage to split training data
p.addOptional('valPct', 0.1);    % Percentage to split validation data
p.addOptional('tstPct', 0.1);    % Percentage to split testing data
p.addOptional('sav', 0);         % Save all outputs into .mat files
p.addOptional('par', 0);         % Run with parallelization where applicable
p.addOptional('figs', 1 : 4);    % Figure handle indices to show results

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end