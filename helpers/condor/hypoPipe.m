function out = hypoPipe(img, varargin)
%% hypoPipe:
% Run image through entire Z-Vector to contour to midline with optimization
%
% Usage:
%   out = hypoPipe(img, varargin)
%
% Input:
%
%
% Output:
%
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

% Convert Network to MyNN
if strcmpi(class(Nd.N1), 'network')
    Nd = MyNN.fromStruct(Nd);
end

%% Function Handles
[bpredict , ~ , zpredict , zcnv, cpredict , mline , msample , mcnv , mgrade , ...
    sopt , ~] = loadSegmentationFunctions(pz , pdp , pdx , pdy , pdw , pm , ...
    Nz , Nd , Nb, 'seg_lengths', seg_lengths, 'toFix', toFix, 'bwid', bwid, ...
    'psz', psz, 'nopts', nopts, 'tolfun', tolfun, 'tolx', tolx, 'z2c', z2c, ...
    'par', par, 'vis', vis);

% ---------------------------------------------------------------------------- %
%% Evaluate 1st frame and get initial guess
tE = tic;
fprintf('Evaluating first frames | ');

[toFlip , eout , fnm] = evaluateDirection(iorg, bpredict, zpredict, ...
    cpredict, mline, msample, mcnv, mgrade, fidx, sav);

% Get initial guesses
img   = eout.img;
cinit = eout.cpre;
minit = eout.mpre;
zinit = eout.zpre;
binit = eout.bpre;
ginit = eout.gpre;
hkeep = eout.keep;

fprintf('Evaluated first frame - keep %s [%.03f sec]\n\n', toc(tE), hkeep);

% % Grab original and flipped images
% fprintf('Grabbing original and flipped hypocotyl image...\n');
% flp = fliplr(img);
%
% % Original
% t = tic;
% fprintf('Original | '); iorg = img;
% fprintf('Z-Vector | '); zorg = zpredict(iorg, 0);
% fprintf('B-Vector | '); zorg = bpredict(iorg, zorg, 1);
% fprintf('Contour | ');  corg = cpredict(iorg, zorg);
%
% fprintf('Midline | ');               morg = mline(corg);
% fprintf('Sampling Midline | ');      porg = msample(iorg, morg);
% fprintf('Grading Midline Patch | '); gorg = mgrade(mcnv(porg));
% eorg = EvaluatorJB('Trace', corg, 'SegmentLengths', seg_lengths);
% dorg = eorg.getDirection;
% fprintf('DONE! [%.03f sec]\n', toc(t));
%
% % Flipped
% t = tic;
% fprintf('Flipped | ');  iflp = flp;
% fprintf('Z-Vector | '); zflp = zpredict(iflp, 0);
% fprintf('B-Vector | '); zflp = bpredict(iflp, zflp, 1);
% fprintf('Contour | ');  cflp = cpredict(iflp, zflp);
%
% fprintf('Midline | ');               mflp = mline(cflp);
% fprintf('Sampling Midline | ');      pflp = msample(iflp, mflp);
% fprintf('Grading Midline Patch | '); gflp = mgrade(mcnv(pflp));
% eflp = EvaluatorJB('Trace', cflp, 'SegmentLengths', seg_lengths);
% dflp = eflp.getDirection;
% fprintf('DONE! [%.03f sec]\n', toc(t));
%
% %% Evaluate Direction [get left-facing]
% t = tic;
% fprintf('Evaluating Directions of first frames...');
%
% % Get lowest probabilty score [most probable]
% keepOrg = 1;
% if gorg >= gflp
%     keepOrg = 0;
% end
% % if ~isequal(dorg, dflp)
% %     % Make sure they didn't determine the same direction
% %     if strcmpi(dorg, 'right')
% %         % Flip if original is right-facing
% %         keepOrg = 0;
% %     end
% % else
% %     % Direction somehow gave same result
% %     if gorg >= gflp
% %         % Get lowest probabilty score [most probable]
% %         keepOrg = 0;
% %     end
% % end
%
% % Keep original or use flipped based on evaluation
% if keepOrg
%     hkeep = 'original';
% else
%     img   = flp;
%     hkeep = 'flipped';
% end
%
% fprintf('Original [%s] | Flipped [%s] | Keep [%s] | %.03f sec\n', ...
%     dorg, dflp, hkeep, toc(t));
%
% fprintf('FINISHED EVALUATING FIRST FRAME [%.03f sec]\n\n', toc(tE));

% ---------------------------------------------------------------------------- %
% %% Get initial guesses
% % Initial guess should be results from previous section, but let's just keep it
% % because I'm lazy and it only takes 20 seconds
% t = tic;
% fprintf('\n\nPredicting Z-Vector...');
% zinit = zpredict(img,0);  % 0 for Z-Vector
% fprintf('DONE! [%.03f sec] | %d x %d\n', toc(t), size(zinit));
%
% t = tic;
% fprintf('Predicting B-Vector to displace Z-Vector...');
% [binit , zinit] = bpredict(img, zinit, 0);
% fprintf('DONE! [%.03f sec] | %d x %d\n', toc(t), size(binit));
%
% t = tic;
% fprintf('Predicting contour...');
% cinit = cpredict(img, zinit);
% fprintf('DONE! [%.03f sec] | %d x %d\n', toc(t), size(cinit));
%
% t = tic;
% fprintf('Generating midline...');
% minit = mline(cinit);
% fprintf('DONE! [%.03f sec] | %d x %d\n\n', toc(t), size(minit));

