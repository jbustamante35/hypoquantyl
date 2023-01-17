function [T , W , FA , TPT] = trackingProcessor_multi(TOUT, GMIDS, GENS, varargin)
%% trackingProcessor_multi
%
% Usage:
%   [T , W , FA , TPT] = trackingProcessor_multi(TOUT, GMIDS, GENS, varargin)
%
% Input:
%   TOUT:
%   GMIDS:
%   GENS:
%   varargin: miscellaneous inputs
%       Main Options
%       ifrm: (default [])
%       ffrm: (default [])
%       skp: (default 1)
%       smth: (default 1)
%       ftrp: (default 500)
%       ltrp: (default 1000)
%       ipcts: (default [])
%
%       Save Options
%       gstr: (default 'xxx_')
%       kdir: (default 'tracking_results')
%       sav: (default 0)
%
% Output:
%   T:
%   W:
%   FA:
%   TPT:
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

if isempty(ipcts); ipcts = TOUT{1}{1}(1,1).info.TPercents; end

%%
W   = cellfun(@(y) cellfun(@(x) fiberBundle1d(x), y, 'UniformOutput', 0), ...
    GMIDS, 'UniformOutput', 0);
FA  = cellfun(@(z) cellfun(@(y) arrayfun(@(x) x.fa, y, 'UniformOutput', 0), ...
    z, 'UniformOutput', 0), TOUT, 'UniformOutput', 0);
TPT = cellfun(@(z) cellfun(@(y) arrayfun(@(x) x.tpt, y, 'UniformOutput', 0), ...
    z, 'UniformOutput', 0), TOUT, 'UniformOutput', 0);

%% Process tracking
ngens = size(TOUT,1);
T     = cell(size(TOUT));
for gidx = 1 : ngens
    g   = GENS(gidx);
    enm = g.ExperimentName;
    gnm = g.GenotypeName;
    gin = g.getProperty('ImageStore').Files;
    w   = reshape(cat(1, W{gidx}{:}), size(W{gidx}));
    fa  = FA{gidx};
    tpt = TPT{gidx};

    %
    T{gidx} = trackingProcessor(fa, tpt, w, ipcts, 'smth', smth, 'ftrp', ...
        ftrp, 'ltrp', ltrp, 'skp', skp, 'sav', sav, 'ExperimentName', enm, ...
        'GenotypeName', gnm, 'GenotypeIndex', gidx, 'FIN', gin);

    %
    if sav
        if ~isfolder(kdir); mkdir(kdir); end
        tnm  = sprintf('%s/%s_trackingresults_%s_%s%02dgenotypes_processed', ...
            kdir, kdate, enm, gstr, ngens);
        save(tnm, '-v7.3', 'T');
    end
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Main Options
p.addOptional('ifrm', []);
p.addOptional('ffrm', []);
p.addOptional('skp', 1);
p.addOptional('smth', 1);
p.addOptional('ftrp', 500);
p.addOptional('ltrp', 1000);
p.addOptional('ipcts', []);

% Save Options
p.addOptional('gstr', 'gset_');
p.addOptional('kdir', 'tracking_results');
p.addOptional('kdate', pwd);
p.addOptional('sav', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
