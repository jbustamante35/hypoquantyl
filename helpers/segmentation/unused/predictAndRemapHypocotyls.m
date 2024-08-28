function [rcntrs , rmlines , cpres , mpres] = predictAndRemapHypocotyls(h, himgs, ht, par)
%% predictAndRemapHypocotyls: full prediction and remapping for all seedlings
%
%
% Usage:
%   [rcntrs , rmlines , cpres , mpres] = ...
%       predictAndRemapHypocotyls(h, himgs, ht)
%
% Input:
%   h: Hypocotyl object
%   himgs: thumbnail images of hypocotyls
%   ht: HypocotylTrainer object containing prediction models
%   par: use with normal loop (0) or with parallelization (1)
%
% Output:
%   rcntrs: remapped contours onto full resolution image
%   rmlines: remapped midlines onto full resolution image
%   cpres: predicted contours from each frame
%   mpres: predicted midlines from each frame
%

%% Predict contour
% [pz , pdp , pdx , pdy , Nz , Nd] = loadHTNetworks(ht);
[pz , pdp , pdx , pdy , ~ , ~ , ~ , Nz , Nd , ~] = loadHTNetworks(ht);

mth   = 'dvec';
% zlvl  = [0.5 , 1.5];
zlvl  = 0.5;
mshps = [2 , 3];
% cpres = hypocotylPredictor(himgs, par, mth, pdx, pdy, pz, ...
%     pdp, Nz, Nd, [], [], [], 0, 'zoomLvl', zlvl);

cpres = hypocotylPredictor(himgs, par, mth, pdx, pdy, pz, pdp, ...
    Nz, Nd, [], [], [], 0, 'myShps', mshps, 'zoomLvl', zlvl);

% ---------------------------------------------------------------------------- %
%% Compute midlines
frms  = numel(himgs);
mpts  = 50;
msz   = [mpts , 2];
mpres = arrayfun(@(x) zeros(msz), 1 : frms, 'UniformOutput', 0)';
if par
    parfor frm = 1 : frms
        try
            tmid = tic;
            fprintf('Extracting midline from frame %02d of %02d...', frm, frms);
            mpres{frm} = primeMidline(himgs{frm}, cpres{frm}, mpts);
            fprintf('DONE! [%.03f sec]\n', toc(tmid));
        catch
            fprintf(2, 'Error with frame %02d [%.03f sec]\n', frm, toc(tmid));
        end
    end
else
    for frm = 1 : frms
        try
            tmid = tic;
            fprintf('Extracting midline from frame %02d of %02d...', frm, frms);
            mpres{frm} = primeMidline(himgs{frm}, cpres{frm}, mpts);
            fprintf('DONE! [%.03f sec]\n', toc(tmid));
        catch
            fprintf(2, 'Error with frame %02d [%.03f sec]\n', frm, toc(tmid));
        end
    end
end

% ---------------------------------------------------------------------------- %
%% Remap to full resolution image
[rcntrs , rmlines] = deal(cell(frms, 1));
if par
    parfor frm = 1 : frms
        try
            tmap = tic;
            fprintf('Remapping contour and midline...');
            cpre = cpres{frm};
            mpre = mpres{frm};
            [rcntrs{frm} , rmlines{frm}] = thumb2full(h, frm, cpre, mpre);
            fprintf('Finished Frame %02d of %02d [%.03f sec]\n', ...
                frm, frms, toc(tmap));
        catch
            fprintf(2, 'Error with frame %02d [%.03f sec]\n', frm, toc(tmap));
        end
    end
else
    for frm = 1 : frms
        try
            tmap = tic;
            fprintf('Remapping contour and midline...');
            cpre = cpres{frm};
            mpre = mpres{frm};
            [rcntrs{frm} , rmlines{frm}] = thumb2full(h, frm, cpre, mpre);
            fprintf('Finished Frame %02d of %02d [%.03f sec]\n', ...
                frm, frms, toc(tmap));
        catch
            fprintf(2, 'Error with frame %02d [%.03f sec]\n', frm, toc(tmap));
        end
    end
end
end
