function P = hypocotylSegmenter(hyp, ht, pm, nopts, seg_lengths, toFix, bwid, psz, sav, par, vis)
%% hypocotylSegmenter:
%
%
% Usage:
%   P = hypocotylSegmenter(hyp, ht, pm, seg_lengths, ...
%       toFix, bwid, psz, sav, par, vis)
%
% Input:
%
%
% Output:
%
%

%% Defaults
if nargin < 4; nopts       = 0;                   end
if nargin < 5; seg_lengths = [53 , 52 , 53 , 51]; end
if nargin < 6; toFix       = 0;                   end
if nargin < 7; bwid        = 0.5;                 end
if nargin < 8; psz         = 20;                  end
if nargin < 9; sav         = 0;                   end
if nargin < 10; par        = 0;                   end
if nargin < 11; vis        = 0;                   end

%% Make empty output structure
if isempty(hyp)
    flds      = {'zpre' , 'cpre' , 'mpre' , 'spre' , ...
        'gpre' , 'rmc' , 'rml' , 'keepOrg'};
    flds{2,1} = [];
    P         = struct(flds{:});
    return;
end

%% Start!
tItr  = tic;
gnm   = hyp.GenotypeName;
hnm   = sprintf('%s_%s_%s', ...
    hyp.GenotypeName, hyp.SeedlingName, hyp.HypocotylName);
gdir  = sprintf('timecourse/%s/seedlings/%s', gnm, hnm);
ttlnm = fixtitle(hnm);

fprintf('Running pipeline with hypocotyl %s\n', hnm);

% ---------------------------------------------------------------------------- %
%% Get Functions
% [zpredict , cpredict , cpredict2 , mline , msample , mcnv , mgrade , sopt] = ...
%     getFunctions(ht, pm, seg_lengths, par, vis, toFix, bwid, psz, nopts);
[~ , ~ , zpredict , ~ , cpredict , mline , msample , mcnv , mgrade , sopt] = ...
    ht.getFunctions(seg_lengths, par, vis, toFix, bwid, psz, nopts);

[~ , ~ , ~ , ~, cpredict2 , ~ , ~ , ~ , ~ , ~] = ...
    ht.getFunctions(seg_lengths, 0, vis, toFix, bwid, psz, nopts);

% ---------------------------------------------------------------------------- %
%% Evaluate 1st frame
tE = tic;
fprintf('Evaluating first frames | ');

% Grab original and flipped images
fprintf('Grabbing original and flipped hypocotyl images...\n');
rorgs = hyp.getImage';
rflps = cellfun(@(x) fliplr(x), rorgs, 'UniformOutput', 0);

% Original
t = tic;
fprintf('Original | '); iorg = rorgs{1};
if nopts
    % With optimization [nopts iterations]
    fprintf('Contour (%d nopt)| ', nopts); corg = sopt(iorg);
    fprintf('Z-Vector | ');                zorg = contour2corestructure(corg);
else
    % Use Initial Guess
    fprintf('Z-Vector | '); zorg = zpredict(iorg,0);
    fprintf('Contour | ');  corg = cpredict(iorg, zorg);
end
fprintf('Midline | ');               morg = mline(corg);
fprintf('Sampling Midline | ');      porg = msample(iorg, morg);
fprintf('Grading Midline Patch | '); gorg = mgrade(mcnv(porg));
eorg = EvaluatorJB('Trace', corg, 'SegmentLengths', seg_lengths);
dorg = eorg.getDirection;
fprintf('DONE! [%.03f sec]\n', toc(t));

% Flipped
t = tic;
fprintf('Flipped | '); iflp = rflps{1};
if nopts
    % With optimization [nopts iterations]
    fprintf('Contour (%d nopt)| ', nopts); cflp = sopt(iflp);
    fprintf('Z-Vector | ');                zflp = contour2corestructure(cflp);
else
    fprintf('Z-Vector | '); zflp = zpredict(iflp, 0);
    fprintf('Contour | ');  cflp = cpredict(iflp, zflp);
