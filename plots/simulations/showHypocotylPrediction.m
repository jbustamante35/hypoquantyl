function showHypocotylPrediction(img, znrms, simg, idx, trnIdx, f)
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
hlfIdx = ceil(length(simg{1}) / 2);
Shlf   = cell2mat(cellfun(@(x) x(hlfIdx,:), simg, 'UniformOutput', 0)');
Sext   = cellfun(@(x,y) [x(1,:) ; y(hlfIdx,:)], znrms, simg, 'UniformOutput', 0)';

% Check set
if ismember(idx, trnIdx)
    cSet = 'training';
else
    cSet = 'validation';
end

%%
% Scale tangent vector
scl = 5;
mid = hq(c).ZVectors(:,1:2);
tng = (scl * (hq(c).ZVectors(:,3:4) - mid)) + hq(c).ZVectors(:,1:2);

% Half Indices
hlfIdx = ceil(length(hq(c).SVectors{1}) / 2);
Shlf   = cell2mat(cellfun(@(x) x(hlfIdx,:), hq(c).SVectors, 'UniformOutput', 0)');

set(0, 'CurrentFigure', figs(fIdx));
cla;clf;

hold on;
imagesc(imgs{c});
colormap gray;
axis ij;
axis image;
cellfun(@(x) plt(x, '-', 1), hq(c).SVectors, 'UniformOutput', 0);
plt(hq(c).ZVectors, 'r.', 10);
arrayfun(@(x) plt([mid(x,:) ; tng(x,:)], 'b-', 1), ...
    allSegs, 'UniformOutput', 0);
plt(Shlf, 'y-', 2);

ttl = sprintf('2-Step Neural Net Prediction\nHypocotyl %d', c);
title(ttl);

%%
set(0, 'CurrentFigure', f(2));
cla;clf;
imagesc(img);
colormap gray;
axis image;
hold on;
plt(znrms(:,1:2), 'r.', 5);
cellfun(@(x) plt(x, '-', 1), simg, 'UniformOutput', 0);
ttl = sprintf('All Segments \nHypocotyl %d [in %s set]', idx, cSet);
title(ttl);

%%
set(0, 'CurrentFigure', f(3));
cla;clf;
imagesc(img);
colormap gray;
axis image;
hold on;
plt(znrms(:,1:2), 'r.', 5);
cellfun(@(x) plt(x(1,:), 'go', 1), simg, 'UniformOutput', 0);
cellfun(@(x) plt(x(end,:), 'b+', 1), simg, 'UniformOutput', 0);
cellfun(@(x) plt(x, '-', 1), Sext, 'UniformOutput', 0);
ttl = sprintf('Segment end points \nHypocotyl %d [in %s set]', idx, cSet);
title(ttl);


end



