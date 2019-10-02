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

%% Check out the results! WOW
hlfIdx = ceil(length(simg{1}) / 2);
Shlf   = cell2mat(cellfun(@(x) x(hlfIdx,:), simg, 'UniformOutput', 0)');
Send   = cellfun(@(x) [x(1,:) ; x(end,:)], simg, 'UniformOutput', 0)';

% Check set
if ismember(idx, trnIdx)
    cSet = 'training';
else
    cSet = 'validation';
end

%%
set(0, 'CurrentFigure', f(1));
cla;clf;
imagesc(img);
colormap gray;
axis image;
hold on;
plt(Shlf, 'y-', 2);
plt(znrms(:,1:2), 'r.', 5);
ttl = sprintf('Segment Half-Indices\nHypocotyl %d [in %s set]', idx, cSet);
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
cellfun(@(x) plt(x, '-', 1), Send, 'UniformOutput', 0);
ttl = sprintf('Segment end points \nHypocotyl %d [in %s set]', idx, cSet);
title(ttl);


end