end
fprintf('Midline | ');               mflp = mline(cflp);
fprintf('Sampling Midline | ');      pflp = msample(iflp, mflp);
fprintf('Grading Midline Patch | '); gflp = mgrade(mcnv(pflp));
eflp = EvaluatorJB('Trace', cflp, 'SegmentLengths', seg_lengths);
dflp = eflp.getDirection;
fprintf('DONE! [%.03f sec]\n', toc(t));

% ---------------------------------------------------------------------------- %
%% Check 1st frames for original and flipped
fidx = 1;
fprintf('Showing 1st frame evaluation on figure %d...', fidx);

% Original
figclr(fidx);
subplot(121);
myimagesc(iorg);
hold on;
plt(zorg(:,1:2), 'y.', 2);
plt(corg, 'g-', 2);
plt(morg, 'r--', 2);
ttl = sprintf('Frame 1 [Original]\nDirection (%s) | [p %.03f]', dorg, gorg);
title(ttl, 'FontSize', 10);

% Flipped
subplot(122);
myimagesc(iflp);
hold on;
plt(zflp(:,1:2), 'y.', 2);
plt(cflp, 'g-', 2);
plt(mflp, 'r--', 2);
ttl = sprintf('Frame 1 [Flipped]\nDirection (%s) | [p %.03f]', dflp, gflp);
title(ttl, 'FontSize', 10);

fnms{fidx} = sprintf('%s_hypocotylpredictions_originalvsflipped_%scurve', ...
    tdate, dorg);

if sav
    tS = tic;
    fprintf('Saving figure %d...', fidx);
    odm = sprintf('%s/original_vs_flipped', gdir);
    saveFiguresJB(fidx, fnms(fidx), odm);
    fprintf('DONE! [%.03f sec]\n', toc(tS));
end

% ---------------------------------------------------------------------------- %
%% Evaluate Direction [get left-facing]
t = tic;
fprintf('Evaluating Directions of first frames...');

keepOrg = 1;
if ~isequal(dorg, dflp)
    % Make sure they didn't determine the same direction
    if strcmpi(dorg, 'right')
        % Flip if original is right-facing
        keepOrg = 0;
    end
else
    % Direction somehow gave same result
    if gorg >= gflp
        % Get lowest probabilty score [most probable]
        keepOrg = 0;
    end
end

% Keep original or use flipped based on evaluation
if keepOrg
    himgs = rorgs;
    hkeep = 'right';
else
    himgs = rflps;
    hkeep = 'left';
end

nimgs = numel(himgs);

fprintf('Original [%s] | Flipped [%s] | Keep [%s] | %.03f sec\n', ...
    dorg, dflp, hkeep, toc(t));

fprintf('FINISHED EVALUATING FIRST FRAME [%.03f sec]\n\n', toc(tE));

% ---------------------------------------------------------------------------- %
%% Run images through whole pipeline
tR = tic;
fprintf('Running %d %s-facing images through pipeline\n', nimgs, hkeep);

[zp , cp , mp , sp , gp] = deal(cell(nimgs,1));
parfor frm = 1 : nimgs
    t = tic;
    fprintf('Predicting %s curve [frame %02d of %02d]...', dorg, frm, nimgs);
    himg = himgs{frm};
    if nopts
        % With optimization (nopts iterations)
        fprintf('Contour (%d iterations)| ', nopts); cp{frm} = sopt(himg);
        fprintf('Generating Z-Vector | ');           zp{frm} = contour2corestructure(cp{frm});
    else
        % Use initial guess
        fprintf('Predicting Z-Vector | '); zp{frm} = zpredict(himg, 0);
        fprintf('Contour | ');             cp{frm} = cpredict2(himg, zp{frm});
    end
    fprintf('Generating Midline | ');    mp{frm} = mline(cp{frm});
    fprintf('Sampling Midline | ');      sp{frm} = msample(himg, mp{frm});
    fprintf('Grading Midline Patch | '); gp{frm} = mgrade(mcnv(sp{frm}));
    fprintf('DONE! [%.03f sec]\n', toc(t));
