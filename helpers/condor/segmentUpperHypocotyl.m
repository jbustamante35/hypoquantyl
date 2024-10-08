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
%   out: segmentation results structure
%       info: metadata about input image
%       init: results from initial guess
%       opt: results from optimization
%       err: error structure
%       isgood: success (1) or error (0) from upper-lower segmentation
%

try
    %% Parse inputs
    args = parseInputs(varargin);
    for fn = fieldnames(args)'
        feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
    end

    % Convert Network to MyNN
    ndclass = class(Nd.N1);
    fprintf('\n\nEvaluating D-Vector Network Model\nPre-Nd class == %s | ', ...
        ndclass);
    if strcmpi(ndclass, 'network')
        switch path2subs
            case 0
                % Generate new set
                fprintf('Converting to MyNN | ');
                Nd = MyNN.fromStruct(Nd);
            case 1
                % Or draw from stored versions
                fprintf('Substituting to MyNN from %s | ', ndclass);
                Nd = substituteNd(Nd, path2subs);
            case 2
                % Keep as network object
        end

        ndclass = class(Nd.N1);
    else
        fprintf('No changes needed | ');
    end
    fprintf('Nd class == %s\n\n', ndclass);

    % ------------------------------------------------------------------------ %
    %% Normalize by histogram if given
    if ~isempty(href)
        hhist = href.Data;
        hmth  = href.Tag;
        nbins = href.NumBins;
        img   = normalizeImageWithHistogram(img, hhist, hmth, nbins);
    end

    %% Evaluate 1st frame and get initial guess or force a direction
    tE = tic;
    fprintf('Evaluating direction | ');

    if isempty(toFlip)
        % Compare both grade for both directions
        [toFlip , eout , fout] = evaluateDirection(img, bpredict, zpredict, ...
            cpredict, mline, mscore, msample, seg_lengths, fidx, sav, vis);

        % Get initial guesses
        img   = eout.img;
        cinit = eout.cpre;
        minit = eout.mpre;
        zinit = eout.zpre;
        binit = eout.bpre;
        ginit = eout.gpre;
        hkeep = eout.keep;

        fprintf('DONE! - keep %s (score %.03f) [%.03f sec]\n\n', ...
            hkeep, ginit, toc(tE));
    else
        % Use defined direction
        hkeep = 'original';
        if toFlip
            img   = fliplr(img);
            hkeep = 'flipped';
        end

        [cinit , minit , zinit , binit] = predictFromImage(img, ...
            bpredict, zpredict, cpredict, mline, mscore);

        ginit = mscore(img, minit);
        fprintf('Forcing %s direction [%.03f sec]\n\n', hkeep, toc(tE));
    end

    % ------------------------------------------------------------------------ %
    %% Run Optimizer
    if nopts
        % Minimization of M-Patch PC scores
        t = tic;
        fprintf('\nOptimizing Z-Vector...');
        zopt = sopt(img);
        zopt = zcnv(zopt);

        [copt , mopt , zopt , bopt] = predictFromImage(img, ...
            bpredict, zpredict, cpredict, mline, zopt);

        % Grade optimized result
        gopt = mscore(img, mopt);

        fprintf(['DONE! [%.03f sec] | %d x %d | %d x %d | ' ...
            '%d x %d | %.02f -> %.02f |\n'], ...
            toc(t), size(copt), size(mopt), size(zopt), ginit, gopt);
    else
        % Just use initial guess as 'optimized'
        copt = cinit;
        mopt = minit;
        zopt = zinit;
        bopt = binit;
        gopt = ginit;
    end

    % ------------------------------------------------------------------------ %
    %% Flip Contour and Midline if using flipped image
    if toFlip
        % Flip Z-Vectors, Contours, Midlines
        %         sld   = seg_lengths(end) * scl;
        isz   = size(img,1);
        %         cflps = cellfun(@(x) flipAndSlide(x, seg_lengths, 0, scl), ...
        %             {cinit , copt, fout.cpre}, 'UniformOutput', 0);
        cflps = cellfun(@(x) flipAndSlide(x, seg_lengths, isz), ...
            {cinit , copt, fout.cpre}, 'UniformOutput', 0);
        mflps = cellfun(@(x) flipLine(x, isz), ...
            {minit , mopt, fout.mpre}, 'UniformOutput', 0);
        zflps = cellfun(@(x) contour2corestructure(x), ...
            cflps, 'UniformOutput', 0);
        bflps = cellfun(@(x) flipLine(x, isz), ...
            {binit , bopt, fout.bpre}, 'UniformOutput', 0);

        % Replace re-flipped curves
        zinit = zflps{1};
        cinit = cflps{1};
        minit = mflps{1};
        binit = bflps{1};
        zopt  = zflps{2};
        copt  = cflps{2};
        mopt  = mflps{2};
        bopt  = bflps{2};

        fout.zpre  = zflps{3};
        fout.cpre  = cflps{3};
        fout.mpre  = mflps{3};
        fout.bpre  = bflps{3};
    end

    % ------------------------------------------------------------------------ %
    %% Output if good
    init   = struct('z', zinit, 'c', cinit, 'm', minit, 'b', binit, 'g', ginit); % Initial Guesses
    opt    = struct('z', zopt,  'c', copt,  'm', mopt,  'b', bopt,  'g', gopt);  % Optimized
    err    = [];
    isgood = true;

    % Return flipped results
    if keepBoth
        flp = struct('z', fout.zpre, 'c', fout.cpre, 'm', ...
            fout.mpre, 'b', fout.bpre, 'g', fout.gpre);
    else
        flp = [];
    end
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

    % Make flipped just so no errors
    if isempty(find(strcmp('flp', aa), 1))
        flp = struct('z', [],  'c', [],  'm', [],  'b', [],  'g', []);
    end

    isgood = false;
    fprintf(2, '\n%s\n\n', err.getReport);
