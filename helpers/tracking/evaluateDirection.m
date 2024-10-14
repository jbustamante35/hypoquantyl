function [toFlip , eout , fout , fnm] = evaluateDirection(img, bpredict, zpredict, cpredict, mline, mscore, msample, seg_lengths, fidx, sav, v)
%% evaluateFirstFrame: check direction image is facing
%
%
% Usage:
%   [toFlip , eout , fout , fnm] = evaluateDirection(img, bpredict, ...
%       zpredict, cpredict, mline, mscore, msample, seg_lengths, fidx, sav, v)
%
%
% Input:
%   img:
%   bpredict:
%   zpredict:
%   cpredict:
%   mline:
%   mscore:
%   msample:
%   seg_lengths:
%   fidx:
%   sav:
%   v:
%
% Output:
%   toFlip:
%   eout:
%   fout:
%   fnm:

%%
if nargin < 8;  seg_lengths = [53 , 51 , 53 , 52]; end
if nargin < 9;  fidx        = 0;                   end
if nargin < 10; sav         = 0;                   end
if nargin < 11; v           = 0;                   end

%% Evaluate 1st frame
if v; tE = tic; fprintf('EVALUATING DIRECTION OF IMAGE\n'); end

% Grab original and flipped images
iorg = img;
iflp = fliplr(iorg);

% Original
t = tic;
try
    if v; fprintf('Segmenting original direction | '); end
    [corg ,  morg , zorg , borg , gorg] = predictFromImage( ...
        iorg, bpredict, zpredict, cpredict, mline, mscore);

    [~ , dorg] = getCurveDirection(corg, seg_lengths);
    if v; fprintf('%s | ', dorg); end

    if v; fprintf('Sampling Midline | '); end
    porg = msample(iorg, morg);

    if v; fprintf(' (%.03f) | DONE! [%.03f sec]\n', gorg, toc(t)); end
catch err
    [corg ,  morg , zorg , borg , porg] = deal([0 , 0]);
    gorg = Inf;
    dorg = '';
    if v; fprintf(2, [' [evaluateDirection] [%.03f] | ' ...
            'ERROR! [%.03f sec]\n%s\n'], gorg, toc(t), err.getReport); end
end

% ---------------------------------------------------------------------------- %
% Flipped
t = tic;
try
    if v; fprintf('Segmenting flipped direction | '); end
    [cflp ,  mflp , zflp , bflp , gflp] = predictFromImage( ...
        iflp, bpredict, zpredict, cpredict, mline, mscore);

    [~ , dflp] = getCurveDirection(cflp, seg_lengths);
    if v; fprintf('%s | ', dflp); end

    if v; fprintf('Sampling Midline | '); end
    pflp = msample(iflp, mflp);

    if v; fprintf(' (%.03f) | DONE! [%.03f sec]\n', gflp, toc(t)); end
catch err
    [cflp ,  mflp , zflp , bflp , pflp] = deal([0 , 0]);
    gflp = Inf;
    dflp = '';
    if v; fprintf(2, [' [evaluateDirection] [%.03f] | ' ...
            'ERROR! [%.03f sec]\n%s\n'], gflp, toc(t), err.getReport); end
end

% ---------------------------------------------------------------------------- %
%% Evaluate Direction [get left-facing]
% Get lowest probabilty score [means most probable]
if v; t = tic; fprintf('Evaluating Direction...'); end

toFlip = gorg >= gflp;
if toFlip
    % Switch to flipped direction
    hkeep = 'flipped';
    hflp  = 'original';
    eout  = struct('img', iflp, 'cpre', cflp, 'mpre', mflp, 'zpre', zflp, ...
        'bpre', bflp, 'ppre', pflp, 'gpre', gflp, 'drc', dflp, 'keep', hkeep);

    % Return both results
    fout = struct('img', iorg, 'cpre', corg, 'mpre', morg, 'zpre', zorg, ...
        'bpre', borg, 'ppre', porg, 'gpre', gorg, 'drc', dorg, 'keep', hflp);
else
    % Keep original direction
    hkeep = 'original';
    hflp  = 'flipped';
    eout  = struct('img', iorg, 'cpre', corg, 'mpre', morg, 'zpre', zorg, ...
        'bpre', borg, 'ppre', porg, 'gpre', gorg, 'drc', dorg, 'keep', hkeep);

    % Return both results
    fout = struct('img', iflp, 'cpre', cflp, 'mpre', mflp, 'zpre', zflp, ...
        'bpre', bflp, 'ppre', pflp, 'gpre', gflp, 'drc', dflp, 'keep', hflp);
end

if v; fprintf('Keep %s [%.03f sec]\n', hkeep, toc(t)); end

% ---------------------------------------------------------------------------- %
%% Check results
fnm = [];
if fidx
    fnm = showEvaluation(iorg, iflp, zorg, zflp, corg, cflp, morg, mflp, ...
        gorg, gflp, dorg, dflp, hkeep, fidx, sav, v);
end

if v; fprintf('FINISHED EVALUATING DIRECTION - keep %s [%.03f sec]\n\n', ...
        hkeep, toc(tE)); end
end

function fnm = showEvaluation(iorg, iflp, zorg, zflp, corg, cflp, morg, mflp, gorg, gflp, dorg, dflp, hkeep, fidx, sav, v)
%% showEvaluation
if v; tS = tic; fprintf('Displaying evaluation on figure %d...', fidx); end

% Original
figclr(fidx);
subplot(121);
myimagesc(iorg);
hold on;
plt(zorg(:,1:2), 'y.', 2);
plt(corg, 'g-', 2);
plt(morg, 'r--', 2);
ttl = sprintf('Original - %s [p %.03f]', dorg, gorg);
title(ttl, 'FontSize', 10);

% Flipped
subplot(122);
myimagesc(iflp);
hold on;
plt(zflp(:,1:2), 'y.', 2);
plt(cflp, 'g-', 2);
plt(mflp, 'r--', 2);
ttl = sprintf('Flipped - %s [p %.03f]', dflp, gflp);
title(ttl, 'FontSize', 10);

drawnow;

fnm = pprintf(sprintf('%s_hypocotylpredictions_originalvsflipped_keep%s', ...
    tdate, hkeep));

if sav
    if v; fprintf('Saving figure %d...', fidx); end
    odm = 'direction_evaluation';
    saveFiguresJB(fidx, {fnm}, odm);
end

if v; fprintf('DONE! [%.03f sec]\n', toc(tS)); end
end
