function showHypocotylPrediction(img, cntr, znrm, simg, idx, trnIdx, mth, sav, fIdxs)
%% showHypocotylPredictions: visualization to show 2-step neural net result
%
%
% Usage:
%   showHypocotylPrediction(img, znrms, simg, idx, trnIdx, f)
%
% Input:
%   img: image used for predictor
%   znrms: Z-Vector in raw form [1st neural net]
%   simg: cell array of S-Vectors in image reference frame [2nd neural net]
%   idx: index in dataset for title purposes
%   trnIdx: training set indices for title purposes
%   f: figure handle indices to plot onto
%
% Output: n/a
%

%% Check the results from two-step neural net
smth = 'svec';
dmth = 'dvec';

% Check set
if ismember(idx, trnIdx)
    cSet = 'training';
else
    cSet = 'validation';
end

% Scale tangent and normal vectors
SCL  = 3;
mid  = znrm(:,1:2);
tng  = znrm(:,3:4);
nrm  = znrm(:,5:6);

switch mth
    case smth
        tng  = (SCL * (tng - mid)) + mid;
        nrm  = (SCL * (nrm - mid)) + mid;
    case dmth
        tng  = (SCL * (tng)) + mid;
        nrm  = (SCL * (nrm)) + mid;
    otherwise
        fprintf(2, 'Method %s must be [%s|%s]\n', mth, smth, dmth);
        return;
end

ttng = arrayfun(@(x) [mid(x,:) ; tng(x,:)], 1:length(mid), 'UniformOutput', 0);
tnrm = arrayfun(@(x) [mid(x,:) ; nrm(x,:)], 1:length(mid), 'UniformOutput', 0);

%% Show Z-Vector and Contour
set(0, 'CurrentFigure', fIdxs(1));
cla;clf;

myimagesc(img);
hold on;
plt(mid, 'g.', 3);
cellfun(@(x) plt(x, 'r-', 1), ttng, 'UniformOutput', 0);
cellfun(@(x) plt(x, 'b-', 1), tnrm, 'UniformOutput', 0);
plt(cntr, 'g-', 2);
plt(cntr(1,:), 'r.', 10);

ttl = sprintf('Neural Net Prediction [%s Method]\nHypocotyl %d [%s set]', ...
    mth, idx, cSet);
title(ttl);

fnms{1} = sprintf('%s_%sMethodPrediction_Hypocotyl%d_%s', ...
    tdate, mth, idx, cSet);

%% Show individual segments or contours through each iteration
set(0, 'CurrentFigure', fIdxs(2));
cla;clf;

myimagesc(img);
hold on;
cellfun(@(x) plt(x, '-', 1), simg, 'UniformOutput', 0);

if strcmpi(mth, smth)    
    ttl = sprintf('%d Segments [%s Method]\nHypocotyl %d [%s set]', ...
        numel(simg), mth, idx, cSet);
    title(ttl);
    
    fnms{2} = sprintf('%s_%dSegments_%sMethod_Hypocotyl%d_%s', ...
        tdate, numel(simg), mth, idx, cSet);
else    
    ttl = sprintf('%d Iterations [%s Method]\nHypocotyl %d [%s set]', ...
        numel(simg), mth, idx, cSet);
    title(ttl);
    
    fnms{2} = sprintf('%s_%dIterations_%sMethod_Hypocotyl%d_%s', ...
        tdate, numel(simg), mth, idx, cSet);
end

%% Save figures as .fig and .tif images
if sav
    for fIdx = 1 : numel(fIdxs)
%         savefig(fIdxs(fIdx), fnms{fIdx});
        saveas(fIdxs(fIdx), fnms{fIdx}, 'tiffn');
    end
end

end

