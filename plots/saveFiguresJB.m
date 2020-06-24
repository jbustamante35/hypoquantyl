function saveFiguresJB(figs, fnms, sav_fig, img_type, sav_dir)
%% saveFiguresJB: save figures as figure names in .fig and .tiffn format
% It's about time I made this function instead of copy-pasting the same simple
% for loop every day.
%
% Usage:
%   saveFiguresJB(figs, fnms, sav_fig, img_type)
%
% Input:
%   figs: numeric array of figure handles
%   fnms: cell array of figure names (should equal number of figs)
%   sav_fig: save .fig format (default to true)
%   img_type: image format to save figures (default to 'tiffn')
%   sav_dir: directory to save figures and images
%

%% Save them
% Default to tiffn format (uncompressed tiff)
if nargin <= 3
    switch nargin
        case 2
            sav_fig  = 1;
            img_type = 'tiffn';
            sav_dir  = pwd;
        case 3
            img_type = 'tiffn';
            sav_dir  = pwd;
        case 4
            sav_dir = pwd;
    end
end

% Save figures
currDir = pwd;
cd(sav_dir);
for fig = 1 : numel(figs)
    if sav_fig
        savefig(figs(fig), fnms{fig});
    end
    
    saveas(figs(fig), fnms{fig}, img_type);
end

cd(currDir);
end

