function fnms = showRemapping(gimgs, himgs, cpres, mpres, rcntrs, rmlines, sav, snm, gnm)
%% showRemapping: show results from remapping thumbnail to full res images
%
%
% Usage:
%   fnms = showRemapping(gimgs, himgs, zpres, cpres, mpres, ...
%       rcntrs, rmlines, sav, snm, gnm)
%
% Input:
%   gimgs:
%   himgs:
%   zpres:
%   cpres:
%   mpres:
%   rcntrs:
%   rmlines:
%   sav:
%   snm:
%   gnm:
%
% Output:
%   fnms: figure names
%

%%
thmb = sprintf('timelapse_thumbs_%s', snm);
fres = sprintf('timelapse_fullres_%s_%s', gnm, snm);
frms = numel(himgs);
for frm = 1 : frms
    himg   = himgs{frm};
    gimg   = gimgs{frm};
    cpre   = cpres{frm};
    mpre   = mpres{frm};
    rcntr  = rcntrs{frm};
    rmline = rmlines{frm};
    
    %% Thumbnail image
    figclr(1);
    myimagesc(himg);
    hold on;
    plt(cpre, 'g-', 2);
    plt(mpre, 'r-', 2);
    ttl = sprintf('Frame %d of %d', frm, frms);
    title(ttl, 'FontSize', 10);
    drawnow;
    
    fnms{1} = sprintf('%s_timelapsepredictions_thumbnail_frame%02dof%02d', ...
        tdate, frm, frms);
    
    %% Full resolution image
    figclr(2);
    myimagesc(gimg);
    hold on;
    plt(rcntr, 'g-', 2);
    plt(rmline, 'r-', 2);
    ttl = sprintf('Frame %d of %d', frm, frms);
    title(ttl, 'FontSize', 10);
    drawnow;
    
    fnms{2} = sprintf('%s_timelapsepredictions_fullres_frame%02dof%02d', ...
        tdate, frm, frms);
    
    %% Save each frame
    if sav
        t = tic;
        fprintf('Saving results for frame %02d of %02d...', frm, frms);
        saveFiguresJB(1, fnms(1), thmb);
        saveFiguresJB(2, fnms(2), fres);
        fprintf('DONE! [%.03f sec]\n', toc(t));
    end
end
end