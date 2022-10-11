function [RawXY, RastXY] = plotContours(ctout, fidxs)
%% plotContours: plots contour data from randomContours.m output
%
% Usage:
%   [RawXY, RastXY] = plotContours(ctout, fidxs)
%
% Input:
%   ctout:
%   fidxs:
%
% Output:
%   RawXY:
%   RastXY:
%

if nargin < 2; fidxs = 1 : 2; end
figclr(fidxs(1));
for i = 1 : length(ctout)
    subplot(211); hold on;
    plot(1:length(ctout(i).Interps), ctout(i).Interps(:,2));

    subplot(212); hold on;
    plot(1:length(ctout(i).Interps), ctout(i).Interps(:,1));
end

subplot(211);
title('Interpolated Contours (x-coordinates)');
xlabel('Coordinate Index');
ylabel('Coordinate');

subplot(212);
title('Interpolated Contours (y-coordinates)');
xlabel('Coordinate Index');
ylabel('Coordinate');

%% ---------------------------------------------------------------------------------------------- %%
figclr(fidxs(2));
ctrsX = arrayfun(@(x) x.Interps(:,2), ctout, 'UniformOutput', 0);
ctrsY = arrayfun(@(x) x.Interps(:,1), ctout, 'UniformOutput', 0);

rX = rasterizeImages(ctrsX);
rY = rasterizeImages(ctrsY);

subplot(211); imagesc(rX), colormap cool;
title('Rasterized Interpolated Contours (x-coordinates)');
xlabel('Coordinate Index');
ylabel('Contour Index');

subplot(212); imagesc(rY), colormap cool;
title('Rasterized Interpolated Contours (y-coordinates)');
xlabel('Coordinate Index');
ylabel('Contour Index');

%% ---------------------------------------------------------------------------------------------- %%
RastXY = struct('rastX', rX, 'rastY', rY);
RawXY  = struct('rawX', {}, 'rawY', {});
for i = 1 : numel(ctrsX)
    RawXY(i).rawX = ctrsX{i};
    RawXY(i).rawY = ctrsY{i};
end
end