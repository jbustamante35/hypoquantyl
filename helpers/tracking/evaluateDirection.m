function [toFlip , eout , fnm] = evaluateDirection(img, bpredict, zpredict, cpredict, mline, msample, mcnv, mgrade, fidx, sav)
%% evaluateFirstFrame: check direction image is facing
%
%
% Usage:
%   [toFlip , eout , fnm] = evaluateDirection(img, bpredict, zpredict, ...
%       cpredict, mline, msample, mcnv, mgrade, fidx, sav)
%
% Input:
%   img:
%
% Output:
%   toFlip:
%   eout:
%   fnm:
%

% ---------------------------------------------------------------------------- %
if nargin < 9;  fidx = 0; end
if nargin < 10; sav  = 0; end

%% Evaluate 1st frame
tE = tic;
fprintf('EVALUATING DIRECTION OF IMAGE\n');

% Grab original and flipped images
iorg = img;
iflp = fliplr(iorg);

% Original
t = tic;
fprintf('Segmenting original direction | ');
[corg ,  morg , zorg , borg] = predictFromImage( ...
    iorg, bpredict, zpredict, cpredict, mline);

fprintf('Sampling Midline | ');
porg = msample(iorg, morg);

fprintf('Grading Midline Patch | ');
gorg = mgrade(mcnv(porg));

fprintf('DONE! [%.03f sec]\n', toc(t));

% Flipped
t = tic;
fprintf('Segmenting flipped direction | ');
[cflp ,  mflp , zflp , bflp] = predictFromImage( ...
    iflp, bpredict, zpredict, cpredict, mline);

fprintf('Sampling Midline | ');
pflp = msample(iflp, mflp);

fprintf('Grading Midline Patch | ');
gflp = mgrade(mcnv(pflp));

fprintf('DONE! [%.03f sec]\n', toc(t));

% ---------------------------------------------------------------------------- %
%% Evaluate Direction [get left-facing]
% Get lowest probabilty score [means most probable]
t = tic;
fprintf('Evaluating Direction...');

toFlip = gorg >= gflp;
if toFlip
    % Switch to flipped direction
    hkeep = 'flipped';
    eout  = struct('img', iflp, 'cpre', cflp, 'mpre', mflp, 'zpre', zflp, ...
        'bpre', bflp, 'ppre', pflp, 'gpre', gflp, 'keep', hkeep);
else
    % Keep original direction
    hkeep = 'original';
    eout  = struct('img', iorg, 'cpre', corg, 'mpre', morg, 'zpre', zorg, ...
        'bpre', borg, 'ppre', porg, 'gpre', gorg, 'keep', hkeep);
end

fprintf('Keep %s [%.03f sec]\n', hkeep, toc(t));

% ---------------------------------------------------------------------------- %
%% Check results
fnm = [];
if fidx
    fnm = showEvaluation(iorg, iflp, zorg, zflp, corg, cflp, morg, mflp, ...
        gorg, gflp, hkeep, fidx, sav);
end

fprintf('FINISHED EVALUATING DIRECTION - keep %s [%.03f sec]\n\n', ...
    hkeep, toc(tE));
end

function fnm = showEvaluation(iorg, iflp, zorg, zflp, corg, cflp, morg, mflp, gorg, gflp, hkeep, fidx, sav)
%% showEvaluation
tS = tic;
fprintf('Displaying evaluation on figure %d...', fidx);

% Original
figclr(fidx);
subplot(121);
myimagesc(iorg);
hold on;
plt(zorg(:,1:2), 'y.', 2);
plt(corg, 'g-', 2);
plt(morg, 'r--', 2);
ttl = sprintf('Original [p %.03f]', gorg);
title(ttl, 'FontSize', 10);

% Flipped
subplot(122);
myimagesc(iflp);
hold on;
plt(zflp(:,1:2), 'y.', 2);
plt(cflp, 'g-', 2);
plt(mflp, 'r--', 2);
ttl = sprintf('Flipped [p %.03f]', gflp);
title(ttl, 'FontSize', 10);

fnm = sprintf('%s_hypocotylpredictions_originalvsflipped_keep%s', tdate, hkeep);

if sav
    fprintf('Saving figure %d...', fidx);
    odm = 'direction_evaluation';
    saveFiguresJB(fidx, {fnm}, odm);
end

fprintf('DONE! [%.03f sec]\n', toc(tS));
end
