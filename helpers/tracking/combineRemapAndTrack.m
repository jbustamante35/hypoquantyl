function cmid = combineRemapAndTrack(T, STBL, gmaps, uenms, enms, varargin)
%% combineRemapAndTrack: cut midline at threshold and then interpolate
%
% Usage:
%   cmid = combineRemapAndTrack(T, STBL, umaps, uenms, enms, varargin)
%
% Input:
%   T: tracking results
%   STBL: tracking data table
%   gmaps: contour and midline information
%   uenms: cell array of Experiment names to search through STBL
%   enms: cell array of Experiment names to search through gmaps
%   varargin: various options [see below]
%
% Output:
%   cmid:

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

% Cutoff midline at threshold and interpolate
nexs = numel(T);
cmid = cell(nexs,1);
for ei = einit : nexs
    enm   = uenms{ei};
    eidx  = strcmp(uenms, enm);
    EI    = strcmp(enms, enm);
    stbl  = STBL(EI,:);
    nsdls = size(stbl,1);
    smid  = cell(nsdls,1);
    for si = 1 : nsdls
        gidx  = stbl(si,:).gidx;
        sidx  = stbl(si,:).sidx;
        ulen  = T{eidx}.Stats.LENS{si};
        nfrms = size(gmaps{gidx},1);
        ifrms = size(ulen,2);
        frms  = round(interpolateVector(1 : nfrms, ifrms));

        if isstruct(gmaps{gidx})
            umid  = arrayfun(@(x) x.m, ...
                gmaps{gidx}(frms, sidx), 'UniformOutput', 0);
        else
            umid  = gmaps{gidx}(frms,sidx);
        end

        if toFlip
            umid  = cellfun(@(x) flipud(x), ...
                umid, 'UniformOutput', 0);
        end

        if toCut
            % smid{si} = cutMidlines(umid, ulen);
            smid{si} = cutMidlines(umid, lthr, ltrp, mth);
        else
            smid{si} = umid;
        end
    end

    cmid{ei} = smid;
end
end

function cmids = cutMidlines(gmids, glens, ltrp, mth)
%% sub function to cut off midline at threshold length
%
% Usage:
%   cmids = cutMidlines(gmids, glens, ltrp, mth)
%
% Input:
%   gmids: midlines
%   glens: logical arrays (mth 1) or threshold length (mth 2)
%   ltrp: intepolation size
%   mth: arclength measurement method
%
% Output:
%   cmids:
%

%%
nfrms = numel(gmids);
cmids = cell(nfrms,1);
for frm = 1 : nfrms
    gm = gmids{frm};

    switch mth
        case 1
            % Cut off midline using logical array
            gl = flipud(glens(:,frm));
        case 2
            % Cut off midline using threshold length
            gl = glens;
    end
    gm         = interpolateOutline(gm, ltrp);
    cmids{frm} = cutMidlineAtLength(gm, gl, ltrp, mth);
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Misc Options
p.addOptional('einit', 1);
p.addOptional('lthr', 369);  % Cut arclength
p.addOptional('ltrp', 1000); % Interpolation size
p.addOptional('mth', 2);     % Measurement method
p.addOptional('toFlip', 0);  % Flip midlines upside-down
p.addOptional('toCut', 1);   % Cut midline at arclength

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
