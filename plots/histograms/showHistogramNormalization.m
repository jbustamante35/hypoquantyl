function showHistogramNormalization(cimgs, chist, hidx, fidx)
%% showHistogramNormalization
%
%
% Usage:
%   showHistogramNormalization(cimgs, chist, hidx, fidx)
%
% Input:
%   cimgs: [n x n] cell array of n images
%   chist: [n x n] cell array of n histograms generated from images
%   hidx: index into cell array to use as reference [default 1]
%   fidx: index to figure handle [default 1]
%

if nargin < 3; hidx = 1; end
if nargin < 4; fidx = 1; end

fplt  = @(x,clr) bar(x, 'EdgeColor', 'none', 'FaceColor', clr, 'BarWidth', 3);
nimgs = size(cimgs,1);

%
rows  = 3;
cols  = 2;
figclr(fidx);
for i = 1 : nimgs
    %
    subplot(rows, cols, 1);
    myimagesc(cimgs{hidx,hidx});
    title(sprintf('%d | %d', hidx, hidx));

    subplot(rows, cols, 3);
    myimagesc(cimgs{i,i});
    title(sprintf('%d | %d', i, hidx));

    subplot(rows, cols, 5);
    myimagesc(cimgs{i,hidx});
    title(sprintf('%d | %d', i, hidx));

    %
    subplot(rows, cols, 2);
    fplt(chist{hidx,hidx}, 'k');
    title(sprintf('%d | %d', hidx, hidx));

    subplot(rows, cols, 4);
    fplt(chist{i,i}, 'r');
    title(sprintf('%d | %d', i, i));

    subplot(rows, cols, 6);
    fplt(chist{i,hidx}, 'b');
    title(sprintf('%d | %d', i, hidx));

    drawnow;
end
end