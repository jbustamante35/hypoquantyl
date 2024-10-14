function regr_overlay_movies(T, STBL, gimgs, gmaps, uenms, enms, msample, varargin)
%% regr_overlay_movies: create REGR Overlay movies on representative seedling
%
% Usage:
%   regr_overlay_movies(T, STBL, uimgs, umaps, uenms, enms, varargin)
%
% Input:
%   T: tracking results
%   STBL: tracking data table
%   gimgs: tracked images
%   gmaps: contour and midline information
%   uenms: cell array of Experiment names to search through STBL
%   enms: cell array of Experiment names to search through gmaps
%   varargin: various options [see below]
%       p.addOptional('einit', 1);
%       p.addOptional('sav', 0);
%       p.addOptional('rdate', tdate);
%       p.addOptional('fidx', 1);
%       p.addOptional('dscl', 0.12);
%       p.addOptional('ctrn', 0.8);
%       p.addOptional('lwid', 5);
%       p.addOptional('rlims', [0 , 8]);
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%%
ulims = [0 , interpolateVector(rlims, 255)]';
nexs  = numel(uenms);

te = tic;
fprintf('\n%s\n', sprA);
for ei = einit : nexs
    enm  = uenms{ei};
    eidx = strcmp(uenms, enm);
    EI   = strcmp(enms, enm);
    stbl = STBL(EI,:);
    nsdls = size(stbl,1);
    for si = 1 : nsdls
        gidx = stbl(si,:).gidx;
        sidx = stbl(si,:).sidx;

        uinfo = gmaps{gidx}(1,sidx).info;
        gnm   = uinfo.GenotypeName;

        switch rtyp
            case 'average'
                uregr = T{eidx}.Stats.cuREGR;
            case 'single'
                uregr = T{eidx}.Output.cREGR{si};
        end

        ulen  = T{eidx}.Stats.LENS{si};
        nfrms = size(uregr,2);
        frms  = round(interpolateVector(1 : numel(gimgs{gidx}), nfrms));
        uimg  = gimgs{gidx}(frms);
        umid  = arrayfun(@(x) x.m, ...
            gmaps{gidx}(frms, sidx), 'UniformOutput', 0);

        % Downscale regr and lengths
        uregr = interpolateGrid(uregr, nfrms, ltrp * dscl, 1);
        ulen  = logical(interpolateGrid(single(ulen), nfrms, ltrp * dscl, 1));

        ts = tic;
        fprintf(['| %s | Genotype %02d of %02d | ' ...
            'Seedling %02d of %02d | Frames %02d | '], ...
            gnm, ei, nexs, si, nsdls, nfrms);

        uinfo.ColorMap   = 'jet';
        uinfo.ColorVec   = ulims;
        uinfo.ColorTrans = ctrn;
        uinfo.LineWidth  = lwid;
        uinfo.Date       = rdate;

        figclr(fidx+1,1);
        subplot(211); imagesc(uregr); colorbar; clim(rlims);
        subplot(212); imagesc(ulen); colorbar; clim(rlims); drawnow;
        showREGR(uimg, umid, ulen, uregr, uinfo, msample, fidx, sav);

        fprintf('DONE! [%.02f min] |\n', mytoc(ts, 'min'));
    end

    fprintf('%s\nExperiment %02d of %02d | %d Seedlings\n%s\n', ...
        sprB, ei, nexs, nsdls, sprA);
end

fprintf('%s\nDONE! [%.02f hrs]\n%s\n', sprA, mytoc(te, 'hrs'), sprA);

end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Misc Options
p.addOptional('einit', 1);
p.addOptional('sav', 0);
p.addOptional('rdate', tdate);
p.addOptional('fidx', 1);
p.addOptional('dscl', 0.12);
p.addOptional('ltrp', 1000);
p.addOptional('ctrn', 0.8);
p.addOptional('lwid', 5);
p.addOptional('rtyp', 'average');
p.addOptional('rlims', [0 , 8]);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
