function fig = plotGallery(C, X, Y, sv, nf)
%% plotGallery:
%
%
% Usage:
%   fig = plotGallery()
%
% Input:
%   C: object array of CircuitJB
%   X: pca output for x-coordinates
%   Y: pca output for y-coordinates
%   sv: boolean to save figure
%   nf: boolean to create new figure or overlay on existing
%
% Output:
%   fig: resulting figure handle
%

%%
if nf
    fig = figure;
    set(gcf,'Color', 'w');
else
    cla;clf;
    set(gcf,'Color','w');
end

%%
im = arrayfun(@(x) x.getImage, C, 'UniformOutput', 0);
im = cellfun(@(x) x.gray, im, 'UniformOutput', 0);
im = cat(3, im{:});

%%
R   = [1 4 8 9 11 14 16 17 20 22 23 25 27 29 31 34 36 37 40];
L   = [2 3 7 10 12 13 15 18 19 21 24 26 28 30 32 33 35 38 39];
CR  = C(R);
CL  = C(L);
imR = im(:,:,R);
imL = im(:,:,L);

%%
rt = 1;
t = eval('pcaXopt(rt).customPCA.PCAscores');

%%
for i = 1 : numel(C)
    subplot(7, 6, i);
    imagesc(im(:,:,i)), colormap gray, axis image;
    %     title(sprintf('%.02f|%.02f', t(i,1), t(i,2)), 'FontSize', 8);
    title(i);
end

%%
for i = 1 : numel(CR)
    subplot(5, 4, i);
    imagesc(imR(:,:,i)), colormap gray, axis image;
    title(i);
end

%%
for i = 1 : numel(CL)
    subplot(5, 4, i);
    imagesc(imL(:,:,i)), colormap gray, axis image;
    title(i);
end

%% 
if sv
    nm = sprintf('%s_PCAoptimal_RT%d_PCorientation_gallery', datestr(now,'yymmdd'), rt);
    savefig(fig, nm);
    saveas(fig, nm, 'tiffn');
end