end

gpres = cat(1, gp{:});

fprintf('FINISHED RUNNING THROUGH PIPELINE [%.03f sec]\n\n', toc(tR));

% ---------------------------------------------------------------------------- %
%% Check results
fidx1 = 2;
fidx2 = 3;
fidx3 = 4;
tC = tic;
fprintf('Saving Predictions, Midline Patches, and Probabilities in figure %d, %d, %d...\n', ...
    fidx1, fidx2, fidx3);

for frm = 1 : nimgs
    %
    himg = himgs{frm};
    zpre = zp{frm};
    cpre = cp{frm};
    mpre = mp{frm};
    spre = sp{frm};
    gpre = gp{frm};

    % Predictions
    figclr(fidx1);
    myimagesc(himg);
    hold on;
    plt(zpre(:,1:2), 'y.', 2);
    plt(cpre, 'g-', 2);
    plt(mpre, 'r--', 2);
    ttl = sprintf('%s\n[%s] | Original [%s]\nFrame %d of %d', ...
        ttlnm, hkeep, dorg, frm, nimgs);
    title(ttl, 'FontSize', 10);

    fnms{fidx1} = sprintf('%s_predictions_timecourse_%s_frame%02dof%02d', ...
        tdate, hnm, frm, nimgs);

    % Midline Patches
    figclr(fidx2);
    myimagesc(spre);
    ttl = sprintf('Midline Patch [p %.03f]\nFrame %d of %d', gpre, frm, nimgs);
    title(ttl, 'FontSize', 10);

    fnms{fidx2} = sprintf('%s_midlinepatches_timecourse_%s_frame%02dof%02d', ...
        tdate, hnm, frm, nimgs);

    % Probabilities through Frames
    figclr(fidx3);
    plt(gpres, 'k-', 2);
    ttl = sprintf('Curve [%d Frames]\nMidline Patch Probability', nimgs);
    title(ttl, 'FontSize', 10);

    fnms{fidx3} = sprintf('%s_probabilities_timecourse_%s_%dframes', ...
        tdate, hnm, nimgs);

    if sav
        t = tic;
        fprintf('Saving Frame %02d of %02d...', frm, nimgs);
        nm1 = sprintf('%s/predictions', gdir);
        nm2 = sprintf('%s/midlinepatches', gdir);
        saveFiguresJB(fidx1, fnms(fidx1), nm1);
        saveFiguresJB(fidx2, fnms(fidx2), nm2);
        saveFiguresJB(fidx3, fnms(fidx3), gdir);
        fprintf('DONE! [%.03f sec]\n', toc(t));
    else
        pause(0.3);
    end
end

% ---------------------------------------------------------------------------- %
%% When complete, flip back to original direction
t = tic;
if ~keepOrg
    % Flip contour and midline to match original direction
    fprintf('Flipping back to original direction...');
    hc = cellfun(@(x) flipAndSlide(x, seg_lengths), cp, 'UniformOutput', 0);
    hm = cellfun(@(x) flipLine(x, seg_lengths(end)), mp, 'UniformOutput', 0);
else
    fprintf('Keepin images in original direction...');
    hc = cp;
    hm = mp;
end

fprintf('DONE! [%.03f sec]\n', toc(t));
fprintf('FINISHED SAVING FIGURES [%.03f sec]\n\n', toc(tC));

% ---------------------------------------------------------------------------- %
%% Remap original results to full-res images
tM = tic;
fprintf('Remapping %s to full resolution image\n', hnm);
[rmc , rml, rmi] = deal(cell(nimgs, 1));
for frm = 1 : nimgs
    t = tic;
    fprintf('Remapping %s [frame %02d of %02d]...', hnm, frm, nimgs);
    [rmc{frm} , rml{frm} , rmi{frm}] = thumb2full(hyp, frm, hc{frm}, hm{frm});
    fprintf('DONE! [%.03f sec]\n', toc(t));
end