% ---------------------------------------------------------------------------- %
%% Run Optimizer
[copt , mopt , zopt , bopt , gopt] = deal([]); % No optimization
if nopts
    % Minimization of M-Patch PC scores
    t = tic;
    fprintf('\nOptimizing Z-Vector...');
    zopt = sopt(img);
    zopt = zcnv(zopt);

    %     [bopt , zopt] = bpredict(img, zopt, 0);
    %
    %
    %     fprintf('DONE! [%.03f sec] | %d x %d\n', toc(t), size(zopt));
    %
    %     % Predict contour and midline from optimized Z-Vector
    %     t = tic;
    %     fprintf('Predicting optimized contour...');
    %     copt = cpredict(img, zopt);
    %     fprintf('DONE! [%.03f sec] | %d x %d\n', toc(t), size(copt));
    %
    %     t = tic;
    %     fprintf('Generating optimized midline...');
    %     mopt = mline(copt);
    %     fprintf('DONE! [%.03f sec] | %d x %d\n\n', toc(t), size(mopt));

    [copt , mopt , zopt , bopt] = predictFromImage(img, ...
        bpredict, zpredict, cpredict, mline, zopt);

    % Grade optimized result
    gopt = mgrade(mcnv(msample(img, mopt)));

    fprintf('DONE! [%.03f sec] | %d x %d | %d x %d | %d x %d | %.02f -> %.02f |\n', ...
        toc(t), size(copt), size(mopt), size(zopt), ginit, gopt);
end

% ---------------------------------------------------------------------------- %
%% Flip Contour and Midline if using flipped image
if toFlip
    % Flip Z-Vectors, Contours, Midlines
    cflps = cellfun(@(x) flipAndSlide(x, seg_lengths), ...
        {cinit , copt}, 'UniformOutput', 0);
    mflps = cellfun(@(x) flipLine(x, seg_lengths(end)), ...
        {minit , mopt}, 'UniformOutput', 0);
    zflps = cellfun(@(x) contour2corestructure(x), cflps, 'UniformOutput', 0);
    bflps = cellfun(@(x) flipLine(x, seg_lengths(end)), ...
        {binit , bopt}, 'UniformOutput', 0);

    % Replace re-flipped curves
    zinit = zflps{1};
    cinit = cflps{1};
    minit = mflps{1};
    binit = bflps{1};
    zopt  = zflps{2};
    copt  = cflps{2};
    mopt  = mflps{2};
    bopt  = bflps{2};
end

% ---------------------------------------------------------------------------- %
%% Output
init = struct('z', zinit, 'c', cinit, 'm', minit, 'b', binit, 'g', ginit); % Initial Guesses
opt  = struct('z', zopt,  'c', copt,  'm', mopt,  'b', bopt,  'g', gopt);  % Optimized
out  = struct('init', init, 'opt', opt);
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
% Required: ncycs
% Model: Nz, pz, Nd, pdp, pdx, pdy, pdw, pm, Nb, fmth, z, model_manifest
% Misc: par, vis
% Vis: fidx, cidx, ncrvs, splts, ctru, ztru, ptru, zoomLvl, toRemove

% Required
p = inputParser;
p.addOptional('ncycs', 1);

% Model Options
p.addOptional('Nz', 'znnout');
p.addOptional('Nd', 'dnnout');
p.addOptional('Nb', 'bnnout');
p.addOptional('pz', 'pz');
p.addOptional('pm', 'pm');
p.addOptional('pdp', 'pdp');
p.addOptional('pdx', 'pdx');
p.addOptional('pdy', 'pdy');
p.addOptional('pdw', 'pdw');
p.addOptional('fmth', 'local');
p.addOptional('z', []);
p.addOptional('model_manifest', {'dnnout' , 'pcadp' , 'pcadx' , ...
    'pcady' , 'pcadw' , 'znnout' , 'pz'});

% Optimization Options
p.addOptional('ymin', 10);
p.addOptional('bwid', 0.5);
p.addOptional('psz', 20);
p.addOptional('toFix', 0);
p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);

% Miscellaneous Options
p.addOptional('z2c', 0);
p.addOptional('nopts', 100);
p.addOptional('tolfun', 1e-4);
p.addOptional('tolx', 1e-4);
p.addOptional('z2c', 0);
p.addOptional('par', 0);
p.addOptional('vis', 0);

% Visualization Options
p.addParameter('fidx', 1);
p.addParameter('cidx', 1);
p.addParameter('ncrvs', 1);
p.addParameter('splts', []);
p.addParameter('ctru', [0 , 0]);
p.addParameter('ztru', [0 , 0]);
p.addParameter('ptru', [0 , 0]);
p.addParameter('zoomLvl', [0.5 , 1.5]);
p.addParameter('toRemove', 1);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
