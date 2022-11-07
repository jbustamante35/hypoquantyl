function out = trackingMidlineWhole_remote(gimgs, smids, varargin)
%% segmentLowerHypocotyl: process and segment lower regions of hypocotyl
% For use with CONDOR
%
% Usage:
%   out = segmentLowerHypocotyl(msk, varargin)
%
% Input:
%   gmid:
%   varargin: various options
%
% Output:
%   out: results
%       info: metadata about inputs
%       fa: output containing [tracked_percent , tracked_stretch]
%       tpt: tracked coordinates
%

%%
try
    %% Parse inputs
    args = parseInputs(varargin);
    for fn = fieldnames(args)'
        feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
    end

    % Track each frame's midline separately
    if isempty(ifrm); ifrm = 1; ffrm = numel(gimgs) - 1; end
    [fa , tpt] = trackMidlineWhole(gimgs, smids, ipcts, ifrm, ffrm, ...
        skp, fidx, sav);

    %% If good
    isgood = true;
    err    = [];
catch err
    %% If error
    [fa , tpt] = deal([]);
    isgood     = false;
    err.getReport;
end

%% Output
info = struct('GenotypeName', GenotypeName, 'GenotypeIndex', GenotypeIndex, ...
    'SeedlingIndex', SeedlingIndex, 'Frames', Frames, 'TPercents', ipcts);
out  = struct('info', info, 'fa', fa, 'tpt', tpt, ...
    'err', err, 'isgood', isgood);

if sav
    if ~isfolder('output'); mkdir('output'); end
    outnm = sprintf('output/%s_results_%s_genotype%02d_seedling%d_%02dframes_trackingwhole', ...
        tdate, GenotypeName, GenotypeIndex, SeedlingIndex, Frames);
    save(outnm, '-v7.3', 'out');
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Misc Options
p.addOptional('ipcts', 0 : 0.05 : 1);
p.addOptional('ifrm', []);
p.addOptional('ffrm', []);
p.addOptional('skp', 1);

% Information Options
p.addOptional('GenotypeName', 'genotype');
p.addOptional('GenotypeIndex', 0);
p.addOptional('SeedlingIndex', 0);
p.addOptional('Frames', 0);

% Visualization Options
p.addOptional('dbug', 0);
p.addOptional('fidx', 0);
p.addOptional('sav', 1);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
