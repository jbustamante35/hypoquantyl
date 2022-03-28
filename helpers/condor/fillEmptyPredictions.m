function pouts = fillEmptyPredictions(pouts, imgs, bpredict, zpredict, cpredict, mline, msample, mcnv, mgrade, seg_lengths, par)
%% fillEmptyPredictions: fix empty data after condor results
%
%
% Usage:
%   pouts = fillEmptyPredictions(pouts, imgs, bpredict, zpredict, cpredict, ...
%       mline, msample, mcnv, mgrade, seg_lengths, par)
%
% Input:
%   pouts: condor result structures [with fields for info, init, opt]
%   imgs: images to make initial predictions
%   bpredict: model to predict base point (B-Vector)
%   zpredict: model to predict contour structure (Z-Vector)
%   cpredict: model to predict contour (D-Vector)
%   mline: midline finding function (default nateMidline)
%   msample: function to sample image at midline
%   mcnv: convert sampled image to PC scores
%   mgrade: grade probability of sampled PC scores
%   seg_lengths: segment length for 4 contour regions [left|top|right|bottom]
%   par: with single thread (0) or parallel (1) [default 0]
%
% Output:
%   pouts: inputted structures with filled init field
%

%%
if nargin < 10; seg_lengths = [53 , 52 , 53 , 51]; end
if nargin < 11; par         = 0;                   end

[~ , sprA , sprB]                       = jprintf(' ', 0, 0, 80);
N                                       = numel(pouts);
[cpres , mpres , zpres , bpres , gpres] = deal(cell(N,1));

%%
tA = tic;
fprintf('\n%s\n\t\t\t\tFixing %d Condor Outputs\n%s\n', sprA, N, sprA);
if par; setupParpool(par); end

%% Make initial prediction
tP = tic;
fprintf('Predicting %d structures\n%s\n', N, sprB);
if par
    %% With parallelization
    parfor n = 1 : N
        tp = tic;
        fprintf('\t\t\t\t\tImage %02d of %02d\n%s\n', n, N, sprB);
        img = imgs{n};
        [cpres{n} , mpres{n} , zpres{n} , bpres{n} , flp] = ...
            doTheThing(img, bpredict, zpredict, cpredict, mline, ...
            msample, mcnv, mgrade, seg_lengths);
        fprintf('%s\n\t\t\tDONE [%.03f sec] | Flip %d\n%s\n', ...
            sprB, toc(tp), flp, sprB);
    end
else
    %%
    for n = 1 : N
        %
        tp = tic;
        fprintf('\t\t\t\t\tImage %02d of %02d\n%s\n', n, N, sprB);
        img = imgs{n};
        [cpres{n} , mpres{n} , zpres{n} , bpres{n} , flp] = ...
            doTheThing(img, bpredict, zpredict, cpredict, mline, ...
            msample, mcnv, mgrade, seg_lengths);
        fprintf('%s\n\t\t\tDONE [%.03f sec] | Flip %d\n%s\n', ...
            sprB, toc(tp), flp, sprB);
    end
end

fprintf('Predicted %d images! [%.03f sec]\n%s\n', N, toc(tP), sprA);

%% Fill empty init fields
tF = tic;
fprintf('Filling empty ''init'' fields for %d structures\n%s\n| ', N, sprB);
for n = 1 : N
    gpres{n}      = mgrade(mcnv(msample(imgs{n}, mpres{n})));
    pouts{n}.init = struct('z', zpres{n}, 'c', cpres{n}, ...
        'm', mpres{n}, 'b', bpres{n}, 'g', gpres{n});
    pouts{n}.opt  = pouts{n}.init;
    fprintf('%d | ', n);
end

fprintf('\n%s\nFilled %d structures! [%.03f sec]\n%s\n', ...
    sprB, N, toc(tF), sprB);

fprintf('\t\t\t\tDone Fixing %d Condor outputs! [%.03f sec]\n%s\n', ...
    N, toc(tA), sprA);
end

function [cpre , mpre , zpre , bpre , toFlip] = doTheThing(img, bpredict, zpredict, cpredict, mline, msample, mcnv, mgrade, seg_lengths)
%% doTheThing: does the thing this should do

% Determine if left or right facing by predicting both directions
[toFlip , eout] = evaluateDirection(img, bpredict, zpredict, cpredict, mline, ...
    msample, mcnv, mgrade);

% Extract results from best prediction
cpre = eout.cpre;
mpre = eout.mpre;
zpre = eout.zpre;
bpre = eout.bpre;

%
if toFlip
    cpre = flipAndSlide(cpre, seg_lengths);
    mpre = flipLine(mpre, seg_lengths(end));
    zpre = contour2corestructure(cpre);
    bpre = flipLine(bpre, seg_lengths(end));
end
end