% ---------------------------------------------------------------------------- %
%% Play full res results
fidx = 4;
tP   = tic;
fprintf('Showing %s remap on figure %d\n', hnm, fidx);

for frm = 1 : nimgs
    figclr(fidx);
    myimagesc(rmi{frm}.gimg);
    hold on;
    plt(rmc{frm}, 'g-', 2);
    plt(rml{frm}, 'r--', 2);

    ttl = sprintf('Full-Res Remap [frame %d of %d]\n%s', frm, nimgs, ttlnm);
    title(ttl, 'FontSize', 10);

    fnms{fidx} = sprintf('%s_remap_timecourse_%s_frame%02dof%02d', ...
        tdate, hnm, frm, nimgs);

    if sav
        tS = tic;
        fprintf('Saving Frame %02d of %02d...', frm, nimgs);
        tnm = sprintf('%s/remap', gdir);
        saveFiguresJB(fidx, fnms(fidx), tnm);
        fprintf('DONE! [%.03f sec]\n', toc(tS));
    else
        pause(0.2);
    end
end

fprintf('DONE! [%.03f sec]\n', toc(tP));
fprintf('FINISHED REMAP [%.03f sec]\n\n', toc(tM));

% ---------------------------------------------------------------------------- %
%% Place Results in Struct
flds = {'zpre' , 'cpre' , 'mpre' , 'spre' , 'gpre' , 'rmc' , 'rml' , 'keepOrg'};
dats = {zp , cp , mp , sp , gpres , rmc , rml , keepOrg};
P    = cell2struct(dats', flds');

fprintf('FINISHED FULL PIPELINE for %s [%.03f sec]\n\n', hnm, toc(tItr));

end

% function [zpredict , cpredict , cpredict2 , mline , msample , mcnv , mgrade , sopt] = getFunctions(ht, pm, seg_lengths, par, vis, toFix, bwid, psz, nopts)
% %% getFunctions
% %
% %
%
% %%
% [pz , pdp , pdx , pdy , pdw , Nz , Nd] = loadHTNetworks(ht);
%
% %
% scrs  = pm.PCAScores;
% pvecs = pm.EigVecs;
% pmns  = pm.MeanVals;
%
% %
% zpredict  = @(i,r) predictZvectorFromImage(i, Nz, pz, r);
% cpredict  = @(i,zs) displacementWindowPredictor(i, 'Nz', Nz, 'pz', pz, 'Nd', Nd, ...
%     'pdp', pdp, 'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'z', zs, ...
%     'toFix', toFix, 'seg_lengths', seg_lengths, 'par', par, 'vis', vis);
% cpredict2  = @(i,zs) displacementWindowPredictor(i, 'Nz', Nz, 'pz', pz, 'Nd', Nd, ...
%     'pdp', pdp, 'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'z', zs, ...
%     'toFix', toFix, 'seg_lengths', seg_lengths, 'par', 0, 'vis', vis);
% mline     = @(c) nateMidline(c);
% msample   = @(i,m) sampleMidline(i, m, 0, psz, 'full');
% mcnv      = @(m) pcaProject(m(:)', pvecs, pmns, 'sim2scr');
% mgrade    = computeKSdensity(scrs, bwid);
%
% % Optimize with nopts iterations
% if nopts
%     sopt = @(i) segmentationOptimizer(i, 'Nz', Nz, 'pz', pz, 'Nd', Nd, ...
%         'pdp', pdp, 'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'pm', pm, ...
%         'toFix', toFix, 'seg_lengths', seg_lengths, 'bwid', bwid, ...
%         'nopts', nopts, 'par', par, 'vis', vis, 'z2c', 1);
% else
%     sopt = [];
% end
%
% %
% % zsegs = size(pdx.InputData, 2) - 1;
% % zvecs = pz.EigVecs;
% % zmns  = pz.MeanVals;
% %
% % zcnv      = @(x) zVectorProjection(x, zsegs, zvecs, zmns, 3);
% % mmaster   = @(i)@(z) mgrade(mcnv(msample(i,mline(cpredict(i,zcnv(z))))));
%
% end
