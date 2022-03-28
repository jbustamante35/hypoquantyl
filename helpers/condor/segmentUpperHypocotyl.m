function out = segmentUpperHypocotyl(img, varargin)
%% segmentUpperHypocotyl: predict contour and midline with optimization
% For use with CONDOR
%
% Usage:
%   out = segmentUpperHypocotyl(img, varargin)
%
% Input:
%   img: grayscale image of uppper hypocotyl
%   varargin: various options
%       [ -- see below for full list of options -- ]
%
% Output:
%   info: metadata about input image
%   init: results from initial guess
%   opt: results from optimization
%

try
    %% Parse inputs
    args = parseInputs(varargin);
    for fn = fieldnames(args)'
        feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
    end

    % Convert Network to MyNN
    if strcmpi(class(Nd.N1), 'network')
        if path2subs
            % Or draw from stored versions
            Nd = substituteNd(Nd, path2subs);
        else
            % Generate new set
            Nd = MyNN.fromStruct(Nd);
        end
    end

    %% Function Handles
    [bpredict , ~ , zpredict , zcnv, cpredict , mline , msample , mcnv , mgrade , ...
        sopt , ~] = loadSegmentationFunctions(pz, pdp, pdx, pdy, pdw, pm, ...
        Nz, Nd, Nb, 'seg_lengths', seg_lengths, 'toFix', toFix, 'bwid', bwid, ...
        'psz', psz, 'nopts', nopts, 'tolfun', tolfun, 'tolx', tolx, 'z2c', z2c, ...
        'par', par, 'vis', vis);

    % ---------------------------------------------------------------------------- %
    %% Evaluate 1st frame and get initial guess
    tE = tic;
    fprintf('Evaluating first frames | ');

    [toFlip , eout] = evaluateDirection(img, bpredict, zpredict, ...
        cpredict, mline, msample, mcnv, mgrade, fidx, sav);

    % Get initial guesses
    img   = eout.img;
    cinit = eout.cpre;
    minit = eout.mpre;
    zinit = eout.zpre;
    binit = eout.bpre;
    ginit = eout.gpre;
    hkeep = eout.keep;

    fprintf('Evaluated first frame - keep %s [%.03f sec]\n\n', hkeep, toc(tE));

    % ---------------------------------------------------------------------------- %
    %% Run Optimizer
    %     [copt , mopt , zopt , bopt , gopt] = deal([]); % Empty if no optimization
    if nopts
        % Minimization of M-Patch PC scores
        t = tic;
        fprintf('\nOptimizing Z-Vector...');
        zopt = sopt(img);
        zopt = zcnv(zopt);

        [copt , mopt , zopt , bopt] = predictFromImage(img, ...
            bpredict, zpredict, cpredict, mline, zopt);

        % Grade optimized result
        gopt = mgrade(mcnv(msample(img, mopt)));

        fprintf('DONE! [%.03f sec] | %d x %d | %d x %d | %d x %d | %.02f -> %.02f |\n', ...
            toc(t), size(copt), size(mopt), size(zopt), ginit, gopt);
    else
        % Just use initial guess as 'optimized'
        copt = cinit;
        mopt = minit;
        zopt = zinit;
        bopt = binit;
        gopt = ginit;
    end

    % ---------------------------------------------------------------------------- %
    %% Flip Contour and Midline if using flipped image
    if toFlip
        % Flip Z-Vectors, Contours, Midlines
        cflps = cellfun(@(x) flipAndSlide(x, seg_lengths), ...
            {cinit , copt}, 'UniformOutput', 0);
        mflps = cellfun(@(x) flipLine(x, seg_lengths(end)), ...
            {minit , mopt}, 'UniformOutput', 0);
        zflps = cellfun(@(x) contour2corestructure(x), ...
            cflps, 'UniformOutput', 0);
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
    %% Output if good
    init   = struct('z', zinit, 'c', cinit, 'm', minit, 'b', binit, 'g', ginit); % Initial Guesses
    opt    = struct('z', zopt,  'c', copt,  'm', mopt,  'b', bopt,  'g', gopt);  % Optimized
    err    = [];
    isgood = true;
catch err
    %% If error
    aa = who;

    % Flip direction
    if isempty(find(strcmp('toFlip', aa), 1))
        toFlip = [];
    end

    % Use initial guess if it worked
    if isempty(find(strcmp('init', aa), 1))
        init = struct('z', [],  'c', [],  'm', [],  'b', [],  'g', []);
    end

    % Use optimized guess if it worked
    if isempty(find(strcmp('opt', aa), 1))
        opt = struct('z', [],  'c', [],  'm', [],  'b', [],  'g', []);
    end

    isgood = false;
    fprintf(2, '\n%s\n\n', err.getReport);
end

%% Output
info = struct('GenotypeName', GenotypeName, 'GenotypeIndex', GenotypeIndex, ...
    'SeedlingIndex', SeedlingIndex, 'Frame', Frame, 'toFlip', toFlip);
out  = struct('info', info, 'init', init, 'opt', opt, ...
    'err', err, 'isgood', isgood);

if sav
    mkdir('output');
    outnm = sprintf('output/%s_results_upper', tdate);
    save(outnm, '-v7.3', 'out');
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

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

% Optimization Options
p.addOptional('nopts', 100);
p.addOptional('ncycs', 1);
p.addOptional('bwid', 0.5);
p.addOptional('psz', 20);
p.addOptional('toFix', 0);
p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);

% Miscellaneous Options
p.addOptional('path2subs', 0);
p.addOptional('z2c', 0);
p.addOptional('tolfun', 1e-4);
p.addOptional('tolx', 1e-4);
p.addOptional('fidx', 0);
p.addOptional('par', 0);
p.addOptional('vis', 0);
p.addOptional('sav', 0);

% Information Options
p.addOptional('GenotypeName', 'genotype');
p.addOptional('GenotypeIndex', 0);
p.addOptional('SeedlingIndex', 0);
p.addOptional('Frame', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
