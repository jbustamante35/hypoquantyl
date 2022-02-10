function fnm = showCropBoxes(h, nfrms, fidx, sav)
%% showCropBoxes
%
%
% Usage:
%   fnm = showCropBoxes(h, nfrms, fidx, sav)
%
% Input:
%   h:
%   nfrms:
%   fidx:
%   sav:
%
% Output:
%   fnm:
%

%%
if nargin < 2; nfrms = h.Lifetime; end
if nargin < 3; fidx  = 1;          end
if nargin < 4; sav   = 0;          end

%%
s    = h.Parent;
g    = s.Parent;
ubox = h.getCropBox(':','upper');
lbox = h.getCropBox(':','lower');

%
fnm  = [];
if fidx
    figclr(fidx);
    for frm = 1 : nfrms
        %
        subplot(131);
        myimagesc(s.getImage(frm));
        hold on;
        rectangle('Position', ubox(frm,:), 'EdgeColor', 'r');
        rectangle('Position', lbox(frm,:), 'EdgeColor', 'c');
        hold off;
        ttl = sprintf('Crop Box Splits\nFrame %d of %d', frm, nfrms);
        title(ttl, 'FontSize', 10);

        %
        subplot(232);
        myimagesc(h.getImage(frm, 'gray', 'upper'));
        ttl = sprintf('Scaled Image\n[upper | lower]');
        title(ttl, 'FontSize', 10);

        %
        subplot(235);
        myimagesc(h.getImage(frm, 'gray', 'lower'));

        %
        subplot(233);
        myimagesc(h.getImage(frm, 'bw', 'upper'));
        ttl = sprintf('Scaled Mask\n[upper | lower]');
        title(ttl, 'FontSize', 10);

        %
        subplot(236);
        myimagesc(h.getImage(frm, 'bw', 'lower'));

        drawnow;

        %
        if sav
            gnm   = s.GenotypeName;
            hidx  = s.getSeedlingIndex;
            nsdls = g.NumberOfSeedlings;
            cdir  = sprintf('cropboxes/%s/seedling%02d', gnm, hidx);
            fnm   = sprintf('%s_cropboxes_%s_seedling%02dof%02d_frame%02dof%02d', ...
                tdate, gnm, hidx, nsdls, frm, nfrms);
            saveFiguresJB(fidx, {fnm}, cdir);
        end
    end
end
end