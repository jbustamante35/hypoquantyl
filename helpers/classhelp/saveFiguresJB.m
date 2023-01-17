function saveFiguresJB(figs, fnms, sav_dir, sav_fig, img_type, msg)
%% saveFiguresJB: save figures as figure names in .fig and .tiffn format
% It's about time I made this function instead of copy-pasting the same simple
% for loop every day.
%
% Usage:
%   saveFiguresJB(figs, fnms, sav_dir, sav_fig, img_type)
%
% Input:
%   figs: numeric array of figure handles
%   fnms: cell array of figure names (should equal number of figs)
%   sav_dir: directory to save figures and images (default pwd)
%   sav_fig: save .fig format (default to false)
%   img_type: image format to save figures [png|tiffn|etc] (default to 'png')
%   msg: display message when saving (default true)

if nargin < 2; fnms     = [];    end
if nargin < 3; sav_dir  = pwd;   end
if nargin < 4; sav_fig  = 0;     end
if nargin < 5; img_type = 'png'; end
if nargin < 6; msg      = 1;     end

% Message separators
[~ , sprA , sprB] = jprintf(' ', 0, 0, 80);

% Make blank figure names
if isempty(fnms)
    fnms = arrayfun(@(x) sprintf('%s_figure%d', tdate, x), ...
        figs, 'UniformOutput', 0);
end

% Create directory if it doesn't exist
if ~isfolder(sav_dir); mkdir(sav_dir); end

%% Save figures
fnms = cellfun(@(fnm) sprintf('%s%s%s', sav_dir, filesep, fnm), ...
    fnms, 'UniformOutput', 0);

if msg; t = tic; fprintf('\n%s\nSaving %d figures...', sprA, numel(fnms)); end

if sav_fig
    arrayfun(@(fig) savefig(figs(fig), fnms{fig}), ...
        1 : numel(figs), 'UniformOutput', 0);
    arrayfun(@(fig) saveas(figs(fig), fnms{fig}, img_type), ...
        1 : numel(figs), 'UniformOutput', 0);
else
    arrayfun(@(fig) saveas(figs(fig), fnms{fig}, img_type), ...
        1 : numel(figs), 'UniformOutput', 0);
end

if msg; fprintf('DONE! [%.03f sec]\n%s\n', toc(t), sprA); end
end

