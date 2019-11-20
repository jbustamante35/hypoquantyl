function plotTrainingGallery(Ein, cin, fIdx)
%% plotTrainingGallery:
%
%
% Usage:
%   plotTrainingGallery(Ein, cin, fIdx)
%
% Input:
%   idxs:
%   ex: Experiment object to draw indices
%   f: figure index to plot to
%
% Output: n/a
%

%% Get 'em
set(0, 'CurrentFigure', fIdx);
cla;clf;

tG = Ein.getGenotype(cin(:,1));
tS = arrayfun(@(x) tG(x).getSeedling(cin(x,2)), ...
    1:numel(tG), 'UniformOutput', 0);
tH = cellfun(@(s) s.MyHypocotyl, tS, 'UniformOutput', 0);
I  = arrayfun(@(x) tH{x}.getImage(cin(x,3)),  ...
    1:numel(tH), 'UniformOutput', 0);

%% Show 'em
[n , o] = deal(1 : numel(tG));
p       = deal(horzcat(n,o));
tot     = numel(I);
rows    = ceil(tot / 10); % Rows of 10
cols    = ceil(tot / rows);
for slot = 1 : tot
    subplot(rows, cols, slot);
    myimagesc(I{slot});
    
    ttl = sprintf('%s\nSeedling %d Frame %d', ...
        fixtitle(tG(p(slot)).GenotypeName), cin(p(slot), 2), cin(p(slot), 3));
    title(ttl, 'FontSize', 6);
    
end

drawnow;

end