end

%% Output
info = struct('GenotypeName', GenotypeName, 'GenotypeIndex', GenotypeIndex, ...
    'SeedlingIndex', SeedlingIndex, 'Frame', Frame, 'toFlip', toFlip);
out  = struct('info', info, 'init', init, 'opt', opt, 'flp', flp, ...
    'err', err, 'isgood', isgood);

if sav
    if ~isfolder(ddir); mkdir(ddir); end
    outnm = sprintf('%s/%s_results_upper', ddir, tdate);
    save(outnm, '-v7.3', 'out');
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Model Options
p.addOptional('pz', 'pz');
p.addOptional('pdp', 'pdp');
p.addOptional('pdx', 'pdx');
p.addOptional('pdy', 'pdy');
p.addOptional('pdw', 'pdw');
p.addOptional('pm', 'pm');
p.addOptional('Nz', 'znnout');
p.addOptional('Nd', 'dnnout');
p.addOptional('Nb', 'bnnout');

% Optimization Options
p.addOptional('ncycs', 1);
p.addOptional('nopts', 100);
p.addOptional('mbuf', 0);
p.addOptional('scl', 1);
p.addOptional('toFlip', []);
p.addOptional('keepBoth', 0);

% Segmentation Function Handles
p.addOptional('bpredict', []);
p.addOptional('zpredict', []);
p.addOptional('cpredict', []);
p.addOptional('mline', []);
p.addOptional('mscore', []);
p.addOptional('sopt', []);
p.addOptional('msample', []);

% Segmentation Function Options
p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);
p.addOptional('ymin', 10);
p.addOptional('bwid', 0.5);
p.addOptional('psz', 20);
p.addOptional('npxy', []);
p.addOptional('npw', []);
p.addOptional('toFix', 0);
p.addOptional('tolfun', 1e-4);
p.addOptional('tolx', 1e-4);
p.addOptional('z2c', 0);
p.addOptional('myShps', [2 , 3 , 4]);
p.addOptional('zoomLvl', [0.5 , 1.5]);
p.addOptional('mpts', 50);
p.addOptional('mmth', 'nate');
p.addOptional('mparams', [5 , 3 , 0.1]);

% Miscellaneous Options
p.addOptional('href', []);
p.addOptional('path2subs', 0);
p.addOptional('fidx', 0);
p.addOptional('par', 0);
p.addOptional('vis', 0);
p.addOptional('sav', 0);
p.addOptional('ddir', 'output');

% Information Options
p.addOptional('GenotypeName', 'genotype');
p.addOptional('GenotypeIndex', 0);
p.addOptional('SeedlingIndex', 0);
p.addOptional('Frame', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
